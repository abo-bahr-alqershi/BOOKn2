using MediatR;

namespace YemenBooking.Application.Features.Notifications.Commands.DismissNotification;

/// <summary>
/// أمر إخفاء إشعار
/// Command to dismiss a notification
/// </summary>
public class DismissNotificationCommand : IRequest<DismissNotificationResponse>
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
/// استجابة إخفاء الإشعار
/// </summary>
public class DismissNotificationResponse
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