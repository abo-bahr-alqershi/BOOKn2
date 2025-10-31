using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics
{
    /// <summary>
    /// استعلام للحصول على نسبة الإشغال لكيان ضمن نطاق زمني
    /// Query to retrieve occupancy rate for a property within a date range
    /// </summary>
    public class GetOccupancyRateQuery : IRequest<decimal>
    {
        /// <summary>
        /// معرف الكيان
        /// Property identifier
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// النطاق الزمني
        /// Date range for the calculation
        /// </summary>
        public DateRangeDto Range { get; set; }

        public GetOccupancyRateQuery(Guid propertyId, DateRangeDto range)
        {
            PropertyId = propertyId;
            Range = range;
        }
    }
} 