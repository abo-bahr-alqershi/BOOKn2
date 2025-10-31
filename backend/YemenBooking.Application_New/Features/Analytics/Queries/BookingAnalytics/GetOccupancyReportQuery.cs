using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics
{
    /// <summary>
    /// استعلام للحصول على تقرير الإشغال
    /// Query to get occupancy report
    /// </summary>
    public class GetOccupancyReportQuery : IRequest<ResultDto<OccupancyReportDto>>
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