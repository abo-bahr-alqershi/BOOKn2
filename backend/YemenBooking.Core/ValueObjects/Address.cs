namespace YemenBooking.Core.ValueObjects;

/// <summary>
/// كائن قيمة للتعامل مع العناوين الجغرافية
/// Value object for handling geographical addresses
/// </summary>
public record Address
{
    /// <summary>
    /// الشارع أو العنوان التفصيلي
    /// Street or detailed address
    /// </summary>
    public string Street { get; init; }
    
    /// <summary>
    /// المدينة
    /// City
    /// </summary>
    public string City { get; init; }
    
    /// <summary>
    /// المحافظة أو الولاية
    /// State or Province
    /// </summary>
    public string? State { get; init; }
    
    /// <summary>
    /// الدولة
    /// Country
    /// </summary>
    public string Country { get; init; }
    
    /// <summary>
    /// الرمز البريدي
    /// Postal code
    /// </summary>
    public string? PostalCode { get; init; }
    
    /// <summary>
    /// خط العرض
    /// Latitude
    /// </summary>
    public decimal? Latitude { get; init; }
    
    /// <summary>
    /// خط الطول
    /// Longitude
    /// </summary>
    public decimal? Longitude { get; init; }
    
    /// <summary>
    /// منشئ كائن العنوان
    /// Address constructor
    /// </summary>
    public Address(string street, string city, string country, string? state = null, 
                   string? postalCode = null, decimal? latitude = null, decimal? longitude = null)
    {
        if (string.IsNullOrWhiteSpace(street))
            throw new ArgumentException("الشارع مطلوب", nameof(street));
        
        if (string.IsNullOrWhiteSpace(city))
            throw new ArgumentException("المدينة مطلوبة", nameof(city));
        
        if (string.IsNullOrWhiteSpace(country))
            throw new ArgumentException("الدولة مطلوبة", nameof(country));
        
        Street = street.Trim();
        City = city.Trim();
        State = state?.Trim();
        Country = country.Trim();
        PostalCode = postalCode?.Trim();
        Latitude = latitude;
        Longitude = longitude;
    }
    
    /// <summary>
    /// التحقق من وجود إحداثيات GPS
    /// Check if GPS coordinates exist
    /// </summary>
    public bool HasCoordinates => Latitude.HasValue && Longitude.HasValue;
    
    /// <summary>
    /// الحصول على العنوان كنص مكتمل
    /// Get full address as text
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
    /// تنسيق العنوان للعرض
    /// Format address for display
    /// </summary>
    public override string ToString() => FullAddress;
}