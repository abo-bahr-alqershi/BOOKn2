using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// DTO لنتائج تحليلات البحث
    /// DTO for search analytics results
    /// </summary>
    public class SearchAnalyticsDto
    {
        /// <summary>
        /// إجمالي عدد عمليات البحث
        /// Total number of searches
        /// </summary>
        public int TotalSearches { get; set; }

        /// <summary>
        /// عدد عمليات البحث عن الكيانات
        /// Number of property searches
        /// </summary>
        public int PropertySearches { get; set; }

        /// <summary>
        /// عدد عمليات البحث عن الوحدات
        /// Number of unit searches
        /// </summary>
        public int UnitSearches { get; set; }

        /// <summary>
        /// عمليات البحث حسب اليوم
        /// Searches count grouped by day
        /// </summary>
        public List<SearchCountByDayDto> SearchesByDay { get; set; } = new List<SearchCountByDayDto>();
    }

    public class SearchCountByDayDto
    {
        /// <summary>
        /// التاريخ
        /// Date
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>
        /// عدد عمليات البحث في ذلك اليوم
        /// Search count on that day
        /// </summary>
        public int Count { get; set; }
    }
} 