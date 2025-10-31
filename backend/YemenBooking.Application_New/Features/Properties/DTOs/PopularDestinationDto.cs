using System;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.DTOs;

/// <summary>
/// DTO الوجهة الشعبية
/// Popular destination DTO
/// </summary>
public class PopularDestinationDto
{
    /// <summary>
    /// معرف الوجهة
    /// Destination ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// اسم المدينة
    /// City name
    /// </summary>
    public string CityName { get; set; } = string.Empty;

    /// <summary>
    /// وصف المدينة
    /// City description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// رابط صورة المدينة
    /// City image URL
    /// </summary>
    public string? ImageUrl { get; set; }

    /// <summary>
    /// عدد العقارات
    /// PropertyDto count
    /// </summary>
    public int PropertiesCount { get; set; }

    /// <summary>
    /// متوسط السعر
    /// Average price
    /// </summary>
    public decimal AveragePrice { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = "USD";

    /// <summary>
    /// درجة الشعبية (0-100)
    /// Popularity score (0-100)
    /// </summary>
    public decimal PopularityScore { get; set; }

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
    /// عدد المراجعات
    /// Reviews count
    /// </summary>
    public int ReviewsCount { get; set; }

    /// <summary>
    /// هل مميزة
    /// Is featured
    /// </summary>
    public bool IsFeatured { get; set; }

    /// <summary>
    /// ترتيب الشعبية
    /// Popularity rank
    /// </summary>
    public int PopularityRank { get; set; }

    /// <summary>
    /// نسبة النمو في الحجوزات
    /// BookingDto growth rate
    /// </summary>
    public decimal BookingGrowthRate { get; set; }

    /// <summary>
    /// أفضل موسم للزيارة
    /// Best season to visit
    /// </summary>
    public string? BestSeason { get; set; }

    /// <summary>
    /// الأنشطة الشعبية
    /// Popular activities
    /// </summary>
    public string? PopularActivities { get; set; }
}
