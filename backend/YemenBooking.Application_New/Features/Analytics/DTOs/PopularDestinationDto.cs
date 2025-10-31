using System;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// DTO للوجهة الشعبية
    /// Popular destination DTO
    /// </summary>
    public class PopularDestinationDto
    {
        /// <summary>
        /// معرف المدينة
        /// City ID
        /// </summary>
        public Guid CityId { get; set; }

        /// <summary>
        /// اسم المدينة
        /// City name
        /// </summary>
        public string CityName { get; set; } = string.Empty;

        /// <summary>
        /// اسم المحافظة
        /// Province name
        /// </summary>
        public string ProvinceName { get; set; } = string.Empty;

        /// <summary>
        /// عدد العقارات المتاحة
        /// Available properties count
        /// </summary>
        public int PropertiesCount { get; set; }

        /// <summary>
        /// عدد الحجوزات
        /// Bookings count
        /// </summary>
        public int BookingsCount { get; set; }

        /// <summary>
        /// متوسط التقييم
        /// Average rating
        /// </summary>
        public decimal AverageRating { get; set; }

        /// <summary>
        /// متوسط السعر
        /// Average price
        /// </summary>
        public decimal AveragePrice { get; set; }

        /// <summary>
        /// متوسط السعر لليلة الواحدة
        /// Average price per night
        /// </summary>
        public decimal AveragePricePerNight { get; set; }

        /// <summary>
        /// العملة
        /// Currency
        /// </summary>
        public string Currency { get; set; } = "YER";

        /// <summary>
        /// صورة الوجهة
        /// Destination image
        /// </summary>
        public string ImageUrl { get; set; } = string.Empty;

        /// <summary>
        /// وصف الوجهة
        /// Destination description
        /// </summary>
        public string Description { get; set; } = string.Empty;

        /// <summary>
        /// خط العرض
        /// Latitude
        /// </summary>
        public double Latitude { get; set; }

        /// <summary>
        /// خط الطول
        /// Longitude
        /// </summary>
        public double Longitude { get; set; }

        /// <summary>
        /// معدل الشعبية (من 1 إلى 100)
        /// Popularity score (1 to 100)
        /// </summary>
        public int PopularityScore { get; set; }

        /// <summary>
        /// هل هي وجهة مميزة
        /// Is featured destination
        /// </summary>
        public bool IsFeatured { get; set; }

        /// <summary>
        /// الموسم الأفضل للزيارة
        /// Best season to visit
        /// </summary>
        public string BestSeason { get; set; } = string.Empty;

        /// <summary>
        /// المعالم الشهيرة
        /// Famous landmarks
        /// </summary>
        public string[] FamousLandmarks { get; set; } = Array.Empty<string>();

        /// <summary>
        /// الأنشطة المتاحة
        /// Available activities
        /// </summary>
        public string[] AvailableActivities { get; set; } = Array.Empty<string>();

        /// <summary>
        /// نسبة الإشغال
        /// Occupancy rate
        /// </summary>
        public decimal OccupancyRate { get; set; }

        /// <summary>
        /// عدد الزوار الشهري
        /// Monthly visitors count
        /// </summary>
        public int MonthlyVisitors { get; set; }
    }
}
