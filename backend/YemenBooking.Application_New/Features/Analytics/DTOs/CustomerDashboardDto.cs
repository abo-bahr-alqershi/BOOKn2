using System;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// DTO لبيانات لوحة تحكم العميل
    /// DTO for customer dashboard data
    /// </summary>
    public class CustomerDashboardDto
    {
        /// <summary>
        /// معرف العميل
        /// Customer identifier
        /// </summary>
        public Guid CustomerId { get; set; }

        /// <summary>
        /// اسم العميل
        /// Customer name
        /// </summary>
        public string CustomerName { get; set; }

        /// <summary>
        /// عدد الحجوزات القادمة
        /// Number of upcoming bookings
        /// </summary>
        public int UpcomingBookings { get; set; }

        /// <summary>
        /// عدد الحجوزات السابقة
        /// Number of past bookings
        /// </summary>
        public int PastBookings { get; set; }

        /// <summary>
        /// إجمالي المبلغ المنفق
        /// Total amount spent
        /// </summary>
        public decimal TotalSpent { get; set; }
    }
} 