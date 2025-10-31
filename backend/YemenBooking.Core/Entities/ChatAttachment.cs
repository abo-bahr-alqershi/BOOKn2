namespace YemenBooking.Core.Entities
{
    using System;
    using System.ComponentModel.DataAnnotations;

    /// <summary>
    /// ملف تعريف مرفق داخل محادثة
    /// Entity representing a chat attachment
    /// </summary>
    [Display(Name = "مرفق المحادثة")]
    public class ChatAttachment : BaseEntity<Guid>
    {
        /// <summary>
        /// معرف المحادثة المرتبط بالمرفق
        /// ID of the conversation this attachment belongs to
        /// </summary>
        [Display(Name = "معرف المحادثة")]
        public Guid ConversationId { get; set; }

        /// <summary>
        /// اسم الملف الأصلي
        /// Original file name
        /// </summary>
        [Display(Name = "اسم الملف الأصلي")]
        public string FileName { get; set; } = string.Empty;

        /// <summary>
        /// نوع المحتوى (MIME type)
        /// Content type of the file
        /// </summary>
        [Display(Name = "نوع المحتوى")]
        public string ContentType { get; set; } = string.Empty;

        /// <summary>
        /// حجم الملف بالبايت
        /// Size of the file in bytes
        /// </summary>
        [Display(Name = "حجم الملف (بايت)")]
        public long FileSize { get; set; }

        /// <summary>
        /// المسار على الخادم حيث يخزن الملف
        /// File path on server
        /// </summary>
        [Display(Name = "مسار الملف على الخادم")]
        public string FilePath { get; set; } = string.Empty;
        /// <summary>
        /// URL of the thumbnail image (optional)
        /// </summary>
        public string? ThumbnailUrl { get; set; }
        /// <summary>
        /// Additional metadata as JSON string (optional)
        /// </summary>
        public string? Metadata { get; set; }

        /// <summary>
        /// الرسالة المرتبط بها هذا المرفق (اختياري قبل الإسناد)
        /// The message this attachment is associated with (nullable until assigned)
        /// </summary>
        public Guid? MessageId { get; set; }

        /// <summary>
        /// Navigation property للرسالة المرتبط بها المرفق
        /// </summary>
        public virtual ChatMessage? Message { get; set; }

        /// <summary>
        /// مدة المرفق بالثواني (للصوت/الفيديو)
        /// Attachment duration in seconds (audio/video)
        /// </summary>
        public int? DurationSeconds { get; set; }

        /// <summary>
        /// المستخدم الذي رفع الملف
        /// User who uploaded the file
        /// </summary>
        [Display(Name = "رفعه بواسطة")]
        public Guid UploadedBy { get; set; }

        /// <summary>
        /// تاريخ رفع الملف
        /// Date when the file was uploaded
        /// </summary>
        [Display(Name = "تاريخ الرفع")]
        public new DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    }
}