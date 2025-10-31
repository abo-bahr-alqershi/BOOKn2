using System.ComponentModel.DataAnnotations;
using System.Text.Json.Serialization;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان قناة الإشعارات
/// Notification channel entity
/// </summary>
[Display(Name = "قناة الإشعارات")]
public class NotificationChannel : BaseEntity<Guid>
{
    /// <summary>
    /// اسم القناة
    /// Channel name
    /// </summary>
    [Display(Name = "اسم القناة")]
    [Required(ErrorMessage = "اسم القناة مطلوب")]
    [StringLength(100, ErrorMessage = "اسم القناة يجب ألا يتجاوز 100 حرف")]
    public string Name { get; set; } = null!;
    
    /// <summary>
    /// معرف القناة الفريد (للاستخدام في FCM)
    /// Unique channel identifier (for FCM usage)
    /// </summary>
    [Display(Name = "معرف القناة")]
    [Required(ErrorMessage = "معرف القناة مطلوب")]
    [StringLength(50, ErrorMessage = "معرف القناة يجب ألا يتجاوز 50 حرف")]
    public string Identifier { get; set; } = null!;
    
    /// <summary>
    /// وصف القناة
    /// Channel description
    /// </summary>
    [Display(Name = "وصف القناة")]
    [StringLength(500, ErrorMessage = "وصف القناة يجب ألا يتجاوز 500 حرف")]
    public string? Description { get; set; }
    
    /// <summary>
    /// أيقونة القناة
    /// Channel icon
    /// </summary>
    [Display(Name = "أيقونة القناة")]
    public string? Icon { get; set; }
    
    /// <summary>
    /// لون القناة
    /// Channel color
    /// </summary>
    [Display(Name = "لون القناة")]
    public string? Color { get; set; }
    
    /// <summary>
    /// هل القناة نشطة
    /// Is channel active
    /// </summary>
    [Display(Name = "القناة نشطة")]
    public bool IsActive { get; set; } = true;
    
    /// <summary>
    /// هل القناة خاصة (تتطلب إذن خاص للانضمام)
    /// Is channel private (requires special permission to join)
    /// </summary>
    [Display(Name = "قناة خاصة")]
    public bool IsPrivate { get; set; } = false;
    
    /// <summary>
    /// هل القناة قابلة للحذف
    /// Is channel deletable
    /// </summary>
    [Display(Name = "قابلة للحذف")]
    public bool IsDeletable { get; set; } = true;
    
    /// <summary>
    /// نوع القناة
    /// Channel type
    /// </summary>
    [Display(Name = "نوع القناة")]
    public string Type { get; set; } = "CUSTOM"; // SYSTEM, CUSTOM, ROLE_BASED, EVENT_BASED
    
    /// <summary>
    /// الأدوار المسموح لها بالانضمام (في حالة القنوات المبنية على الأدوار)
    /// Allowed roles to join (for role-based channels)
    /// </summary>
    [Display(Name = "الأدوار المسموحة")]
    public List<string> AllowedRoles { get; set; } = new();
    
    /// <summary>
    /// إعدادات القناة (JSON)
    /// Channel settings (JSON)
    /// </summary>
    [Display(Name = "إعدادات القناة")]
    public string? Settings { get; set; }
    
    /// <summary>
    /// عدد المستخدمين المشتركين
    /// Number of subscribed users
    /// </summary>
    [Display(Name = "عدد المشتركين")]
    public int SubscribersCount { get; set; } = 0;
    
    /// <summary>
    /// عدد الإشعارات المرسلة
    /// Number of notifications sent
    /// </summary>
    [Display(Name = "عدد الإشعارات المرسلة")]
    public int NotificationsSentCount { get; set; } = 0;
    
    /// <summary>
    /// آخر وقت تم فيه إرسال إشعار
    /// Last notification sent time
    /// </summary>
    [Display(Name = "آخر إشعار")]
    public DateTime? LastNotificationAt { get; set; }
    
    /// <summary>
    /// معرف المنشئ
    /// Creator ID
    /// </summary>
    [Display(Name = "معرف المنشئ")]
    public Guid? CreatedBy { get; set; }
    
    // Navigation Properties
    
    /// <summary>
    /// المستخدمون المشتركون في القناة
    /// Users subscribed to the channel
    /// </summary>
    [Display(Name = "المستخدمون المشتركون")]
    public virtual ICollection<UserChannel> UserChannels { get; set; } = new List<UserChannel>();
    
