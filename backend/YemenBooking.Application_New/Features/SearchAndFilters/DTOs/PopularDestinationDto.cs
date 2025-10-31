namespace YemenBooking.Application.Features.SearchAndFilters.DTOs;

/// <summary>
/// بيانات الوجهة الشعبية
/// Popular destination data
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
    /// اسم البلد
    /// Country name
    /// </summary>
    public string CountryName { get; set; } = string.Empty;

    /// <summary>
    /// رمز البلد
    /// Country code
    /// </summary>
    public string CountryCode { get; set; } = string.Empty;

    /// <summary>
    /// عدد الكيانات المتاحة
    /// Number of available properties
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
    public string Currency { get; set; } = string.Empty;

    /// <summary>
    /// التقييم المتوسط
    /// Average rating
    /// </summary>
    public double AverageRating { get; set; }

    /// <summary>
    /// عدد التقييمات
    /// Number of reviews
    /// </summary>
    public int ReviewsCount { get; set; }

    /// <summary>
    /// وصف قصير
    /// Short description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// رابط الصورة الرئيسية
    /// Main image URL
    /// </summary>
    public string ImageUrl { get; set; } = string.Empty;

    /// <summary>
    /// صور إضافية
    /// Additional images
    /// </summary>
    public List<string> Images { get; set; } = new List<string>();

    /// <summary>
    /// الكلمات المفتاحية
    /// Tags
    /// </summary>
    public List<string> Tags { get; set; } = new List<string>();

    /// <summary>
    /// الإحداثيات الجغرافية
    /// Geographic coordinates
    /// </summary>
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    /// <summary>
    /// عدد الحجوزات الأخيرة
    /// Recent bookings count
    /// </summary>
    public int RecentBookingsCount { get; set; }

    /// <summary>
    /// نسبة الإشغال
    /// Occupancy rate
    /// </summary>
    public double OccupancyRate { get; set; }

    /// <summary>
    /// هل هي وجهة مميزة
    /// Is featured destination
    /// </summary>
    public bool IsFeatured { get; set; }

    /// <summary>
    /// ترتيب الشعبية
    /// Popularity rank
    /// </summary>
    public int PopularityRank { get; set; }

    /// <summary>
    /// أفضل وقت للزيارة
    /// Best time to visit
    /// </summary>
    public string BestTimeToVisit { get; set; } = string.Empty;

    /// <summary>
    /// المناخ
    /// Climate
    /// </summary>
    public string Climate { get; set; } = string.Empty;
}
