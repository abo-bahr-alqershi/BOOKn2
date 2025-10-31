using MediatR;
using YemenBooking.Application.Features.Notifications.Commands;
using YemenBooking.Application.Features.Notifications.DTOs;

namespace YemenBooking.Application.Features.Notifications.Commands.ManageNotifications;

/// <summary>
/// أمر تحديد إشعار كمقروء
/// Command to mark notification as read
/// </summary>
public class MarkNotificationAsReadCommand : IRequest<MarkNotificationAsReadResponse>
{
    /// <summary>
    /// معرف الإشعار
    /// </summary>
    public Guid NotificationId { get; set; }
    
    /// <summary>
    /// معرف المستخدم (للتحقق من الصلاحية)
    /// </summary>
    public Guid UserId { get; set; }
}

/// <summary>
/// استجابة تحديد الإشعار كمقروء
/// </summary>
public class MarkNotificationAsReadResponse
{
    /// <summary>
    /// نجاح العملية
    /// </summary>
    public bool Success { get; set; }
    
    /// <summary>
    /// رسالة النتيجة
    /// </summary>
    public string Message { get; set; } = string.Empty;
}