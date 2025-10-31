using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان إعدادات المستخدم
/// User settings entity
/// </summary>
[Display(Name = "إعدادات المستخدم")]
public class UserSettings : BaseEntity<Guid>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    [Display(Name = "معرف المستخدم")]
    public Guid UserId { get; set; }

    /// <summary>
    /// اللغة المفضلة
    /// Preferred language
    /// </summary>
    [Display(Name = "اللغة المفضلة")]
    [MaxLength(10)]
    public string? PreferredLanguage { get; set; } = "ar";

    /// <summary>
    /// العملة المفضلة
    /// Preferred currency
    /// </summary>
    [Display(Name = "العملة المفضلة")]
    [MaxLength(3)]
    public string? PreferredCurrency { get; set; } = "YER";

    /// <summary>
    /// المنطقة الزمنية
    /// Time zone
    /// </summary>
    [Display(Name = "المنطقة الزمنية")]
    [MaxLength(50)]
    public string? TimeZone { get; set; } = "Asia/Aden";

    /// <summary>
    /// تفعيل الوضع الليلي
    /// Dark mode enabled
    /// </summary>
    [Display(Name = "الوضع الليلي")]
    public bool DarkMode { get; set; } = false;

    /// <summary>
    /// تلقي إشعارات الحجوزات
    /// Booking notifications enabled
    /// </summary>
    [Display(Name = "إشعارات الحجوزات")]
    public bool BookingNotifications { get; set; } = true;

    /// <summary>
    /// تلقي إشعارات العروض
    /// Promotional notifications enabled
    /// </summary>
    [Display(Name = "إشعارات العروض")]
    public bool PromotionalNotifications { get; set; } = true;

    /// <summary>
    /// تلقي إشعارات البريد الإلكتروني
    /// Email notifications enabled
    /// </summary>
    [Display(Name = "إشعارات البريد الإلكتروني")]
    public bool EmailNotifications { get; set; } = true;

    /// <summary>
    /// تلقي إشعارات الرسائل النصية
    /// SMS notifications enabled
    /// </summary>
    [Display(Name = "إشعارات الرسائل النصية")]
    public bool SmsNotifications { get; set; } = false;

    /// <summary>
    /// تلقي إشعارات دفع
    /// Push notifications enabled
    /// </summary>
    [Display(Name = "إشعارات الدفع")]
    public bool PushNotifications { get; set; } = true;

    /// <summary>
    /// إعدادات إضافية (JSON)
    /// Additional settings (JSON)
    /// </summary>
    [Display(Name = "إعدادات إضافية")]
    public Dictionary<string, object>? AdditionalSettings { get; set; }

    /// <summary>
    /// المستخدم المرتبط
    /// Related user
    /// </summary>
    public virtual User? User { get; set; }
}
