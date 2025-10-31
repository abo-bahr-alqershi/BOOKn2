using System.Collections.Generic;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// إحصائيات البحث
    /// Search statistics DTO
    /// </summary>
    public class SearchStatisticsDto
    {
        /// <summary>
        /// عدد العقارات لكل نوع
        /// PropertyDto count by type
        /// </summary>
        public Dictionary<string, int> PropertiesByType { get; set; } = new();

        /// <summary>
        /// عدد العقارات لكل مدينة
        /// PropertyDto count by city
        /// </summary>
        public Dictionary<string, int> PropertiesByCity { get; set; } = new();

        /// <summary>
        /// نطاق الأسعار
        /// Price range
        /// </summary>
        public PriceRangeDto PriceRange { get; set; } = null!;

        /// <summary>
        /// متوسط التقييم
        /// Average rating
        /// </summary>
        public decimal AverageRating { get; set; }

        /// <summary>
        /// عدد العقارات المتاحة
        /// Available properties count
        /// </summary>
        public int AvailableCount { get; set; }

        /// <summary>
        /// إجمالي عدد العقارات
        /// Total properties count
        /// </summary>
        public int TotalCount { get; set; }
    }

    /// <summary>
    /// نطاق الأسعار
    /// Price range DTO
    /// </summary>
    public class PriceRangeDto
    {
        /// <summary>
        /// الحد الأدنى
        /// Minimum price
        /// </summary>
        public decimal Min { get; set; }

        /// <summary>
        /// الحد الأقصى
        /// Maximum price
        /// </summary>
        public decimal Max { get; set; }

        /// <summary>
        /// العملة
        /// Currency
        /// </summary>
        public string Currency { get; set; } = "YER";
    }
}
