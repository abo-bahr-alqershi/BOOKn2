namespace YemenBooking.Application.Features.Users.DTOs;

/// <summary>
/// بيانات إعدادات المستخدم
/// User settings data transfer object
/// </summary>
public class UserSettingsDto
{
    /// <summary>
    /// اللغة المفضلة
    /// Preferred language
    /// </summary>
    public string PreferredLanguage { get; set; } = "ar";
    
    /// <summary>
    /// العملة المفضلة
    /// Preferred currency
    /// </summary>
    public string PreferredCurrency { get; set; } = "YER";
    
    /// <summary>
    /// المنطقة الزمنية
    /// Time zone
    /// </summary>
    public string TimeZone { get; set; } = "Asia/Aden";
    
    /// <summary>
    /// تفعيل الوضع الليلي
    /// Dark mode enabled
    /// </summary>
    public bool DarkMode { get; set; }
    
    /// <summary>
    /// إعدادات الإشعارات
    /// Notification settings
    /// </summary>
    public NotificationSettingsDto NotificationSettings { get; set; } = new();
    
    /// <summary>
    /// إعدادات إضافية
    /// Additional settings
    /// </summary>
    public Dictionary<string, object> AdditionalSettings { get; set; } = new();
}

/// <summary>
/// بيانات إعدادات الإشعارات
/// Notification settings data transfer object
/// </summary>
public class NotificationSettingsDto
{
    /// <summary>
    /// تلقي إشعارات الحجوزات
    /// BookingDto notifications enabled
    /// </summary>
    public bool BookingNotifications { get; set; } = true;
    
    /// <summary>
    /// تلقي إشعارات العروض
    /// Promotional notifications enabled
    /// </summary>
    public bool PromotionalNotifications { get; set; } = true;
    
    /// <summary>
    /// تلقي إشعارات البريد الإلكتروني
    /// Email notifications enabled
    /// </summary>
    public bool EmailNotifications { get; set; } = true;
    
    /// <summary>
    /// تلقي إشعارات الرسائل النصية
    /// SMS notifications enabled
    /// </summary>
    public bool SmsNotifications { get; set; } = false;
    
    /// <summary>
    /// تلقي إشعارات دفع
    /// Push notifications enabled
    /// </summary>
    public bool PushNotifications { get; set; } = true;
}
