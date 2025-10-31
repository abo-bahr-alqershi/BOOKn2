using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Interfaces;
using System.Text.Json;
using System.Linq;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.Authentication.Services;

namespace YemenBooking.Application.Features.Users.Commands.CreateUser
{
    /// <summary>
    /// معالج أمر إنشاء حساب مستخدم جديد
    /// </summary>
    public class CreateUserCommandHandler : IRequestHandler<CreateUserCommand, ResultDto<Guid>>
    {
        private readonly IUserRepository _userRepository;
        private readonly IPasswordHashingService _passwordHashingService;
        private readonly IEmailService _emailService;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<CreateUserCommandHandler> _logger;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IFinancialAccountingService _financialAccountingService;
        private readonly IRoleRepository _roleRepository;

        public CreateUserCommandHandler(
            IUserRepository userRepository,
            IPasswordHashingService passwordHashingService,
            IEmailService emailService,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<CreateUserCommandHandler> logger,
            IUnitOfWork unitOfWork,
            IFinancialAccountingService financialAccountingService,
            IRoleRepository roleRepository)
        {
            _userRepository = userRepository;
            _passwordHashingService = passwordHashingService;
            _emailService = emailService;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _unitOfWork = unitOfWork;
            _financialAccountingService = financialAccountingService;
            _roleRepository = roleRepository;
        }

        public async Task<ResultDto<Guid>> Handle(CreateUserCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إنشاء مستخدم جديد: Email={Email}, Name={Name}", request.Email, request.Name);

            // التحقق من المدخلات
            if (string.IsNullOrWhiteSpace(request.Name))
                return ResultDto<Guid>.Failed("الاسم مطلوب");
            if (string.IsNullOrWhiteSpace(request.Email))
                return ResultDto<Guid>.Failed("البريد الإلكتروني مطلوب");
            if (string.IsNullOrWhiteSpace(request.Password))
                return ResultDto<Guid>.Failed("كلمة المرور مطلوبة");
            if (string.IsNullOrWhiteSpace(request.Phone))
                return ResultDto<Guid>.Failed("رقم الهاتف مطلوب");

            // التحقق من قواعد العمل
            if (await _userRepository.CheckEmailExistsAsync(request.Email, cancellationToken))
                return ResultDto<Guid>.Failed("البريد الإلكتروني مستخدم بالفعل");

            // تحقق من قوة كلمة المرور
            var (isValid, issues) = await _passwordHashingService.ValidatePasswordStrengthAsync(request.Password, cancellationToken);
            if (!isValid)
                return ResultDto<Guid>.Failed($"كلمة المرور غير قوية: {string.Join(", ", issues)}");

            // التنفيذ
            var hashedPassword = await _passwordHashingService.HashPasswordAsync(request.Password, cancellationToken);
            var user = new User
            {
                Name = request.Name.Trim(),
                Email = request.Email.Trim(),
                Password = hashedPassword,
                Phone = request.Phone.Trim(),
                ProfileImage = string.IsNullOrWhiteSpace(request.ProfileImage) ? null : request.ProfileImage.Trim(),
                CreatedAt = DateTime.UtcNow,
                IsActive = false,
                EmailConfirmed = request.EmailConfirmed,
                IsEmailVerified = request.EmailConfirmed, // If admin confirms email, set both flags
                EmailVerifiedAt = request.EmailConfirmed ? DateTime.UtcNow : (DateTime?)null,
                PhoneNumberConfirmed = request.PhoneNumberConfirmed,
                IsPhoneNumberVerified = request.PhoneNumberConfirmed, // If admin confirms phone, set both flags
                PhoneNumberVerifiedAt = request.PhoneNumberConfirmed ? DateTime.UtcNow : (DateTime?)null,
                // Optional fields - will be null by default, which is now allowed
                TimeZoneId = null,
                Country = null,
                City = null,
                LoyaltyTier = null,
                TotalSpent = 0,
                SettingsJson = "{}",
                FavoritesJson = "[]"
            };
            User created = null!;
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                created = await _userRepository.CreateUserAsync(user, cancellationToken);

                // تحديد الدور المستهدف (إن وُفر)
                string roleName = request.RoleName?.Trim() ?? string.Empty;
                bool isOwnerRole = false;
                if (!string.IsNullOrWhiteSpace(roleName))
                {
                    var allRoles = await _roleRepository.GetAllRolesAsync(cancellationToken);
                    var matchedRole = allRoles?.FirstOrDefault(r => r.Name.Equals(roleName, StringComparison.OrdinalIgnoreCase));
                    if (matchedRole != null)
                    {
                        var assigned = await _roleRepository.AssignRoleToUserAsync(created.Id, matchedRole.Id, cancellationToken);
                        if (!assigned)
                            throw new InvalidOperationException("FAILED_TO_ASSIGN_ROLE_TO_NEW_USER");

                        var norm = matchedRole.Name?.Trim().ToLowerInvariant() ?? string.Empty;
                        isOwnerRole = norm == "owner" || norm == "hotel_owner" || norm.Contains("owner");
                    }
                    else
                    {
                        _logger.LogWarning("لم يتم العثور على الدور {RoleName}، سيتم التهيئة الافتراضية كعميل", roleName);
                    }
                }

                // إنشاء الحسابات المالية بناءً على الدور
                bool accountsCreated;
                if (isOwnerRole)
                {
                    accountsCreated = await _financialAccountingService.CreateOwnerFinancialAccountsAsync(created.Id, created.Name, cancellationToken);
                    if (!accountsCreated)
                        throw new InvalidOperationException("FAILED_TO_CREATE_OWNER_FINANCIAL_ACCOUNTS");
                }
                else
                {
                    accountsCreated = await _financialAccountingService.CreateCustomerFinancialAccountAsync(created.Id, created.Name, cancellationToken);
                    if (!accountsCreated)
                        throw new InvalidOperationException("FAILED_TO_CREATE_CUSTOMER_FINANCIAL_ACCOUNT");
                }
            }, cancellationToken);

            // إرسال بريد ترحيبي بعد إنشاء الحساب
            await _emailService.SendWelcomeEmailAsync(created.Email, created.Name, cancellationToken);

            // تسجيل التدقيق اليدوي مع قيم جديدة
            var newValues = new
            {
                created.Id,
                created.Name,
                created.Email,
                created.Phone,
                created.ProfileImage,
                created.IsActive,
                created.EmailConfirmed
            };
            await _auditService.LogAuditAsync(
                entityType: "User",
                entityId: created.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(newValues),
                performedBy: _currentUserService.UserId,
                notes: $"تم إنشاء مستخدم جديد {created.Id} ({created.Email})",
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل إنشاء المستخدم بنجاح: UserId={UserId}", created.Id);
            return ResultDto<Guid>.Succeeded(created.Id, "تم إنشاء المستخدم بنجاح");
        }
    }
} 