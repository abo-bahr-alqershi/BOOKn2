using MediatR;

namespace YemenBooking.Application.Features.Notifications.Commands.NotificationSettings;

/// <summary>
/// أمر تحديث إعدادات الإشعارات للمستخدم
/// Command to update user notification settings
/// </summary>
public class UpdateNotificationSettingsCommand : IRequest<UpdateNotificationSettingsResponse>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// تلقي إشعارات الحجوزات
    /// </summary>
    public bool BookingNotifications { get; set; } = true;
    
    /// <summary>
    /// تلقي إشعارات العروض الترويجية
    /// </summary>
    public bool PromotionalNotifications { get; set; } = true;
    
    /// <summary>
    /// تلقي إشعارات الرد على المراجعات
    /// </summary>
    public bool ReviewResponseNotifications { get; set; } = true;
    
    /// <summary>
    /// تلقي إشعارات بالبريد الإلكتروني
    /// </summary>
    public bool EmailNotifications { get; set; } = true;
    
    /// <summary>
    /// تلقي إشعارات بالرسائل النصية
    /// </summary>
    public bool SmsNotifications { get; set; } = false;
    
    /// <summary>
    /// تلقي إشعارات دفع (Push)
    /// </summary>
    public bool PushNotifications { get; set; } = true;
}

/// <summary>
/// استجابة تحديث إعدادات الإشعارات
/// </summary>
public class UpdateNotificationSettingsResponse
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