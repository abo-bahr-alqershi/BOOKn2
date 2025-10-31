namespace YemenBooking.Infrastructure.Settings
{
    /// <summary>
    /// إعدادات خدمة تحديد الموقع الجغرافي
    /// Geolocation service settings
    /// </summary>
    public class GeolocationSettings
    {
        /// <summary>
        /// عنوان API للترميز الجغرافي
        /// Geocoding API base URL
        /// </summary>
        public string GeocodingApiUrl { get; set; } = "https://nominatim.openstreetmap.org";

        /// <summary>
        /// عنوان API لخدمات المنطقة الزمنية
        /// Timezone API base URL
        /// </summary>
        public string TimezoneApiUrl { get; set; } = "http://api.timezonedb.com/v2.1/get-time-zone";

        /// <summary>
        /// مفتاح API (اختياري)
        /// API key (optional)
        /// </summary>
        public string ApiKey { get; set; } = "";
    }
} 