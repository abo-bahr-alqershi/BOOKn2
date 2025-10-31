using MediatR;

namespace YemenBooking.Application.Features.Notifications.Commands.MarkAllNotificationsAsRead;

/// <summary>
/// أمر تحديد جميع الإشعارات كمقروءة
/// Command to mark all notifications as read
/// </summary>
public class MarkAllNotificationsAsReadCommand : IRequest<MarkAllNotificationsAsReadResponse>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
}

/// <summary>
/// استجابة تحديد جميع الإشعارات كمقروءة
/// </summary>
public class MarkAllNotificationsAsReadResponse
{
    /// <summary>
    /// عدد الإشعارات التي تم تحديثها
    /// </summary>
    public int UpdatedCount { get; set; }
    
    /// <summary>
    /// رسالة النتيجة
    /// </summary>
    public string Message { get; set; } = string.Empty;
}