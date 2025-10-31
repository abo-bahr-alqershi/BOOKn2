using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using System.Text.RegularExpressions;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.Authentication.DTOs;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Application.Features.Authentication.Services;

namespace YemenBooking.Application.Features.Authentication.Commands.RegisterOwner
{
    /// <summary>
    /// معالج أمر تسجيل مالك عقار جديد مع إنشاء عقار مرتبط
    /// Handler to register property owner and create a linked property
    /// </summary>
    public class RegisterPropertyOwnerCommandHandler : IRequestHandler<RegisterPropertyOwnerCommand, ResultDto<RegisterPropertyOwnerResponse>>
    {
        private readonly IPasswordHashingService _passwordHashingService;
        private readonly IUserRepository _userRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IRoleRepository _roleRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly IAuthenticationService _authService;
        private readonly ILogger<RegisterPropertyOwnerCommandHandler> _logger;
        private readonly IFinancialAccountingService _financialAccountingService;

        public RegisterPropertyOwnerCommandHandler(
            IPasswordHashingService passwordHashingService,
            IUserRepository userRepository,
            IPropertyRepository propertyRepository,
            IRoleRepository roleRepository,
            IUnitOfWork unitOfWork,
            IAuthenticationService authService,
            ILogger<RegisterPropertyOwnerCommandHandler> logger,
            IFinancialAccountingService financialAccountingService)
        {
            _passwordHashingService = passwordHashingService;
            _userRepository = userRepository;
            _propertyRepository = propertyRepository;
            _roleRepository = roleRepository;
            _unitOfWork = unitOfWork;
            _authService = authService;
            _logger = logger;
            _financialAccountingService = financialAccountingService;
        }

