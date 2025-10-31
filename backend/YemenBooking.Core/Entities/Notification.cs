using System.ComponentModel.DataAnnotations;

namespace YemenBooking.Core.Entities;

/// <summary>
/// كيان الإشعار في النظام
/// Notification entity in the system
/// </summary>
[Display(Name = "كيان الإشعار في النظام")]
public class Notification : BaseEntity<Guid>
{
    /// <summary>
    /// نوع الإشعار
    /// Notification type
    /// </summary>
    [Display(Name = "نوع الإشعار")]
    public string Type { get; set; } = null!;
    
    /// <summary>
    /// عنوان الإشعار
    /// Notification title
    /// </summary>
    [Display(Name = "عنوان الإشعار")]
    public string Title { get; set; } = null!;
    
    /// <summary>
    /// محتوى الإشعار
    /// Notification message
    /// </summary>
    [Display(Name = "محتوى الإشعار")]
    public string Message { get; set; } = null!;
    
    /// <summary>
    /// عنوان الإشعار بالعربية
    /// Notification title in Arabic
    /// </summary>
    [Display(Name = "عنوان الإشعار بالعربية")]
    public string? TitleAr { get; set; }
    
    /// <summary>
    /// محتوى الإشعار بالعربية
    /// Notification message in Arabic
    /// </summary>
    [Display(Name = "محتوى الإشعار بالعربية")]
    public string? MessageAr { get; set; }
    
    /// <summary>
    /// أولوية الإشعار
    /// Notification priority
    /// </summary>
    [Display(Name = "أولوية الإشعار")]
    public string Priority { get; set; } = "MEDIUM"; // LOW, MEDIUM, HIGH, URGENT
    
    /// <summary>
    /// حالة الإشعار
    /// Notification status
    /// </summary>
    [Display(Name = "حالة الإشعار")]
    public string Status { get; set; } = "PENDING"; // PENDING, SENT, DELIVERED, READ, FAILED
    
    /// <summary>
    /// معرف المستلم
    /// Recipient ID
    /// </summary>
    [Display(Name = "معرف المستلم")]
    public Guid RecipientId { get; set; }
    
    /// <summary>
    /// معرف المرسل (اختياري)
    /// Sender ID (optional)
    /// </summary>
    [Display(Name = "معرف المرسل")]
    public Guid? SenderId { get; set; }
    
    /// <summary>
    /// بيانات إضافية (JSON)
    /// Additional data (JSON)
    /// </summary>
    [Display(Name = "بيانات إضافية")]
    public string? Data { get; set; }
    
    /// <summary>
    /// قنوات الإرسال
    /// Delivery channels
    /// </summary>
    [Display(Name = "قنوات الإرسال")]
    public List<string> Channels { get; set; } = new() { "IN_APP" }; // IN_APP, EMAIL, SMS, PUSH
    
    /// <summary>
    /// القنوات التي تم الإرسال إليها
    /// Channels that were sent to
    /// </summary>
    [Display(Name = "القنوات التي تم الإرسال إليها")]
    public List<string> SentChannels { get; set; } = new();
    
    /// <summary>
    /// هل تم قراءة الإشعار
    /// Is notification read
    /// </summary>
    [Display(Name = "هل تم قراءة الإشعار")]
    public bool IsRead { get; set; } = false;
    
    /// <summary>
    /// هل تم إخفاء الإشعار
    /// Is notification dismissed
    /// </summary>
    [Display(Name = "هل تم إخفاء الإشعار")]
    public bool IsDismissed { get; set; } = false;
    
    /// <summary>
    /// هل الإشعار يتطلب إجراء
    /// Does notification require action
    /// </summary>
    [Display(Name = "هل الإشعار يتطلب إجراء")]
    public bool RequiresAction { get; set; } = false;
    
    /// <summary>
    /// هل يمكن إخفاء الإشعار
    /// Can notification be dismissed
    /// </summary>
    [Display(Name = "هل يمكن إخفاء الإشعار")]
    public bool CanDismiss { get; set; } = true;
    
