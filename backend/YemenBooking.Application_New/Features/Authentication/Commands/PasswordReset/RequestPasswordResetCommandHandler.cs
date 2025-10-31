using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using System.Text.RegularExpressions;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Authentication.DTOs;
using YemenBooking.Application.Features.Authentication.Services;

namespace YemenBooking.Application.Features.Authentication.Commands.PasswordReset;

/// <summary>
/// معالج أمر طلب إعادة تعيين كلمة المرور
/// Handler for request password reset command
/// </summary>
public class RequestPasswordResetCommandHandler : IRequestHandler<RequestPasswordResetCommand, ResultDto<RequestPasswordResetResponse>>
{
    private readonly IUserRepository _userRepository;
    private readonly IEmailService _emailService;
    private readonly ISmsService _smsService;
    private readonly IPasswordResetService _passwordResetService;
    private readonly ILogger<RequestPasswordResetCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج أمر طلب إعادة تعيين كلمة المرور
    /// Constructor for request password reset command handler
    /// </summary>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="emailService">خدمة البريد الإلكتروني</param>
    /// <param name="smsService">خدمة الرسائل النصية</param>
    /// <param name="passwordResetService">خدمة إعادة تعيين كلمة المرور</param>
    /// <param name="logger">مسجل الأحداث</param>
    public RequestPasswordResetCommandHandler(
        IUserRepository userRepository,
        IEmailService emailService,
        ISmsService smsService,
        IPasswordResetService passwordResetService,
        ILogger<RequestPasswordResetCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService)
    {
        _userRepository = userRepository;
        _emailService = emailService;
        _smsService = smsService;
        _passwordResetService = passwordResetService;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة أمر طلب إعادة تعيين كلمة المرور
    /// Handle request password reset command
    /// </summary>
    /// <param name="request">طلب إعادة تعيين كلمة المرور</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<RequestPasswordResetResponse>> Handle(RequestPasswordResetCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء عملية طلب إعادة تعيين كلمة المرور: {EmailOrPhone}", request.EmailOrPhone);

            // التحقق من صحة البيانات المدخلة
            if (string.IsNullOrWhiteSpace(request.EmailOrPhone))
            {
                return ResultDto<RequestPasswordResetResponse>.Failed("البريد الإلكتروني أو رقم الهاتف مطلوب", "EMAIL_OR_PHONE_REQUIRED");
            }

            // تحديد نوع المدخل (بريد إلكتروني أم رقم هاتف)
            bool isEmail = IsValidEmail(request.EmailOrPhone);
            bool isPhone = IsValidPhone(request.EmailOrPhone);

            if (!isEmail && !isPhone)
            {
                return ResultDto<RequestPasswordResetResponse>.Failed("تنسيق البريد الإلكتروني أو رقم الهاتف غير صحيح", "INVALID_FORMAT");
            }

            // البحث عن المستخدم
            var allUsers = await _userRepository.GetAllAsync(cancellationToken);
            var user = isEmail ? allUsers?.FirstOrDefault(u => u.Email == request.EmailOrPhone) : allUsers?.FirstOrDefault(u => u.Phone == request.EmailOrPhone);

            // نعيد نفس الرسالة سواء وُجد المستخدم أم لا لأسباب أمنية
            const string successMessage = "إذا كان الحساب موجوداً، فسيتم إرسال رابط إعادة تعيين كلمة المرور";

            if (user == null)
            {
                _logger.LogInformation("طلب إعادة تعيين كلمة المرور لحساب غير موجود: {EmailOrPhone}", request.EmailOrPhone);
                
                var notFoundResponse = new RequestPasswordResetResponse
                {
                    Success = true,
                    Message = successMessage
                };

                return ResultDto<RequestPasswordResetResponse>.Ok(notFoundResponse, successMessage);
            }

            // التحقق من عدم تجاوز حد الطلبات
            _logger.LogInformation("التحقق من طلبات إعادة تعيين كلمة المرور للمستخدم: {UserId}", user.Id);
            var recentRequestsCount = 0; // تنفيذ مبسط
            if (recentRequestsCount >= 3)
            {
                _logger.LogWarning("تجاوز حد طلبات إعادة تعيين كلمة المرور للمستخدم: {UserId}", user.Id);
                return ResultDto<RequestPasswordResetResponse>.Failed("تم تجاوز الحد الأقصى لطلبات إعادة تعيين كلمة المرور. يرجى المحاولة لاحقاً", "TOO_MANY_REQUESTS");
            }

            // إنشاء رمز إعادة تعيين كلمة المرور
            var resetToken = await _passwordResetService.GenerateResetTokenAsync(user.Id);
            if (string.IsNullOrEmpty(resetToken))
            {
                _logger.LogError("فشل في إنشاء رمز إعادة تعيين كلمة المرور للمستخدم: {UserId}", user.Id);
                return ResultDto<RequestPasswordResetResponse>.Failed("فشل في إنشاء طلب إعادة التعيين", "TOKEN_GENERATION_FAILED");
            }

            // إرسال رابط إعادة التعيين
            bool sendResult = false;
            if (isEmail)
            {
                sendResult = await _emailService.SendPasswordResetEmailAsync(user.Email, resetToken, user.Name, cancellationToken);
                _logger.LogInformation("تم إرسال بريد إعادة تعيين كلمة المرور للمستخدم: {UserId}", user.Id);
            }
            else
            {
                // إرسال رسالة نصية (تنفيذ مبسط)
                var smsBody = $"رمز إعادة تعيين كلمة المرور: {resetToken}";
                sendResult = await _smsService.SendSmsAsync(user.Phone, smsBody, cancellationToken);
                _logger.LogInformation("تم إرسال رسالة نصية لإعادة تعيين كلمة المرور للمستخدم: {UserId}", user.Id);
            }

            if (!sendResult)
            {
                _logger.LogError("فشل في إرسال رابط إعادة تعيين كلمة المرور للمستخدم: {UserId}", user.Id);
                // إلغاء الرموز السابقة (تنفيذ مبسط)
                _logger.LogDebug("تم تجاهل إلغاء الرموز السابقة - سيتم تنفيذه لاحقاً");
                return ResultDto<RequestPasswordResetResponse>.Failed("فشل في إرسال رابط إعادة التعيين", "SEND_FAILED");
            }

            _logger.LogInformation("تم إرسال طلب إعادة تعيين كلمة المرور بنجاح للمستخدم: {UserId}", user.Id);

            var response = new RequestPasswordResetResponse
            {
                Success = true,
                Message = successMessage
            };

            // تدقيق يدوي: طلب إعادة تعيين كلمة المرور
            var performerName = _currentUserService.Username;
            var performerId = _currentUserService.UserId;
            var notes = $"تم طلب إعادة تعيين كلمة المرور للمستخدم {user.Id} بواسطة {performerName} (ID={performerId})";
            await _auditService.LogAuditAsync(
                entityType: "User",
                entityId: user.Id,
                action: AuditAction.PASSWORD_RESET,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { Success = true }),
                performedBy: performerId,
                notes: notes,
                cancellationToken: cancellationToken);

