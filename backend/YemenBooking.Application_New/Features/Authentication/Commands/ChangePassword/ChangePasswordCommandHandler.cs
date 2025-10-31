using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using System;
using System.Threading;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Features.Authentication.DTOs;
using YemenBooking.Application.Features.Authentication.Services;

namespace YemenBooking.Application.Features.Authentication.Commands.ChangePassword
{
    /// <summary>
    /// معالج أمر تغيير كلمة المرور
    /// Handler for change password command
    /// </summary>
    public class ChangePasswordCommandHandler : IRequestHandler<ChangePasswordCommand, ResultDto<ChangePasswordResponse>>
    {
        private readonly IAuthenticationService _authService;
        private readonly IUserRepository _userRepository;
    private readonly ILogger<ChangePasswordCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

        /// <summary>
        /// منشئ معالج أمر تغيير كلمة المرور
        /// Constructor for change password command handler
        /// </summary>
        /// <param name="authService">خدمة المصادقة</param>
        /// <param name="userRepository">مستودع المستخدمين</param>
        /// <param name="logger">مسجل الأحداث</param>
        public ChangePasswordCommandHandler(
        IAuthenticationService authService,
        IUserRepository userRepository,
        ILogger<ChangePasswordCommandHandler> logger,
        IAuditService auditService,
        ICurrentUserService currentUserService)
        {
            _authService = authService;
            _userRepository = userRepository;
        _logger = logger;
        _auditService = auditService;
        _currentUserService = currentUserService;
        }

        /// <summary>
        /// معالجة أمر تغيير كلمة المرور
        /// Handle change password command
        /// </summary>
        /// <param name="request">طلب تغيير كلمة المرور</param>
        /// <param name="cancellationToken">رمز الإلغاء</param>
        /// <returns>نتيجة العملية</returns>
        public async Task<ResultDto<ChangePasswordResponse>> Handle(ChangePasswordCommand request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("بدء عملية تغيير كلمة المرور للمستخدم: {UserId}", request.UserId);

                // التحقق من صحة البيانات المدخلة
                if (request.UserId == Guid.Empty)
                {
                    _logger.LogWarning("محاولة تغيير كلمة المرور بمعرف مستخدم غير صالح");
                    return ResultDto<ChangePasswordResponse>.Failed("معرف المستخدم غير صالح", "INVALID_USER_ID");
                }

                if (string.IsNullOrWhiteSpace(request.CurrentPassword))
                {
                    return ResultDto<ChangePasswordResponse>.Failed("كلمة المرور الحالية مطلوبة", "CURRENT_PASSWORD_REQUIRED");
                }

                if (string.IsNullOrWhiteSpace(request.NewPassword))
                {
                    return ResultDto<ChangePasswordResponse>.Failed("كلمة المرور الجديدة مطلوبة", "NEW_PASSWORD_REQUIRED");
                }

                // التحقق من قوة كلمة المرور الجديدة
                if (request.NewPassword.Length < 8)
                {
                    return ResultDto<ChangePasswordResponse>.Failed("كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل", "PASSWORD_TOO_SHORT");
                }

                // البحث عن المستخدم
                var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
                if (user == null)
                {
                    _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", request.UserId);
                    return ResultDto<ChangePasswordResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
                }

                // التحقق من كلمة المرور الحالية
                // ملاحظة: يمكن إضافة التحقق من كلمة المرور لاحقاً
                // Note: Password verification can be added later
                var isCurrentPasswordValid = !string.IsNullOrWhiteSpace(request.CurrentPassword);
                if (!isCurrentPasswordValid)
                {
                    _logger.LogWarning("كلمة المرور الحالية غير صحيحة للمستخدم: {UserId}", request.UserId);
                    return ResultDto<ChangePasswordResponse>.Failed("كلمة المرور الحالية غير صحيحة", "INVALID_CURRENT_PASSWORD");
                }

                // تحديث كلمة المرور
                var changeResult = await _authService.ChangePasswordAsync(request.UserId, request.CurrentPassword, request.NewPassword, cancellationToken);
                if (!changeResult)
                {
                    _logger.LogError("فشل في تحديث كلمة المرور للمستخدم: {UserId}", request.UserId);
                    return ResultDto<ChangePasswordResponse>.Failed("فشل في تحديث كلمة المرور", "PASSWORD_CHANGE_FAILED");
                }

                _logger.LogInformation("تم تغيير كلمة المرور بنجاح للمستخدم: {UserId}", request.UserId);

                // تدقيق يدوي: تغيير كلمة المرور (عدم تسجيل كلمات المرور)
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"تم تغيير كلمة المرور للمستخدم {request.UserId} بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "User",
                    entityId: request.UserId,
                    action: YemenBooking.Core.Entities.AuditAction.PASSWORD_CHANGE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { Success = true }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                var response = new ChangePasswordResponse
                {
                    Success = true,
                    Message = "تم تغيير كلمة المرور بنجاح"
                };

                return ResultDto<ChangePasswordResponse>.Ok(response, "تم تغيير كلمة المرور بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تغيير كلمة المرور للمستخدم: {UserId}", request.UserId);
                return ResultDto<ChangePasswordResponse>.Failed($"حدث خطأ أثناء تغيير كلمة المرور: {ex.Message}", "CHANGE_PASSWORD_ERROR");
            }
        }
    }
}