    /// <summary>
    /// تاريخ القراءة
    /// Read date
    /// </summary>
    [Display(Name = "تاريخ القراءة")]
    public DateTime? ReadAt { get; set; }
    
    /// <summary>
    /// تاريخ الإخفاء
    /// Dismiss date
    /// </summary>
    [Display(Name = "تاريخ الإخفاء")]
    public DateTime? DismissedAt { get; set; }
    
    /// <summary>
    /// موعد الإرسال المجدول
    /// Scheduled delivery time
    /// </summary>
    [Display(Name = "موعد الإرسال المجدول")]
    public DateTime? ScheduledFor { get; set; }
    
    /// <summary>
    /// تاريخ انتهاء الصلاحية
    /// Expiration date
    /// </summary>
    [Display(Name = "تاريخ انتهاء الصلاحية")]
    public DateTime? ExpiresAt { get; set; }
    
    /// <summary>
    /// تاريخ التسليم
    /// Delivery date
    /// </summary>
    [Display(Name = "تاريخ التسليم")]
    public DateTime? DeliveredAt { get; set; }
    
    /// <summary>
    /// معرف المجموعة (لتجميع الإشعارات المترابطة)
    /// Group ID (for grouping related notifications)
    /// </summary>
    [Display(Name = "معرف المجموعة")]
    public string? GroupId { get; set; }
    
    /// <summary>
    /// معرف الدفعة (للإشعارات المرسلة في دفعة واحدة)
    /// Batch ID (for notifications sent in a batch)
    /// </summary>
    [Display(Name = "معرف الدفعة")]
    public string? BatchId { get; set; }
    
    /// <summary>
    /// أيقونة الإشعار
    /// Notification icon
    /// </summary>
    [Display(Name = "أيقونة الإشعار")]
    public string? Icon { get; set; }
    
    /// <summary>
    /// لون الإشعار
    /// Notification color
    /// </summary>
    [Display(Name = "لون الإشعار")]
    public string? Color { get; set; }
    
    /// <summary>
    /// رابط الإجراء
    /// Action URL
    /// </summary>
    [Display(Name = "رابط الإجراء")]
    public string? ActionUrl { get; set; }
    
    /// <summary>
    /// نص زر الإجراء
    /// Action button text
    /// </summary>
    [Display(Name = "نص زر الإجراء")]
    public string? ActionText { get; set; }
    
    // Navigation Properties
    
    /// <summary>
    /// المستلم
    /// Recipient
    /// </summary>
    [Display(Name = "المستلم")]
    public virtual User Recipient { get; set; } = null!;
    
    /// <summary>
    /// المرسل
    /// Sender
    /// </summary>
    [Display(Name = "المرسل")]
    public virtual User? Sender { get; set; }
    
    // Helper Properties
    
    /// <summary>
    /// هل الإشعار منتهي الصلاحية
    /// Is notification expired
    /// </summary>
    [Display(Name = "هل الإشعار منتهي الصلاحية")]
    public bool IsExpired => ExpiresAt.HasValue && ExpiresAt < DateTime.UtcNow;
    
    /// <summary>
    /// هل الإشعار جاهز للإرسال
    /// Is notification ready to send
    /// </summary>
    [Display(Name = "هل الإشعار جاهز للإرسال")]
    public bool IsReadyToSend => Status == "PENDING" && 
                                (!ScheduledFor.HasValue || ScheduledFor <= DateTime.UtcNow) &&
                                !IsExpired;
    
    /// <summary>
    /// هل الإشعار تم تسليمه
    /// Is notification delivered
    /// </summary>
    [Display(Name = "هل الإشعار تم تسليمه")]
    public bool IsDelivered => Status == "DELIVERED" || Status == "READ";
    
