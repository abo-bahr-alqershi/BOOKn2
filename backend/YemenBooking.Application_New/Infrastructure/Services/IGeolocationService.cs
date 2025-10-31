namespace YemenBooking.Application.Infrastructure.Services;

/// <summary>
/// واجهة خدمة تحديد الموقع الجغرافي والمنطقة الزمنية
/// Geolocation and timezone service interface
/// </summary>
public interface IGeolocationService
{
    /// <summary>
    /// الحصول على معلومات المنطقة الزمنية من الـ Headers أو IP
    /// Get timezone info from headers or IP fallback
    /// </summary>
    Task<GeolocationInfo> GetLocationInfoAsync(string ipAddress = null);

    /// <summary>
    /// الحصول على المنطقة الزمنية من HttpContext Headers
    /// Get timezone from HttpContext headers
    /// </summary>
    string GetTimezoneFromHeaders();

    /// <summary>
    /// الحصول على offset المنطقة الزمنية من Headers
    /// Get timezone offset from headers
    /// </summary>
    int? GetTimezoneOffsetFromHeaders();

    /// <summary>
    /// الحصول على عنوان IP الخاص بالعميل من HttpContext
    /// </summary>
    string GetClientIpAddress();

    /// <summary>
    /// تحويل التوقيت من UTC إلى توقيت المستخدم
    /// Convert from UTC to user timezone
    /// </summary>
    DateTime ConvertFromUtc(DateTime utcDateTime, string timezoneId = null);

    /// <summary>
    /// تحويل التوقيت من توقيت المستخدم إلى UTC
    /// Convert from user timezone to UTC
    /// </summary>
    DateTime ConvertToUtc(DateTime localDateTime, string timezoneId = null);

    /// <summary>
    /// الحصول على الإحداثيات من العنوان
    /// Get coordinates from address
    /// </summary>
    Task<(double Latitude, double Longitude)> GetCoordinatesAsync(
        string address, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على العنوان من الإحداثيات
    /// Get address from coordinates
    /// </summary>
    Task<string> GetAddressAsync(
        double latitude, 
        double longitude, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// حساب المسافة بين نقطتين
    /// Calculate distance between two points
    /// </summary>
    Task<double> CalculateDistanceAsync(
        double lat1, 
        double lon1, 
        double lat2, 
        double lon2, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// العثور على الأماكن القريبة
    /// Find nearby places
    /// </summary>
    Task<IEnumerable<object>> FindNearbyPlacesAsync(
        double latitude, 
        double longitude, 
        double radiusKm, 
        string placeType = "all", 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من صحة الإحداثيات
    /// Validate coordinates
    /// </summary>
    Task<bool> ValidateCoordinatesAsync(
        double latitude, 
        double longitude, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على معلومات المنطقة الزمنية من الإحداثيات
    /// Get timezone information from coordinates
    /// </summary>
    Task<string> GetTimezoneAsync(
        double latitude, 
        double longitude, 
        CancellationToken cancellationToken = default);
}

public class GeolocationInfo
{
    public string Country { get; set; }
    public string CountryCode { get; set; }
    public string City { get; set; }
    public string TimeZoneId { get; set; }
    public int? TimeZoneOffset { get; set; } // بالدقائق
    public double? Latitude { get; set; }
    public double? Longitude { get; set; }
    public string Region { get; set; }
    public string Source { get; set; } // "Headers" أو "IP" أو "Default"
}