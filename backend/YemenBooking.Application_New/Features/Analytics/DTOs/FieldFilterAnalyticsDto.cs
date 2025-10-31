using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// DTO لنتائج احصائيات الفلاتر الديناميكية
    /// DTO for dynamic filter analytics results
    /// </summary>
    public class FieldFilterAnalyticsDto
    {
        /// <summary>
        /// معرف الحقل الديناميكي
        /// Dynamic field identifier
        /// </summary>
        public Guid FieldId { get; set; }

        /// <summary>
        /// قيم الفلتر مع عدد الاستخدامات لكل قيمة
        /// Filter values with usage counts
        /// </summary>
        public List<FilterValueCountDto> ValueCounts { get; set; } = new List<FilterValueCountDto>();
    }

    /// <summary>
    /// DTO لعدد مرات استخدام قيمة فلتر معينة
    /// DTO for count of a specific filter value usage
    /// </summary>
    public class FilterValueCountDto
    {
        /// <summary>
        /// قيمة الفلتر
        /// Filter value
        /// </summary>
        public string FilterValue { get; set; }

        /// <summary>
        /// عدد المرات التي تم فيها استخدام هذه القيمة
        /// Number of times this value was used
        /// </summary>
        public int Count { get; set; }
    }
} 