    /// <summary>
    /// النص المناسب حسب اللغة
    /// Appropriate text based on language
    /// </summary>
    public string GetTitle(string language = "ar") => 
        language == "ar" && !string.IsNullOrEmpty(TitleAr) ? TitleAr : Title;
    
    /// <summary>
    /// المحتوى المناسب حسب اللغة
    /// Appropriate content based on language
    /// </summary>
    public string GetMessage(string language = "ar") => 
        language == "ar" && !string.IsNullOrEmpty(MessageAr) ? MessageAr : Message;
    
    // Helper Methods
    
    /// <summary>
    /// تحديد الإشعار كمقروء
    /// Mark notification as read
    /// </summary>
    public void MarkAsRead()
    {
        if (!IsRead)
        {
            IsRead = true;
            ReadAt = DateTime.UtcNow;
            Status = "READ";
            UpdatedAt = DateTime.UtcNow;
        }
    }
    
    /// <summary>
    /// إخفاء الإشعار
    /// Dismiss notification
    /// </summary>
    public void Dismiss()
    {
        if (CanDismiss && !IsDismissed)
        {
            IsDismissed = true;
            DismissedAt = DateTime.UtcNow;
            UpdatedAt = DateTime.UtcNow;
        }
    }
    
    /// <summary>
    /// تحديد الإشعار كمرسل
    /// Mark notification as sent
    /// </summary>
    public void MarkAsSent(string channel)
    {
        if (!SentChannels.Contains(channel))
        {
            SentChannels.Add(channel);
        }
        
        Status = "SENT";
        UpdatedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// تحديد الإشعار كمسلم
    /// Mark notification as delivered
    /// </summary>
    public void MarkAsDelivered()
    {
        Status = "DELIVERED";
        DeliveredAt = DateTime.UtcNow;
        UpdatedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// تحديد الإشعار كفاشل
    /// Mark notification as failed
    /// </summary>
    public void MarkAsFailed(string reason = "")
    {
        Status = "FAILED";
        if (!string.IsNullOrEmpty(reason))
        {
            Data = reason;
        }
        UpdatedAt = DateTime.UtcNow;
    }
    
    /// <summary>
    /// إضافة قناة إرسال
    /// Add delivery channel
    /// </summary>
    public void AddChannel(string channel)
    {
        if (!Channels.Contains(channel))
        {
            Channels.Add(channel);
            UpdatedAt = DateTime.UtcNow;
        }
    }
    
    /// <summary>
    /// إزالة قناة إرسال
    /// Remove delivery channel
    /// </summary>
    public void RemoveChannel(string channel)
    {
        if (Channels.Remove(channel))
        {
            UpdatedAt = DateTime.UtcNow;
        }
    }
    
    // Static Factory Methods
    
    /// <summary>
    /// إنشاء إشعار حجز جديد
    /// Create booking notification
    /// </summary>
    public static Notification CreateBookingNotification(
        Guid recipientId, 
        string bookingNumber, 
        string type = "BOOKING_CREATED",
        string priority = "MEDIUM")
    {
        return new Notification
        {
            RecipientId = recipientId,
            Type = type,
            Title = "حجز جديد",
            Message = $"تم إنشاء حجز جديد برقم {bookingNumber}",
            TitleAr = "حجز جديد",
            MessageAr = $"تم إنشاء حجز جديد برقم {bookingNumber}",
            Priority = priority,
            Data = $"{{\"bookingNumber\": \"{bookingNumber}\"}}"
        };
    }
    
    /// <summary>
    /// إنشاء إشعار دفع
    /// Create payment notification
    /// </summary>
    public static Notification CreatePaymentNotification(
        Guid recipientId, 
        string amount, 
        string status,
        string priority = "HIGH")
    {
        return new Notification
        {
            RecipientId = recipientId,
            Type = "PAYMENT_UPDATE",
            Title = "تحديث الدفع",
            Message = $"تم {status} دفعة بمبلغ {amount}",
            Priority = priority,
            RequiresAction = status == "فشل"
        };
    }
}