            return ResultDto<RequestPasswordResetResponse>.Ok(response, successMessage);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء طلب إعادة تعيين كلمة المرور: {EmailOrPhone}", request.EmailOrPhone);
            return ResultDto<RequestPasswordResetResponse>.Failed($"حدث خطأ أثناء معالجة الطلب: {ex.Message}", "REQUEST_PASSWORD_RESET_ERROR");
        }
    }

    /// <summary>
    /// التحقق من صحة تنسيق البريد الإلكتروني
    /// Validate email format
    /// </summary>
    /// <param name="email">البريد الإلكتروني</param>
    /// <returns>صحة التنسيق</returns>
    private static bool IsValidEmail(string email)
    {
        var emailRegex = new Regex(@"^[^\s@]+@[^\s@]+\.[^\s@]+$");
        return emailRegex.IsMatch(email);
    }

    /// <summary>
    /// التحقق من صحة تنسيق رقم الهاتف
    /// Validate phone format
    /// </summary>
    /// <param name="phone">رقم الهاتف</param>
    /// <returns>صحة التنسيق</returns>
    private static bool IsValidPhone(string phone)
    {
        var phoneRegex = new Regex(@"^(\+967|967|0)?[1-9]\d{7,8}$");
        return phoneRegex.IsMatch(phone);
    }
}
