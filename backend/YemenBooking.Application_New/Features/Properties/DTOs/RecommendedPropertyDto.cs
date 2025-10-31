using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Properties.DTOs;

/// <summary>
/// DTO العقار الموصى به
/// Recommended property DTO
/// </summary>
public class RecommendedPropertyDto
{
    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// اسم العقار
    /// Property name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// وصف العقار
    /// Property description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// العنوان
    /// Address
    /// </summary>
    public string Address { get; set; } = string.Empty;

    /// <summary>
    /// المدينة
    /// City
    /// </summary>
    public string City { get; set; } = string.Empty;

    /// <summary>
    /// تقييم النجوم
    /// Star rating
    /// </summary>
    public int StarRating { get; set; }

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
    /// أقل سعر متاح
    /// Minimum price
    /// </summary>
    public decimal MinPrice { get; set; }

    /// <summary>
    /// العملة
    /// Currency
    /// </summary>
    public string Currency { get; set; } = "USD";

    /// <summary>
    /// رابط الصورة الرئيسية
    /// Main image URL
    /// </summary>
    public string? MainImageUrl { get; set; }

    /// <summary>
    /// درجة التوصية (0-100)
    /// Recommendation score (0-100)
    /// </summary>
    public decimal RecommendationScore { get; set; }

    /// <summary>
    /// سبب التوصية
    /// Recommendation reason
    /// </summary>
    public string RecommendationReason { get; set; } = string.Empty;

    /// <summary>
    /// هل متاح للحجز
    /// Is available for booking
    /// </summary>
    public bool IsAvailable { get; set; } = true;

    /// <summary>
    /// عدد الوحدات المتاحة
    /// Available units count
    /// </summary>
    public int AvailableUnitsCount { get; set; }

    /// <summary>
    /// نوع العقار
    /// Property type
    /// </summary>
    public string PropertyType { get; set; } = string.Empty;

    /// <summary>
    /// هل مميز
    /// Is featured
    /// </summary>
    public bool IsFeatured { get; set; }

    /// <summary>
    /// قائمة وسائل الراحة الرئيسية
    /// Main amenities list
    /// </summary>
    public List<string> MainAmenities { get; set; } = new();

    /// <summary>
    /// نسبة التطابق مع تفضيلات المستخدم (0-100)
    /// Match percentage with user preferences (0-100)
    /// </summary>
    public decimal MatchPercentage { get; set; }

    /// <summary>
    /// العوامل المؤثرة في التوصية
    /// Recommendation factors
    /// </summary>
    public List<string> RecommendationFactors { get; set; } = new();

    /// <summary>
    /// هل سبق للمستخدم حجز هذا العقار
    /// Has user booked this property before
    /// </summary>
    public bool HasBookedBefore { get; set; }

    /// <summary>
    /// هل العقار في المفضلات
    /// Is property in favorites
    /// </summary>
    public bool IsInFavorites { get; set; }

    /// <summary>
    /// تاريخ آخر تحديث للتوصية
    /// Last recommendation update date
    /// </summary>
    public DateTime LastUpdated { get; set; }
}
