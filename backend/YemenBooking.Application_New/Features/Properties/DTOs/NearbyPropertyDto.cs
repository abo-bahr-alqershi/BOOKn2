namespace YemenBooking.Application.Features.Properties.DTOs;

/// <summary>
/// بيانات العقار القريب
/// Nearby property data
/// </summary>
public class NearbyPropertyDto
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
    /// العنوان
    /// Address
    /// </summary>
    public string Address { get; set; } = string.Empty;
    
    /// <summary>
    /// المسافة بالكيلومترات
    /// Distance in kilometers
    /// </summary>
    public double DistanceKm { get; set; }
    
    /// <summary>
    /// متوسط التقييم
    /// Average rating
    /// </summary>
    public decimal AverageRating { get; set; }
    
    /// <summary>
    /// أقل سعر متاح
    /// Minimum available price
    /// </summary>
    public decimal? MinPrice { get; set; }
    
    /// <summary>
    /// رابط الصورة الرئيسية
    /// Main image URL
    /// </summary>
    public string? MainImageUrl { get; set; }
}
