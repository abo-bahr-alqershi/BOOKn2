namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// تقدم رفع الصورة
    /// Image upload progress DTO
    /// </summary>
    public class UploadProgressDto
    {
        /// <summary>
        /// معرف المهمة لتتبع التقدم
        /// Task ID for progress tracking
        /// </summary>
        public string TaskId { get; set; } = string.Empty;

        /// <summary>
        /// اسم الملف الجاري رفعه
        /// Filename in upload process
        /// </summary>
        public string Filename { get; set; } = string.Empty;

        /// <summary>
        /// النسبة المئوية للتقدم
        /// Progress percentage
        /// </summary>
        public int Progress { get; set; }

        /// <summary>
        /// حالة الرفع (uploading, processing, completed, failed)
        /// Upload status
        /// </summary>
        public string Status { get; set; } = string.Empty;

        /// <summary>
        /// رسالة الخطأ إن وجدت
        /// Error message if any
        /// </summary>
        public string? Error { get; set; }

        /// <summary>
        /// معرف الصورة عند الانتهاء
        /// Image ID when upload completed
        /// </summary>
        public Guid? ImageId { get; set; }
    }
} 