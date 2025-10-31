using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.PropertyAnalytics
{
    /// <summary>
    /// استعلام للحصول على مؤشرات أداء الكيان
    /// Query to get property performance metrics
    /// </summary>
    public class GetPropertyPerformanceQuery : IRequest<ResultDto<PropertyPerformanceDto>>
    {
        /// <summary>
        /// معرف الكيان
        /// Property identifier
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// تاريخ البداية
        /// Start date
        /// </summary>
        public DateTime StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية
        /// End date
        /// </summary>
        public DateTime EndDate { get; set; }
    }
} 