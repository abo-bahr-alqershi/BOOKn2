using System;

namespace YemenBooking.Application.Features.Properties.DTOs
{
    /// <summary>
    /// DTO لأداء الكيان
    /// DTO for property performance metrics
    /// </summary>
    public class PropertyPerformanceDto
    {
        /// <summary>
        /// نسبة الإشغال
        /// Occupancy rate
        /// </summary>
        public decimal OccupancyRate { get; set; }

        /// <summary>
        /// إجمالي الإيرادات
        /// Total revenue
        /// </summary>
        public decimal TotalRevenue { get; set; }

        /// <summary>
        /// إجمالي الحجوزات
        /// Total bookings
        /// </summary>
        public int TotalBookings { get; set; }

        /// <summary>
        /// الحجوزات المكتملة
        /// Completed bookings
        /// </summary>
        public int CompletedBookings { get; set; }

        /// <summary>
        /// الحجوزات الملغاة
        /// Cancelled bookings
        /// </summary>
        public int CancelledBookings { get; set; }

        /// <summary>
        /// معدل الإلغاء
        /// Cancellation rate
        /// </summary>
        public double CancellationRate { get; set; }

        /// <summary>
        /// متوسط مدة الإقامة (ليالي)
        /// Average stay (nights)
        /// </summary>
        public double AverageStay { get; set; }

        /// <summary>
        /// متوسط الإيراد لكل حجز
        /// Average revenue per booking
        /// </summary>
        public decimal AverageRevenuePerBooking { get; set; }

        /// <summary>
        /// متوسط التقييمات
        /// Average rating
        /// </summary>
        public double AverageRating { get; set; }

        /// <summary>
        /// إجمالي عدد التقييمات
        /// Total reviews count
        /// </summary>
        public int TotalReviews { get; set; }
    }
} 