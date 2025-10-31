using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Commands;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application_New.Core.Enums;

namespace YemenBooking.Application.Features.Notifications.Commands.MarkAllNotificationsAsRead;

/// <summary>
/// معالج أمر تحديد جميع الإشعارات كمقروءة (موبايل)
/// </summary>
public class MarkAllNotificationsAsReadCommandHandler : IRequestHandler<MarkAllNotificationsAsReadCommand, MarkAllNotificationsAsReadResponse>
{
    private readonly INotificationRepository _notificationRepository;
    private readonly IAuditService _auditService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<MarkAllNotificationsAsReadCommandHandler> _logger;

    public MarkAllNotificationsAsReadCommandHandler(INotificationRepository notificationRepository, IAuditService auditService, ICurrentUserService currentUserService, ILogger<MarkAllNotificationsAsReadCommandHandler> logger)
    {
        _notificationRepository = notificationRepository;
        _auditService = auditService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    public async Task<MarkAllNotificationsAsReadResponse> Handle(MarkAllNotificationsAsReadCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("تحديد كل الإشعارات كمقروءة للمستخدم {UserId}", request.UserId);

        // الحصول على جميع الإشعارات غير المقروءة للمستخدم
        var allNotifications = await _notificationRepository.GetAllAsync(cancellationToken);
        var userNotifications = allNotifications?.Where(n => n.RecipientId == request.UserId).ToList();
        var unreadNotifications = userNotifications?.Where(n => !n.IsRead).ToList();
        var updatedCount = 0;
        
        // تحديث كل إشعار على حدة
        foreach (var notification in unreadNotifications)
        {
            notification.IsRead = true;
            // Store UTC; client will receive localized times via queries/DTOs
            notification.ReadAt = DateTime.UtcNow;
            await _notificationRepository.UpdateAsync(notification, cancellationToken);
            updatedCount++;
        }

        // تدقيق يدوي مع ذكر اسم ومعرف المنفذ
        var performerName = _currentUserService.Username;
        var performerId = _currentUserService.UserId;
        var notes = $"تم تحديد {updatedCount} إشعارات كمقروءة بواسطة {performerName} (ID={performerId})";
        await _auditService.LogAuditAsync(
            entityType: "Notification",
            entityId: request.UserId,
            action: YemenBooking.Core.Entities.AuditAction.UPDATE,
            oldValues: null,
            newValues: JsonSerializer.Serialize(new { MarkedAsReadCount = updatedCount }),
            performedBy: performerId,
            notes: notes,
            cancellationToken: cancellationToken);

        return new MarkAllNotificationsAsReadResponse { UpdatedCount = updatedCount, Message = "تم التحديث" };
    }
}
