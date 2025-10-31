namespace YemenBooking.Application.Common.Models;

/// <summary>
/// DTO للعناوين الجغرافية
/// DTO for geographical addresses
/// </summary>
public class AddressDto
{
    /// <summary>
    /// الشارع أو العنوان التفصيلي
    /// Street or detailed address
    /// </summary>
    public string Street { get; set; } = null!;
    
    /// <summary>
    /// المدينة
    /// City
    /// </summary>
    public string City { get; set; } = null!;
    
    /// <summary>
    /// المحافظة أو الولاية
    /// State or Province
    /// </summary>
    public string? State { get; set; }
    
    /// <summary>
    /// الدولة
    /// Country
    /// </summary>
    public string Country { get; set; } = null!;
    
    /// <summary>
    /// الرمز البريدي
    /// Postal code
    /// </summary>
    public string? PostalCode { get; set; }
    
    /// <summary>
    /// خط العرض
    /// Latitude
    /// </summary>
    public decimal? Latitude { get; set; }
    
    /// <summary>
    /// خط الطول
    /// Longitude
    /// </summary>
    public decimal? Longitude { get; set; }
    
    /// <summary>
    /// العنوان الكامل
    /// Full address
    /// </summary>
    public string FullAddress
    {
        get
        {
            var parts = new List<string> { Street, City };
            
            if (!string.IsNullOrWhiteSpace(State))
                parts.Add(State);
            
            parts.Add(Country);
            
            if (!string.IsNullOrWhiteSpace(PostalCode))
                parts.Add(PostalCode);
            
            return string.Join(", ", parts);
        }
    }
    
    /// <summary>
    /// هل توجد إحداثيات GPS
    /// Has GPS coordinates
    /// </summary>
    public bool HasCoordinates => Latitude.HasValue && Longitude.HasValue;
}