using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.FilterAnalytics
{
    /// <summary>
    /// استعلام للحصول على احصائيات فلاتر البحث الديناميكية للوحدات
    /// Query to get dynamic filter analytics for unit searches
    /// </summary>
    public class GetUnitDynamicFilterAnalyticsQuery : IRequest<ResultDto<List<FieldFilterAnalyticsDto>>>
    {
        /// <summary>
        /// تاريخ بدء الفترة (اختياري)
        /// Start date for analytics (optional)
        /// </summary>
        public DateTime? From { get; set; }

        /// <summary>
        /// تاريخ نهاية الفترة (اختياري)
        /// End date for analytics (optional)
        /// </summary>
        public DateTime? To { get; set; }
    }
} 