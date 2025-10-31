namespace YemenBooking.Core.Entities
{
    using System;
    using System.ComponentModel.DataAnnotations;

    /// <summary>
    /// إعدادات الشات الخاصة بالمستخدم
    /// Entity for user chat settings
    /// </summary>
    [Display(Name = "إعدادات الشات")]
    public class ChatSettings : BaseEntity<Guid>
    {
        [Display(Name = "معرف المستخدم")]
        public Guid UserId { get; set; }

        [Display(Name = "تنبيهات مفعلة")]
        public bool NotificationsEnabled { get; set; } = true;

        [Display(Name = "صوت مفعّل")]
        public bool SoundEnabled { get; set; } = true;

        [Display(Name = "عرض إيصالات القراءة")]
        public bool ShowReadReceipts { get; set; } = true;

        [Display(Name = "عرض مؤشر الكتابة")]
        public bool ShowTypingIndicator { get; set; } = true;

        [Display(Name = "المظهر")]
        public string Theme { get; set; } = "light";

        [Display(Name = "حجم الخط")]
        public string FontSize { get; set; } = "medium";

        [Display(Name = "التحميل التلقائي للوسائط")]
        public bool AutoDownloadMedia { get; set; } = false;

        [Display(Name = "نسخ احتياطي للرسائل")]
        public bool BackupMessages { get; set; } = false;
    }
} 