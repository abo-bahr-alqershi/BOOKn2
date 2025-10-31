using System;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// DTO لبيانات لوحة تحكم المالك
    /// DTO for owner dashboard data
    /// </summary>
    public class OwnerDashboardDto
    {
        /// <summary>
        /// معرف المالك
        /// Owner identifier
        /// </summary>
        public Guid OwnerId { get; set; }

        /// <summary>
        /// اسم المالك
        /// Owner name
        /// </summary>
        public string OwnerName { get; set; }

        /// <summary>
        /// إجمالي عدد الكيانات الخاصة بالمالك
        /// Total number of properties for the owner
        /// </summary>
        public int PropertyCount { get; set; }

        /// <summary>
        /// إجمالي عدد الحجوزات للكيانات الخاصة بالمالك
        /// Total number of bookings for the owner's properties
        /// </summary>
        public int BookingCount { get; set; }

        /// <summary>
        /// إجمالي الإيرادات للكيانات الخاصة بالمالك
        /// Total revenue for the owner's properties
        /// </summary>
        public decimal TotalRevenue { get; set; }
    }
} 