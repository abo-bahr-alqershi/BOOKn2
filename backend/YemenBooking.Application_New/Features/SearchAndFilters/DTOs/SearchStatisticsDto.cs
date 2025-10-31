using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.SearchAndFilters.DTOs {
    /// <summary>
    /// إحصائيات البحث
    /// </summary>
    public class SearchStatisticsDto
    {
        /// <summary>
        /// مدة البحث بالملي ثانية
        /// Search duration in milliseconds
        /// </summary>
        public long SearchDurationMs { get; set; }

        /// <summary>
        /// عدد الفلاتر المطبقة
        /// Applied filters count
        /// </summary>
        public int AppliedFiltersCount { get; set; }

        /// <summary>
        /// عدد النتائج قبل التصفح
        /// Total results before paging
        /// </summary>
        public int TotalResultsBeforePaging { get; set; }

        /// <summary>
        /// اقتراحات البحث
        /// Search suggestions
        /// </summary>
        public List<string> Suggestions { get; set; } = new List<string>();

        /// <summary>
        /// النطاق السعري للنتائج
        /// Price range of results
        /// </summary>
        public PriceRangeDto? PriceRange { get; set; }

        /// <summary>
        /// عدد العقارات حسب النوع
        /// Properties count by type
        /// </summary>
        public Dictionary<string, int> PropertiesByType { get; set; } = new Dictionary<string, int>();

        /// <summary>
        /// متوسط تقييم العقارات
        /// Average rating of properties
        /// </summary>
        public double AverageRating { get; set; }
    }
} 