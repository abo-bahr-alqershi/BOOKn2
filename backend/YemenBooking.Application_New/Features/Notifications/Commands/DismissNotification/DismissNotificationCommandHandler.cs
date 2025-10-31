using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Commands;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Commands.DismissNotification;

/// <summary>
/// معالج أمر إخفاء إشعار للموبايل
/// </summary>
public class DismissNotificationCommandHandler : IRequestHandler<DismissNotificationCommand, DismissNotificationResponse>
{
    private readonly INotificationRepository _notificationRepository;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<DismissNotificationCommandHandler> _logger;

    public DismissNotificationCommandHandler(INotificationRepository notificationRepository, IAuditService auditService, ICurrentUserService currentUserService, ILogger<DismissNotificationCommandHandler> logger)
    {
        _notificationRepository = notificationRepository;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    public async Task<DismissNotificationResponse> Handle(DismissNotificationCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("إخفاء إشعار {NotificationId} من قبل المستخدم {UserId}", request.NotificationId, request.UserId);

        var notification = await _notificationRepository.GetByIdAsync(request.NotificationId, cancellationToken);
        if (notification == null)
            return new DismissNotificationResponse { Success = false, Message = "الإشعار غير موجود" };

        if (notification.RecipientId != request.UserId)
            return new DismissNotificationResponse { Success = false, Message = "غير مصرح لك" };

        notification.IsDismissed = true;
        await _notificationRepository.UpdateAsync(notification, cancellationToken);

        // تدقيق يدوي مع ذكر اسم ومعرف المنفذ
        var performerName = _currentUserService.Username;
        var performerId = _currentUserService.UserId;
        var notes = $"تم إخفاء الإشعار {notification.Id} بواسطة {performerName} (ID={performerId})";
        await _auditService.LogAuditAsync(
            entityType: "Notification",
            entityId: notification.Id,
            action: AuditAction.UPDATE,
            oldValues: null,
            newValues: JsonSerializer.Serialize(new { Dismissed = true }),
            performedBy: performerId,
            notes: notes,
            cancellationToken: cancellationToken);

        return new DismissNotificationResponse { Success = true, Message = "تم الإخفاء بنجاح" };
    }
}
