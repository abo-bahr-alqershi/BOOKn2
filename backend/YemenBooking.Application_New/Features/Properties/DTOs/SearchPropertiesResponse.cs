using System;
using System.Collections.Generic;
using YemenBooking.Application.Features.SearchAndFilters;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// استجابة البحث عن العقارات
    /// Search properties response
    /// </summary>
    public class PropertySearchResultDto
    {
        /// <summary>
        /// قائمة العقارات المطابقة للبحث
        /// List of properties matching the search
        /// </summary>
        public List<PropertySearchResultDto> PropertyDto { get; set; } = new();

        /// <summary>
        /// العدد الإجمالي للنتائج
        /// Total count of results
        /// </summary>
        public int TotalCount { get; set; }

        /// <summary>
        /// رقم الصفحة الحالية
        /// Current page number
        /// </summary>
        public int CurrentPage { get; set; }

        /// <summary>
        /// حجم الصفحة
        /// Page size
        /// </summary>
        public int PageSize { get; set; }

        /// <summary>
        /// العدد الإجمالي للصفحات
        /// Total pages count
        /// </summary>
        public int TotalPages { get; set; }

        /// <summary>
        /// هل يوجد صفحة سابقة
        /// Whether there is a previous page
        /// </summary>
        public bool HasPreviousPage { get; set; }

        /// <summary>
        /// هل يوجد صفحة تالية
        /// Whether there is a next page
        /// </summary>
        public bool HasNextPage { get; set; }

        /// <summary>
        /// فلاتر البحث المطبقة
        /// Applied search filters
        /// </summary>
        public SearchFiltersDto AppliedFilters { get; set; } = null!;

        /// <summary>
        /// وقت البحث بالميلي ثانية
        /// Search time in milliseconds
        /// </summary>
        public long SearchTimeMs { get; set; }

        /// <summary>
        /// إحصائيات البحث
        /// Search statistics
        /// </summary>
        public SearchStatisticsDto StatisticsDto { get; set; } = null!;
    }
}
