using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using Microsoft.Extensions.Logging;
using System.Text.RegularExpressions;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Authentication.Services;
using YemenBooking.Application_New.Core.Enums;

namespace YemenBooking.Application.Features.Authentication.Commands.Login;

/// <summary>
/// معالج أمر تسجيل دخول المستخدم للعميل
/// Handler for client login user command
/// </summary>
public class ClientLoginUserCommandHandler : IRequestHandler<ClientLoginUserCommand, ResultDto<ClientLoginUserResponse>>
{
    private readonly IAuthenticationService _authService;
    private readonly ILogger<ClientLoginUserCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    public ClientLoginUserCommandHandler(
        IAuthenticationService authService,
        ILogger<ClientLoginUserCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService)
    {
        _authService = authService;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة أمر تسجيل دخول المستخدم
    /// Handle login user command
    /// </summary>
    /// <param name="request">الطلب</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<ClientLoginUserResponse>> Handle(ClientLoginUserCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("محاولة تسجيل دخول للمستخدم: {EmailOrPhone}", request.EmailOrPhone);

            // التحقق من صحة البيانات
            if (string.IsNullOrWhiteSpace(request.EmailOrPhone))
            {
                return ResultDto<ClientLoginUserResponse>.Failed("البريد الإلكتروني أو رقم الهاتف مطلوب", "EMAIL_OR_PHONE_REQUIRED");
            }

            if (string.IsNullOrWhiteSpace(request.Password))
            {
                return ResultDto<ClientLoginUserResponse>.Failed("كلمة المرور مطلوبة", "PASSWORD_REQUIRED");
            }

            var identifier = request.EmailOrPhone.Trim();
            // تحقق من صيغة البريد إذا كان يحتوي على @
            if (identifier.Contains('@'))
            {
                // تصحيح شائع: .cpm -> .com
                var lowered = identifier.ToLowerInvariant();
                if (lowered.EndsWith(".cpm"))
                {
                    var corrected = lowered[..^4] + ".com";
                    _logger.LogInformation("تصحيح نطاق البريد من {Old} إلى {New}", identifier, corrected);
                    identifier = corrected;
                }
                // تحقق بسيط لصيغة البريد
                var emailPattern = @"^[^@\s]+@[^@\s]+\.[^@\s]+$";
                if (!Regex.IsMatch(identifier, emailPattern, RegexOptions.IgnoreCase))
                {
                    return ResultDto<ClientLoginUserResponse>.Failed("صيغة البريد الإلكتروني غير صحيحة", "INVALID_EMAIL_FORMAT");
                }
            }
            else
            {
                // اعتبره رقم هاتف: طبيع الأرقام وتحقق من الطول الأدنى
                var digits = new string(identifier.Where(char.IsDigit).ToArray());
                if (digits.Length < 7)
                {
                    return ResultDto<ClientLoginUserResponse>.Failed("رقم الهاتف غير صالح", "INVALID_PHONE");
                }
            }

            // استخدام خدمة المصادقة للتحقق من المستخدم وإصدار التوكنات
            var authResult = await _authService.LoginAsync(identifier, request.Password, cancellationToken);

            if (authResult == null)
            {
                _logger.LogWarning("فشل تسجيل الدخول: بيانات غير صحيحة {EmailOrPhone}", request.EmailOrPhone);
                return ResultDto<ClientLoginUserResponse>.Failed("البريد الإلكتروني أو كلمة المرور غير صحيحة", "INVALID_CREDENTIALS");
            }

            // تحويل النتيجة إلى التنسيق المطلوب للعميل
            var response = new ClientLoginUserResponse
            {
                UserId = authResult.UserId,
                Name = authResult.UserName,
                Email = authResult.Email,
                Phone = "", // سيتم تحديثه من قاعدة البيانات إذا لزم الأمر
                AccessToken = authResult.AccessToken,
                RefreshToken = authResult.RefreshToken,
                Roles = new List<string> { string.IsNullOrWhiteSpace(authResult.AccountRole) ? authResult.Role : authResult.AccountRole }
            };

            _logger.LogInformation("تم تسجيل دخول المستخدم بنجاح {UserId}", authResult.UserId);

            // تدقيق يدوي: تسجيل الدخول
            var performerName = _currentUserService.Username;
            var performerId = _currentUserService.UserId;
            var notes = $"تم تسجيل الدخول للمستخدم {authResult.UserId} بواسطة {performerName} (ID={performerId})";
            await _auditService.LogAuditAsync(
                entityType: "User",
                entityId: authResult.UserId,
                action: YemenBooking.Core.Entities.AuditAction.LOGIN,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { Success = true }),
                performedBy: performerId,
                notes: notes,
                cancellationToken: cancellationToken);

            return ResultDto<ClientLoginUserResponse>.Ok(response, "تم تسجيل الدخول بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "فشل تسجيل الدخول للمستخدم {EmailOrPhone}: {Reason}", request.EmailOrPhone, ex.Message);
            var message = ex.Message ?? string.Empty;
            if (message.Contains("المستخدم غير موجود") || message.Contains("بيانات الاعتماد غير صحيحة"))
            {
                return ResultDto<ClientLoginUserResponse>.Failed("البريد الإلكتروني أو كلمة المرور غير صحيحة", "INVALID_CREDENTIALS");
            }
            return ResultDto<ClientLoginUserResponse>.Failed("حدث خطأ أثناء تسجيل الدخول", "LOGIN_ERROR");
        }
    }
}