    /// <summary>
    /// الإشعارات المرسلة عبر القناة
    /// Notifications sent through the channel
    /// </summary>
    [Display(Name = "الإشعارات المرسلة")]
    public virtual ICollection<NotificationChannelHistory> NotificationHistories { get; set; } = new List<NotificationChannelHistory>();
    
    /// <summary>
    /// المنشئ
    /// Creator
    /// </summary>
    [Display(Name = "المنشئ")]
    public virtual User? Creator { get; set; }
    
    // Helper Methods
    
    /// <summary>
    /// إضافة مشترك
    /// Add subscriber
    /// </summary>
    public void AddSubscriber()
    {
        SubscribersCount++;
        UpdatedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// إزالة مشترك
    /// Remove subscriber
    /// </summary>
    public void RemoveSubscriber()
    {
        if (SubscribersCount > 0)
        {
            SubscribersCount--;
            UpdatedAt = DateTime.UtcNow;
        }
    }
    
    /// <summary>
    /// تسجيل إرسال إشعار
    /// Record notification sent
    /// </summary>
    public void RecordNotificationSent()
    {
        NotificationsSentCount++;
        LastNotificationAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// التحقق من إمكانية الوصول للقناة
    /// Check if channel is accessible
    /// </summary>
    public bool IsAccessibleBy(string? userRole)
    {
        if (!IsActive) return false;
        if (!IsPrivate) return true;
        if (Type == "ROLE_BASED" && !string.IsNullOrEmpty(userRole))
        {
            return AllowedRoles.Contains(userRole);
        }
        return false;
    }
    
    /// <summary>
    /// الحصول على موضوع FCM
    /// Get FCM topic
    /// </summary>
    public string GetFcmTopic() => $"channel_{Identifier}";
    
    // Static Factory Methods
    
    /// <summary>
    /// إنشاء قناة نظام
    /// Create system channel
    /// </summary>
    public static NotificationChannel CreateSystemChannel(string name, string identifier)
    {
        return new NotificationChannel
        {
            Name = name,
            Identifier = identifier,
            Type = "SYSTEM",
            IsActive = true,
            IsPrivate = false,
            IsDeletable = false,
            Description = $"قناة نظام: {name}"
        };
    }
    
    /// <summary>
    /// إنشاء قناة مخصصة
    /// Create custom channel
    /// </summary>
    public static NotificationChannel CreateCustomChannel(string name, string identifier, Guid createdBy)
    {
        return new NotificationChannel
        {
            Name = name,
            Identifier = identifier,
            Type = "CUSTOM",
            IsActive = true,
            CreatedBy = createdBy,
            Description = $"قناة مخصصة: {name}"
        };
    }
}

/// <summary>
/// كيان ربط المستخدم بالقناة
/// User channel relationship entity
/// </summary>
[Display(Name = "اشتراك المستخدم في القناة")]
public class UserChannel : BaseEntity<Guid>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    [Display(Name = "معرف المستخدم")]
    [Required]
    public Guid UserId { get; set; }
    
    /// <summary>
    /// معرف القناة
    /// Channel ID
    /// </summary>
    [Display(Name = "معرف القناة")]
    [Required]
    public Guid ChannelId { get; set; }
    
    /// <summary>
    /// هل الاشتراك نشط
    /// Is subscription active
    /// </summary>
    [Display(Name = "الاشتراك نشط")]
    public bool IsActive { get; set; } = true;
    
    /// <summary>
    /// هل الإشعارات مكتومة
    /// Are notifications muted
    /// </summary>
    [Display(Name = "الإشعارات مكتومة")]
    public bool IsMuted { get; set; } = false;
    
    /// <summary>
    /// تاريخ الاشتراك
    /// Subscription date
    /// </summary>
    [Display(Name = "تاريخ الاشتراك")]
    public DateTime SubscribedAt { get; set; }
    
    /// <summary>
    /// تاريخ إلغاء الاشتراك
    /// Unsubscription date
    /// </summary>
    [Display(Name = "تاريخ إلغاء الاشتراك")]
    public DateTime? UnsubscribedAt { get; set; }
    
    /// <summary>
    /// عدد الإشعارات المستلمة
    /// Number of notifications received
    /// </summary>
    [Display(Name = "عدد الإشعارات المستلمة")]
    public int NotificationsReceivedCount { get; set; } = 0;
    
    /// <summary>
    /// آخر إشعار مستلم
    /// Last notification received
    /// </summary>
    [Display(Name = "آخر إشعار مستلم")]
    public DateTime? LastNotificationReceivedAt { get; set; }
    
    /// <summary>
    /// ملاحظات
    /// Notes
    /// </summary>
    [Display(Name = "ملاحظات")]
    public string? Notes { get; set; }
    
    // Navigation Properties
    
    /// <summary>
    /// المستخدم
    /// User
    /// </summary>
    [Display(Name = "المستخدم")]
    public virtual User User { get; set; } = null!;
    
    /// <summary>
    /// القناة
    /// Channel
    /// </summary>
    [Display(Name = "القناة")]
    [JsonIgnore]
    public virtual NotificationChannel Channel { get; set; } = null!;
    
    // Helper Methods
    
    /// <summary>
    /// تفعيل الاشتراك
    /// Activate subscription
    /// </summary>
    public void Activate()
    {
        IsActive = true;
        IsMuted = false;
        UnsubscribedAt = null;
        UpdatedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// إلغاء الاشتراك
    /// Deactivate subscription
    /// </summary>
    public void Deactivate()
    {
        IsActive = false;
        UnsubscribedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// كتم الإشعارات
    /// Mute notifications
    /// </summary>
    public void Mute()
    {
        IsMuted = true;
        UpdatedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// إلغاء كتم الإشعارات
    /// Unmute notifications
    /// </summary>
    public void Unmute()
    {
        IsMuted = false;
        UpdatedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// تسجيل استلام إشعار
    /// Record notification received
    /// </summary>
    public void RecordNotificationReceived()
    {
        NotificationsReceivedCount++;
        LastNotificationReceivedAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }
}

/// <summary>
/// كيان سجل إشعارات القناة
/// Channel notification history entity
/// </summary>
[Display(Name = "سجل إشعارات القناة")]
public class NotificationChannelHistory : BaseEntity<Guid>
{
    /// <summary>
    /// معرف القناة
    /// Channel ID
    /// </summary>
    [Display(Name = "معرف القناة")]
    [Required]
    public Guid ChannelId { get; set; }
    
    /// <summary>
    /// معرف الإشعار
    /// Notification ID
    /// </summary>
    [Display(Name = "معرف الإشعار")]
    public Guid? NotificationId { get; set; }
    
    /// <summary>
    /// عنوان الإشعار
    /// Notification title
    /// </summary>
    [Display(Name = "عنوان الإشعار")]
    public string Title { get; set; } = null!;
    
    /// <summary>
    /// محتوى الإشعار
    /// Notification content
    /// </summary>
    [Display(Name = "محتوى الإشعار")]
    public string Content { get; set; } = null!;
    
    /// <summary>
    /// نوع الإشعار
    /// Notification type
    /// </summary>
    [Display(Name = "نوع الإشعار")]
    public string Type { get; set; } = "INFO";
    
    /// <summary>
    /// عدد المستلمين
    /// Number of recipients
    /// </summary>
    [Display(Name = "عدد المستلمين")]
    public int RecipientsCount { get; set; } = 0;
    
    /// <summary>
    /// عدد التسليمات الناجحة
    /// Number of successful deliveries
    /// </summary>
    [Display(Name = "التسليمات الناجحة")]
    public int SuccessfulDeliveries { get; set; } = 0;
    
    /// <summary>
    /// عدد التسليمات الفاشلة
    /// Number of failed deliveries
    /// </summary>
    [Display(Name = "التسليمات الفاشلة")]
    public int FailedDeliveries { get; set; } = 0;
    
    /// <summary>
    /// معرف المرسل
    /// Sender ID
    /// </summary>
    [Display(Name = "معرف المرسل")]
    public Guid? SenderId { get; set; }
    
    /// <summary>
    /// تاريخ الإرسال
    /// Sent date
    /// </summary>
    [Display(Name = "تاريخ الإرسال")]
    public DateTime SentAt { get; set; }
    
    // Navigation Properties
    
    /// <summary>
    /// القناة
    /// Channel
    /// </summary>
    [Display(Name = "القناة")]
    [JsonIgnore]
    public virtual NotificationChannel Channel { get; set; } = null!;
    
    /// <summary>
    /// المرسل
    /// Sender
    /// </summary>
    [Display(Name = "المرسل")]
    public virtual User? Sender { get; set; }
}
