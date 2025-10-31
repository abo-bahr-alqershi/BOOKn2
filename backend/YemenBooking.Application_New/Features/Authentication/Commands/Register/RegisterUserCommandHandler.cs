using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Entities;
using System.Text.RegularExpressions;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Authentication.DTOs;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Application.Features.Authentication.Services;

namespace YemenBooking.Application.Features.Authentication.Commands.Register;

/// <summary>
/// معالج أمر تسجيل مستخدم جديد
/// Handler for register user command
/// </summary>
public class RegisterUserCommandHandler : IRequestHandler<RegisterUserCommand, ResultDto<RegisterUserResponse>>
{
    private readonly IAuthenticationService _authService;
    private readonly IUserRepository _userRepository;
    private readonly IEmailService _emailService;
    private readonly IPasswordHashingService _passwordHashingService;
    private readonly IEmailVerificationService _emailVerificationService;
    private readonly ILogger<RegisterUserCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IFinancialAccountingService _financialAccountingService;

    /// <summary>
    /// منشئ معالج أمر تسجيل مستخدم جديد
    /// Constructor for register user command handler
    /// </summary>
    /// <param name="authService">خدمة المصادقة</param>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="emailService">خدمة البريد الإلكتروني</param>
    /// <param name="logger">مسجل الأحداث</param>
    public RegisterUserCommandHandler(
        IAuthenticationService authService,
        IUserRepository userRepository,
        IEmailService emailService,
        IPasswordHashingService passwordHashingService,
        IEmailVerificationService emailVerificationService,
        ILogger<RegisterUserCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService,
        IUnitOfWork unitOfWork,
        IFinancialAccountingService financialAccountingService)
    {
        _authService = authService;
        _userRepository = userRepository;
        _emailService = emailService;
        _passwordHashingService = passwordHashingService;
        _emailVerificationService = emailVerificationService;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _unitOfWork = unitOfWork;
        _financialAccountingService = financialAccountingService;
    }

    /// <summary>
    /// معالجة أمر تسجيل مستخدم جديد
    /// Handle register user command
    /// </summary>
    /// <param name="request">طلب تسجيل المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<RegisterUserResponse>> Handle(RegisterUserCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء عملية تسجيل مستخدم جديد: {Email}", request.Email);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // التحقق من عدم وجود المستخدم مسبقاً
            var allUsers = await _userRepository.GetAllAsync(cancellationToken);
            var existingUser = allUsers?.FirstOrDefault(u => u.Email == request.Email);
            if (existingUser != null)
            {
                _logger.LogWarning("محاولة تسجيل مستخدم موجود مسبقاً: {Email}", request.Email);
                return ResultDto<RegisterUserResponse>.Failed("البريد الإلكتروني مستخدم مسبقاً", "EMAIL_ALREADY_EXISTS");
            }

            // التحقق من عدم وجود رقم الهاتف مسبقاً
            if (!string.IsNullOrWhiteSpace(request.Phone))
            {
                var existingPhoneUser = await _userRepository.GetByPhoneAsync(request.Phone, cancellationToken);
                if (existingPhoneUser != null)
                {
                    _logger.LogWarning("محاولة تسجيل مستخدم برقم هاتف موجود مسبقاً: {Phone}", request.Phone);
                    return ResultDto<RegisterUserResponse>.Failed("رقم الهاتف مستخدم مسبقاً", "PHONE_ALREADY_EXISTS");
                }
            }

            // إنشاء المستخدم الجديد - استخدام طريقة بديلة لأن RegisterAsync غير متوفرة
            var hashedPassword = await _passwordHashingService.HashPasswordAsync(request.Password, cancellationToken);

            var newUser = new User
            {
                Id = Guid.NewGuid(),
                Name = request.Name.Trim(),
                Email = request.Email.Trim(),
                Phone = request.Phone,
                Password = hashedPassword,
                ProfileImage = null,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsEmailVerified = false,
                EmailConfirmed = false,
                IsActive = true, // Mobile users are active by default
                // Optional location fields
                TimeZoneId = null,
                Country = null,
                City = null,
                LoyaltyTier = null,
                TotalSpent = 0,
                SettingsJson = "{}",
                FavoritesJson = "[]"
            };
            
