using System.Collections.Generic;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// نتيجة مرقمة مخصصة للاستخدام في خدمات الصور
    /// Paginated result DTO for image queries
    /// </summary>
    public class PaginatedResultDto<T>
    {
        /// <summary>
        /// قائمة العناصر
        /// Items list
        /// </summary>
        public IEnumerable<T> Items { get; set; } = new List<T>();

        /// <summary>
        /// العدد الكلي للعناصر
        /// Total items count
        /// </summary>
        public int Total { get; set; }

        /// <summary>
        /// الصفحة الحالية
        /// Current page number
        /// </summary>
        public int Page { get; set; }

        /// <summary>
        /// حجم الصفحة
        /// Items per page
        /// </summary>
        public int Limit { get; set; }

        /// <summary>
        /// إجمالي عدد الصفحات
        /// Total pages
        /// </summary>
        public int TotalPages { get; set; }

        /// <summary>
        /// بيانات إضافية (ميتا) مثل الإحصائيات المصاحبة للنتيجة
        /// Optional metadata (e.g., aggregated stats)
        /// </summary>
        public object? Metadata { get; set; }
    }
} 