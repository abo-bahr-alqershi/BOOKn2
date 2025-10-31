using System;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// DTO لملخص حجوزات المستخدم
    /// User booking summary DTO
    /// </summary>
    public class UserBookingSummaryDto
    {
        /// <summary>
        /// معرف المستخدم
        /// User ID
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// الفترة الزمنية
        /// Time period
        /// </summary>
        public string Period { get; set; } = string.Empty;

        /// <summary>
        /// العدد الإجمالي للحجوزات
        /// Total bookings count
        /// </summary>
        public int TotalBookings { get; set; }

        /// <summary>
        /// الحجوزات المؤكدة
        /// Confirmed bookings
        /// </summary>
        public int ConfirmedBookings { get; set; }

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
        /// الحجوزات المعلقة
        /// Pending bookings
        /// </summary>
        public int PendingBookings { get; set; }

        /// <summary>
        /// إجمالي المبلغ المنفق
        /// Total amount spent
        /// </summary>
        public decimal TotalAmountSpent { get; set; }

        /// <summary>
        /// متوسط قيمة الحجز
        /// Average booking value
        /// </summary>
        public decimal AverageBookingValue { get; set; }

        /// <summary>
        /// إجمالي الليالي المحجوزة
        /// Total nights booked
        /// </summary>
        public int TotalNightsBooked { get; set; }

        /// <summary>
        /// العقارات المفضلة (الأكثر حجزاً)
        /// Favorite properties (most booked)
        /// </summary>
        public List<AnalyticsFavoritePropertyDto> FavoriteProperties { get; set; } = new();

        /// <summary>
        /// الوجهات المفضلة
        /// Favorite destinations
        /// </summary>
        public List<FavoriteDestinationDto> FavoriteDestinations { get; set; } = new();

        /// <summary>
        /// إحصائيات شهرية
        /// Monthly statistics
        /// </summary>
        public List<MonthlyBookingStatsDto> MonthlyStats { get; set; } = new();

        /// <summary>
        /// معدل الإلغاء
        /// Cancellation rate
        /// </summary>
        public decimal CancellationRate { get; set; }

        /// <summary>
        /// متوسط التقييم المعطى
        /// Average rating given
        /// </summary>
        public decimal AverageRatingGiven { get; set; }

        /// <summary>
        /// عدد المراجعات المكتوبة
        /// Number of reviews written
        /// </summary>
        public int ReviewsWritten { get; set; }
    }

    /// <summary>
    /// DTO للعقار المفضل
    /// Favorite property DTO
    /// </summary>
    public class AnalyticsFavoritePropertyDto
    {
        /// <summary>
        /// معرف العقار
        /// Property ID
        /// </summary>
        public Guid PropertyId { get; set; }

        /// <summary>
        /// اسم العقار
        /// Property name
        /// </summary>
        public string PropertyName { get; set; } = string.Empty;

        /// <summary>
        /// عدد مرات الحجز
        /// BookingDto count
        /// </summary>
        public int BookingCount { get; set; }

        /// <summary>
        /// إجمالي المبلغ المنفق
        /// Total amount spent
        /// </summary>
        public decimal TotalSpent { get; set; }
    }

    /// <summary>
    /// DTO للوجهة المفضلة
    /// Favorite destination DTO
    /// </summary>
    public class FavoriteDestinationDto
    {
        /// <summary>
        /// اسم المدينة
        /// City name
        /// </summary>
        public string CityName { get; set; } = string.Empty;

        /// <summary>
        /// عدد مرات الزيارة
        /// Visit count
        /// </summary>
        public int VisitCount { get; set; }

        /// <summary>
        /// إجمالي الليالي
        /// Total nights
        /// </summary>
        public int TotalNights { get; set; }
    }

    /// <summary>
    /// DTO لإحصائيات الحجز الشهرية
    /// Monthly booking statistics DTO
    /// </summary>
    public class MonthlyBookingStatsDto
    {
        /// <summary>
        /// الشهر والسنة
        /// Month and year
        /// </summary>
        public string MonthYear { get; set; } = string.Empty;

        /// <summary>
        /// عدد الحجوزات
        /// Bookings count
        /// </summary>
        public int BookingsCount { get; set; }

        /// <summary>
        /// إجمالي المبلغ
        /// Total amount
        /// </summary>
        public decimal TotalAmount { get; set; }

        /// <summary>
        /// عدد الليالي
        /// Nights count
        /// </summary>
        public int NightsCount { get; set; }
    }
}
