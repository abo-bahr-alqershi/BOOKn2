using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings.DTOs;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics
{
    /// <summary>
    /// استعلام للحصول على تقرير الحجوزات
    /// Query to get booking report
    /// </summary>
    public class GetBookingReportQuery : IRequest<ResultDto<BookingReportDto>>
    {
        /// <summary>
        /// تاريخ البداية
        /// </summary>
        public DateTime StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية
        /// </summary>
        public DateTime EndDate { get; set; }

        /// <summary>
        /// معرف الكيان (اختياري)
        /// </summary>
        public Guid? PropertyId { get; set; }
    }
} 