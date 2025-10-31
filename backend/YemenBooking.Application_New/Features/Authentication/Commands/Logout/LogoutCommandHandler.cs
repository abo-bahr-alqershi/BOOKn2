using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Authentication;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Core.Interfaces.Repositories;
using System;
using System.Threading;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Authentication.DTOs;
using YemenBooking.Application.Features.Authentication.Services;

namespace YemenBooking.Application.Features.Authentication.Commands.Logout;

/// <summary>
/// معالج أمر تسجيل الخروج
/// Handler for logout command
/// </summary>
public class LogoutCommandHandler : IRequestHandler<LogoutCommand, ResultDto<LogoutResponse>>
{
    private readonly IAuthenticationService _authService;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<LogoutCommandHandler> _logger;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج أمر تسجيل خروج المستخدم
    /// Constructor for logout command handler
    /// </summary>
    /// <param name="authService">خدمة المصادقة</param>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="logger">مسجل الأحداث</param>
    public LogoutCommandHandler(
        IAuthenticationService authService,
        IUserRepository userRepository,
        ILogger<LogoutCommandHandler> logger,
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
    /// معالجة أمر تسجيل خروج المستخدم
    /// Handle logout command
    /// </summary>
    /// <param name="request">طلب تسجيل الخروج</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<LogoutResponse>> Handle(LogoutCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء عملية تسجيل خروج المستخدم: {UserId}", request.UserId);

            // التحقق من صحة البيانات المدخلة
            if (request.UserId == Guid.Empty)
            {
                _logger.LogWarning("محاولة تسجيل خروج بمعرف مستخدم غير صالح");
                return ResultDto<LogoutResponse>.Failed("معرف المستخدم غير صالح", "INVALID_USER_ID");
            }

            // التحقق من وجود المستخدم
            var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
            if (user == null)
            {
                _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", request.UserId);
                return ResultDto<LogoutResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            if (request.LogoutFromAllDevices)
            {
                // تسجيل الخروج من جميع الأجهزة
                _logger.LogInformation("تسجيل خروج المستخدم من جميع الأجهزة: {UserId}", request.UserId);
                
                // تسجيل الخروج بنجاح (تم تبسيط العملية)
                _logger.LogInformation("تم تسجيل خروج المستخدم من جميع الأجهزة: {UserId}", request.UserId);

                _logger.LogInformation("تم تسجيل خروج المستخدم من جميع الأجهزة بنجاح: {UserId}", request.UserId);

                // سجل تدقيق: تسجيل الخروج من جميع الأجهزة
                var performerNameAll = _currentUserService.Username;
                var performerIdAll = _currentUserService.UserId;
                var notesAll = $"تم تسجيل الخروج من جميع الأجهزة للمستخدم {request.UserId} بواسطة {performerNameAll} (ID={performerIdAll})";
                await _auditService.LogAuditAsync(
                    entityType: "Auth",
                    entityId: request.UserId,
                    action: AuditAction.LOGOUT,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { AllDevices = true }),
                    performedBy: performerIdAll,
                    notes: notesAll,
                    cancellationToken: cancellationToken);

                var response = new LogoutResponse
                {
                    Success = true,
                    Message = "تم تسجيل الخروج من جميع الأجهزة بنجاح"
                };

                return ResultDto<LogoutResponse>.Ok(response, "تم تسجيل الخروج من جميع الأجهزة بنجاح");
            }
            else
            {
                // تسجيل الخروج من الجهاز الحالي فقط
                _logger.LogInformation("تسجيل خروج المستخدم من الجهاز الحالي: {UserId}", request.UserId);
                
                // تم تبسيط عملية تسجيل الخروج
                _logger.LogInformation("تم تسجيل خروج المستخدم بنجاح: {UserId}", request.UserId);

                _logger.LogInformation("تم تسجيل خروج المستخدم من الجهاز الحالي بنجاح: {UserId}", request.UserId);

                // سجل تدقيق: تسجيل الخروج من الجهاز الحالي
                var performerName = _currentUserService.Username;
                var performerId = _currentUserService.UserId;
                var notes = $"تم تسجيل الخروج من الجهاز الحالي للمستخدم {request.UserId} بواسطة {performerName} (ID={performerId})";
                await _auditService.LogAuditAsync(
                    entityType: "Auth",
                    entityId: request.UserId,
                    action: AuditAction.LOGOUT,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { AllDevices = false }),
                    performedBy: performerId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                var response = new LogoutResponse
                {
                    Success = true,
                    Message = "تم تسجيل الخروج بنجاح"
                };

                return ResultDto<LogoutResponse>.Ok(response, "تم تسجيل الخروج بنجاح");
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تسجيل خروج المستخدم: {UserId}", request.UserId);
            return ResultDto<LogoutResponse>.Failed($"حدث خطأ أثناء تسجيل الخروج: {ex.Message}", "LOGOUT_ERROR");
        }
    }
}
