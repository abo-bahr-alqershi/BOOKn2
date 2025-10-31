using System;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// DTO لبيانات لوحة تحكم المسؤول
    /// DTO for admin dashboard data
    /// </summary>
    public class AdminDashboardDto
    {
        /// <summary>
        /// إجمالي عدد المستخدمين
        /// Total number of users
        /// </summary>
        public int TotalUsers { get; set; }

        /// <summary>
        /// إجمالي عدد الكيانات
        /// Total number of properties
        /// </summary>
        public int TotalProperties { get; set; }

        /// <summary>
        /// إجمالي عدد الحجوزات
        /// Total number of bookings
        /// </summary>
        public int TotalBookings { get; set; }

        /// <summary>
        /// إجمالي الإيرادات
        /// Total revenue
        /// </summary>
        public decimal TotalRevenue { get; set; }
    }
} 