        public async Task<ResultDto<RegisterPropertyOwnerResponse>> Handle(RegisterPropertyOwnerCommand request, CancellationToken cancellationToken)
        {
            try
            {
                // Basic validation
                if (string.IsNullOrWhiteSpace(request.Name))
                    return ResultDto<RegisterPropertyOwnerResponse>.Failed("اسم المستخدم مطلوب", "NAME_REQUIRED");
                if (string.IsNullOrWhiteSpace(request.Email))
                    return ResultDto<RegisterPropertyOwnerResponse>.Failed("البريد الإلكتروني مطلوب", "EMAIL_REQUIRED");
                if (string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 8)
                    return ResultDto<RegisterPropertyOwnerResponse>.Failed("كلمة المرور يجب أن تكون 8 أحرف على الأقل", "PASSWORD_WEAK");
                var emailRegex = new Regex(@"^[^\s@]+@[^\s@]+\.[^\s@]+$");
                if (!emailRegex.IsMatch(request.Email))
                    return ResultDto<RegisterPropertyOwnerResponse>.Failed("تنسيق البريد الإلكتروني غير صحيح", "INVALID_EMAIL");
                if (request.PropertyTypeId == Guid.Empty)
                    return ResultDto<RegisterPropertyOwnerResponse>.Failed("نوع الكيان مطلوب", "PROPERTY_TYPE_REQUIRED");
                if (string.IsNullOrWhiteSpace(request.PropertyName))
                    return ResultDto<RegisterPropertyOwnerResponse>.Failed("اسم الكيان مطلوب", "PROPERTY_NAME_REQUIRED");
                if (string.IsNullOrWhiteSpace(request.Address))
                    return ResultDto<RegisterPropertyOwnerResponse>.Failed("عنوان الكيان مطلوب", "PROPERTY_ADDRESS_REQUIRED");
                if (string.IsNullOrWhiteSpace(request.City))
                    return ResultDto<RegisterPropertyOwnerResponse>.Failed("اسم المدينة مطلوب", "CITY_REQUIRED");

                // Ensure user/email not exists
                var allUsers = await _userRepository.GetAllAsync(cancellationToken);
                var existingUser = allUsers?.FirstOrDefault(u => u.Email.Equals(request.Email, StringComparison.OrdinalIgnoreCase));
                if (existingUser != null)
                    return ResultDto<RegisterPropertyOwnerResponse>.Failed("البريد الإلكتروني مستخدم مسبقاً", "EMAIL_ALREADY_EXISTS");

                await _unitOfWork.ExecuteInTransactionAsync(async () =>
                {
                    // Create user
                    var hashed = await _passwordHashingService.HashPasswordAsync(request.Password, cancellationToken);
                    var user = new User
                    {
                        Id = Guid.NewGuid(),
                        Name = request.Name.Trim(),
                        Email = request.Email.Trim(),
                        Phone = request.Phone,
                        Password = hashed,
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsEmailVerified = false,
                        EmailConfirmed = false,
                        IsActive = true, // Property owners are active by default
                        ProfileImage = null,
                        // Optional location fields - will be filled from property info if needed
                        TimeZoneId = null,
                        Country = null,
                        City = request.City.Trim(), // Use property city as user city
                        LoyaltyTier = null,
                        TotalSpent = 0,
                        SettingsJson = "{}",
                        FavoritesJson = "[]"
                    };
                    await _userRepository.CreateUserAsync(user, cancellationToken);

                    // Assign Owner role
                    var roles = await _roleRepository.GetAllRolesAsync(cancellationToken);
                    var ownerRole = roles.FirstOrDefault(r => r.Name.Equals("Owner", StringComparison.OrdinalIgnoreCase));
                    if (ownerRole != null)
                        await _roleRepository.AssignRoleToUserAsync(user.Id, ownerRole.Id, cancellationToken);

                    // Create property
                    var property = new Property
                    {
                        Id = Guid.NewGuid(),
                        OwnerId = user.Id,
                        TypeId = request.PropertyTypeId,
                        Name = request.PropertyName.Trim(),
                        Address = request.Address.Trim(),
                        City = request.City.Trim(),
                        Latitude = (decimal)(request.Latitude ?? 0),
                        Longitude = (decimal)(request.Longitude ?? 0),
                        StarRating = request.StarRating,
                        Description = request.Description ?? string.Empty,
                        Currency = string.IsNullOrWhiteSpace(request.Currency) ? "YER" : request.Currency!.ToUpperInvariant(),
                        CreatedAt = DateTime.UtcNow,
                        CreatedBy = user.Id,
                        IsApproved = false,
                    };
                    await _propertyRepository.CreatePropertyAsync(property, cancellationToken);

                    // إنشاء الحسابات المحاسبية الفرعية للمالك
                    // الإجراء المحاسبي: إنشاء حسابات فرعية
                    // إنشاء حساب فرعي: ذمم دائنة - مالك #{OwnerId}
                    // إنشاء حساب: عمولات مستحقة - مالك #{OwnerId}
                    // لا يوجد قيد محاسبي
                    var ownerAccountsCreated = await _financialAccountingService.CreateOwnerFinancialAccountsAsync(
                        user.Id,
                        user.Name,
                        cancellationToken);
                    if (!ownerAccountsCreated)
                        throw new InvalidOperationException("FAILED_TO_CREATE_OWNER_FINANCIAL_ACCOUNTS");
                }, cancellationToken);

                // Retrieve created user and property to populate response
                var createdUser = (await _userRepository.GetAllAsync(cancellationToken))!.First(u => u.Email == request.Email);
                var properties = await _propertyRepository.GetPropertiesByOwnerAsync(createdUser.Id, cancellationToken);
                var createdProperty = properties.First();

                // Optionally login the newly created owner to return tokens for immediate CP usage
                YemenBooking.Core.DTOs.Common.AuthResultDto? tokens = null;
                try
                {
                    tokens = await _authService.LoginAsync(request.Email.Trim(), request.Password, cancellationToken);
                }
                catch { /* non-blocking */ }

                var resp = new RegisterPropertyOwnerResponse
                {
                    UserId = createdUser.Id,
                    PropertyId = createdProperty.Id,
                    UserName = createdUser.Name,
                    Email = createdUser.Email,
                    PropertyName = createdProperty.Name,
                    Message = "تم إنشاء حساب المالك وإنشاء العقار بنجاح",
                    AccessToken = tokens?.AccessToken ?? string.Empty,
                    RefreshToken = tokens?.RefreshToken ?? string.Empty,
                    AccessTokenExpiry = tokens?.ExpiresAt ?? DateTime.UtcNow.AddHours(1),
                    PropertyCurrency = createdProperty.Currency,
                };

                return ResultDto<RegisterPropertyOwnerResponse>.Ok(resp, "تم التسجيل كمالك وإنشاء العقار بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "فشل تسجيل مالك وإنشاء عقار");
                return ResultDto<RegisterPropertyOwnerResponse>.Failed("حدث خطأ أثناء إنشاء حساب المالك والعقار", "REGISTER_OWNER_ERROR");
            }
        }
    }
}

