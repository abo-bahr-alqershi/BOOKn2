using System.Collections.Generic;
using YemenBooking.Application.Features.Reports.DTOs;

namespace YemenBooking.Application.Features.Bookings.DTOs {
    /// <summary>
    /// تقرير الحجز
    /// BookingDto report DTO
    /// </summary>
    public class BookingReportDto
    {
        /// <summary>
        /// عناصر تقرير الحجوزات اليومية
        /// Daily booking report items
        /// </summary>
        public List<BookingReportItemDto> Items { get; set; } = new List<BookingReportItemDto>();
    }
} 