using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics
{
    /// <summary>
    /// استعلام للحصول على اتجاهات الحجوزات كسلسلة زمنية
    /// Query to retrieve booking trends as a time series
    /// </summary>
    public class GetBookingTrendsQuery : IRequest<IEnumerable<TimeSeriesDataDto>>
    {
        /// <summary>
        /// معرّف الكيان (اختياري)
        /// Property identifier (optional)
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// النطاق الزمني
        /// Date range for the trends
        /// </summary>
        public DateRangeDto Range { get; set; }

        public GetBookingTrendsQuery(Guid? propertyId, DateRangeDto range)
        {
            PropertyId = propertyId;
            Range = range;
        }
    }
} 