            // Persist user and create financial account atomically
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                await _userRepository.CreateUserAsync(newUser, cancellationToken);
                var createdOk = await _financialAccountingService.CreateCustomerFinancialAccountAsync(newUser.Id, newUser.Name, cancellationToken);
                if (!createdOk)
                    throw new InvalidOperationException("FAILED_TO_CREATE_CUSTOMER_FINANCIAL_ACCOUNT");
            }, cancellationToken);

            // Issue tokens for the newly registered user so the client can be authenticated immediately
            YemenBooking.Core.DTOs.Common.AuthResultDto? authTokens = null;
            try
            {
                authTokens = await _authService.LoginAsync(request.Email.Trim(), request.Password, cancellationToken);
            }
            catch
            {
                // If token issuance fails for any reason, continue without blocking registration
            }

            var registerResult = new { 
                Success = true, 
                UserId = newUser.Id, 
                Message = "تم تسجيل المستخدم بنجاح",
                AccessToken = authTokens?.AccessToken ?? string.Empty,
                RefreshToken = authTokens?.RefreshToken ?? string.Empty,
                AccessTokenExpiry = authTokens?.ExpiresAt
            };

            if (registerResult == null)
            {
                _logger.LogError("فشل في تسجيل المستخدم: {Email}", request.Email);
                return ResultDto<RegisterUserResponse>.Failed("فشل في تسجيل المستخدم", "REGISTRATION_FAILED");
            }

            // إرسال رمز تحقق بالبريد
            try
            {
                var code = _emailVerificationService.GenerateVerificationCode();
                var sent = await _emailVerificationService.SendVerificationEmailAsync(request.Email, code);
                if (!sent)
                {
                    _logger.LogWarning("فشل إرسال بريد رمز التحقق للمستخدم: {Email}", request.Email);
                }
            }
            catch (Exception emailEx)
            {
                _logger.LogWarning(emailEx, "فشل في إرسال بريد التحقق للمستخدم: {Email}", request.Email);
                // لا نفشل العملية بسبب فشل إرسال البريد
            }

            _logger.LogInformation("تم تسجيل المستخدم بنجاح: {UserId}", registerResult.UserId);

            var response = new RegisterUserResponse
            {
                UserId = registerResult.UserId,
                AccessToken = registerResult.AccessToken,
                RefreshToken = registerResult.RefreshToken,
                Message = "تم تسجيل المستخدم بنجاح. يرجى التحقق من بريدك الإلكتروني لتفعيل الحساب",
                AccessTokenExpiry = registerResult.AccessTokenExpiry ?? DateTime.UtcNow.AddHours(1),
                UserName = newUser.Name,
                Email = newUser.Email,
                IsEmailVerified = newUser.IsEmailVerified
            };

            // تدقيق يدوي: تسجيل مستخدم جديد (بدون كلمة مرور)
            var performerName = _currentUserService.Username;
            var performerId = _currentUserService.UserId;
            var notes = $"تم تسجيل مستخدم جديد {newUser.Id} بواسطة {performerName} (ID={performerId})";
            await _auditService.LogAuditAsync(
                entityType: "User",
                entityId: newUser.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { newUser.Id, newUser.Name, newUser.Email, newUser.Phone }),
                performedBy: performerId,
                notes: notes,
                cancellationToken: cancellationToken);

            return ResultDto<RegisterUserResponse>.Ok(response, "تم تسجيل المستخدم بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تسجيل المستخدم: {Email}", request.Email);
            return ResultDto<RegisterUserResponse>.Failed($"حدث خطأ أثناء تسجيل المستخدم: {ex.Message}", "REGISTRATION_ERROR");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate the input request
    /// </summary>
    /// <param name="request">طلب التسجيل</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<RegisterUserResponse> ValidateRequest(RegisterUserCommand request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
        {
            return ResultDto<RegisterUserResponse>.Failed("اسم المستخدم مطلوب", "NAME_REQUIRED");
        }

        if (request.Name.Length < 2 || request.Name.Length > 100)
        {
            return ResultDto<RegisterUserResponse>.Failed("اسم المستخدم يجب أن يكون بين 2 و 100 حرف", "INVALID_NAME_LENGTH");
        }

        if (string.IsNullOrWhiteSpace(request.Email))
        {
            return ResultDto<RegisterUserResponse>.Failed("البريد الإلكتروني مطلوب", "EMAIL_REQUIRED");
        }

        // التحقق من صحة تنسيق البريد الإلكتروني
        var emailRegex = new Regex(@"^[^\s@]+@[^\s@]+\.[^\s@]+$");
        if (!emailRegex.IsMatch(request.Email))
        {
            return ResultDto<RegisterUserResponse>.Failed("تنسيق البريد الإلكتروني غير صحيح", "INVALID_EMAIL_FORMAT");
        }

        if (string.IsNullOrWhiteSpace(request.Password))
        {
            return ResultDto<RegisterUserResponse>.Failed("كلمة المرور مطلوبة", "PASSWORD_REQUIRED");
        }

        if (request.Password.Length < 8)
        {
            return ResultDto<RegisterUserResponse>.Failed("كلمة المرور يجب أن تكون 8 أحرف على الأقل", "PASSWORD_TOO_SHORT");
        }

        // التحقق من قوة كلمة المرور
        if (!Regex.IsMatch(request.Password, @"^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)"))
        {
            return ResultDto<RegisterUserResponse>.Failed("كلمة المرور يجب أن تحتوي على حرف كبير وحرف صغير ورقم على الأقل", "WEAK_PASSWORD");
        }

        // التحقق من رقم الهاتف إذا تم توفيره
        if (!string.IsNullOrWhiteSpace(request.Phone))
        {
            var phoneRegex = new Regex(@"^(\+967|967|0)?[1-9]\d{7,8}$");
            if (!phoneRegex.IsMatch(request.Phone))
            {
                return ResultDto<RegisterUserResponse>.Failed("تنسيق رقم الهاتف غير صحيح", "INVALID_PHONE_FORMAT");
            }
        }

        return ResultDto<RegisterUserResponse>.Ok(null, "البيانات صحيحة");
    }
}
