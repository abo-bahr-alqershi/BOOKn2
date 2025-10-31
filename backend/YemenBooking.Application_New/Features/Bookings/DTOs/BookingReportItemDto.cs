using System;

namespace YemenBooking.Application.Features.Bookings.DTOs {
    /// <summary>
    /// عنصر تقرير الحجوزات اليومية
    /// Daily booking report item
    /// </summary>
    public class BookingReportItemDto
    {
        /// <summary>
        /// التاريخ
        /// Date
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>
        /// عدد الحجوزات في ذلك اليوم
        /// BookingDto count for that day
        /// </summary>
        public int Count { get; set; }
    }
} 