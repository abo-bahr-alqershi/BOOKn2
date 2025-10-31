using System.Collections.Generic;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// إحصائيات الصور
    /// Image statistics DTO (total count, total size, counts by category/status, average size, primary count)
    /// </summary>
    public class ImageStatisticsDto
    {
        /// <summary>
        /// إجمالي عدد الصور
        /// Total images count
        /// </summary>
        public int TotalImages { get; set; }

        /// <summary>
        /// الحجم الكلي للصور بالبايت
        /// Total size in bytes
        /// </summary>
        public long TotalSize { get; set; }

        /// <summary>
        /// عدد الصور حسب الفئة
        /// Images count by category
        /// </summary>
        public Dictionary<ImageCategory, int> ByCategory { get; set; } = new Dictionary<ImageCategory, int>();

        /// <summary>
        /// عدد الصور حسب حالة المعالجة
        /// Images count by processing status
        /// </summary>
        public Dictionary<string, int> ByStatus { get; set; } = new Dictionary<string, int>();

        /// <summary>
        /// متوسط حجم الصورة بالبايت
        /// Average image size
        /// </summary>
        public double AverageSize { get; set; }

        /// <summary>
        /// عدد الصور الرئيسية
        /// Primary images count
        /// </summary>
        public int PrimaryImages { get; set; }
    }
} 