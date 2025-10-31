using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using System.Net.Http;
using System.Text.Json;
using System.Globalization;
using Microsoft.Extensions.Options;
using YemenBooking.Infrastructure.Settings;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Configuration;
using Newtonsoft.Json;
using TimeZoneConverter;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة تحديد الموقع الجغرافي والمنطقة الزمنية
    /// Geolocation and timezone service implementation
    /// </summary>
    public class GeolocationService : IGeolocationService
    {
        private readonly ILogger<GeolocationService> _logger;
        private readonly HttpClient _httpClient;
        private readonly GeolocationSettings _settings;
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IHttpClientFactory _httpClientFactory;
        private readonly IMemoryCache _cache;
        private readonly IConfiguration _configuration;

        public GeolocationService(
            IHttpContextAccessor httpContextAccessor,
            IHttpClientFactory httpClientFactory,
            IMemoryCache cache,
            IConfiguration configuration,
            ILogger<GeolocationService> logger,
            HttpClient httpClient,
            IOptions<GeolocationSettings> options)
        {
            _httpContextAccessor = httpContextAccessor;
            _httpClientFactory = httpClientFactory;
            _cache = cache;
            _configuration = configuration;
            _logger = logger;
            _httpClient = httpClient;
            _settings = options.Value;
        }

        /// <summary>
        /// الحصول على المنطقة الزمنية من Headers
        /// Get timezone from request headers
        /// </summary>
        public string GetTimezoneFromHeaders()
        {
            var context = _httpContextAccessor.HttpContext;
            if (context == null) return null;

            // محاولة الحصول على timezone من headers مختلفة
            var timezone = context.Request.Headers["X-TimeZone"].FirstOrDefault() ??
                          context.Request.Headers["X-User-TimeZone"].FirstOrDefault() ??
                          context.Request.Headers["TimeZone"].FirstOrDefault();

            if (!string.IsNullOrEmpty(timezone))
            {
                _logger.LogDebug("Timezone from headers: {Timezone}", timezone);
                return timezone;
            }

            // محاولة استنتاج timezone من offset
            var offset = GetTimezoneOffsetFromHeaders();
            if (offset.HasValue)
            {
                // محاولة إيجاد timezone مطابق للـ offset
                var hours = offset.Value / 60;
                var minutes = Math.Abs(offset.Value % 60);
                var offsetString = $"{(offset.Value >= 0 ? "+" : "-")}{Math.Abs(hours):D2}:{minutes:D2}";
                
                _logger.LogDebug("Timezone offset from headers: {Offset} minutes", offset.Value);
                return $"UTC{offsetString}";
            }

            return null;
        }

        /// <summary>
        /// الحصول على offset المنطقة الزمنية من Headers بالدقائق
        /// Get timezone offset from headers in minutes
        /// </summary>
        public int? GetTimezoneOffsetFromHeaders()
        {
            var context = _httpContextAccessor.HttpContext;
            if (context == null) return null;

            var offsetHeader = context.Request.Headers["X-TimeZone-Offset"].FirstOrDefault() ??
                              context.Request.Headers["X-User-TimeZone-Offset"].FirstOrDefault();

            if (!string.IsNullOrEmpty(offsetHeader) && int.TryParse(offsetHeader, out var offset))
            {
                return offset;
            }

            return null;
        }

        /// <summary>
        /// الحصول على عنوان IP الخاص بالعميل من HttpContext
        /// Get client IP address from HttpContext
        /// </summary>
        public string GetClientIpAddress()
        {
            var httpContext = _httpContextAccessor.HttpContext;
            if (httpContext == null) return string.Empty;

            // تحقق من headers مختلفة للحصول على IP الحقيقي
            string ip = httpContext.Request.Headers["CF-Connecting-IP"].FirstOrDefault() ?? // Cloudflare
                       httpContext.Request.Headers["X-Forwarded-For"].FirstOrDefault()?.Split(',')[0].Trim() ??
                       httpContext.Request.Headers["X-Real-IP"].FirstOrDefault() ??
                       httpContext.Connection.RemoteIpAddress?.ToString() ??
                       "127.0.0.1";

            // إزالة IPv6 prefix إذا وجد
            if (ip.Contains("::ffff:"))
                ip = ip.Replace("::ffff:", "");

            return ip;
        }

        /// <summary>
        /// الحصول على معلومات الموقع من Headers أو IP
        /// Get location info from headers or IP
        /// </summary>
        public async Task<GeolocationInfo> GetLocationInfoAsync(string ipAddress = null)
        {
            // 1. محاولة الحصول من Headers أولاً
            var timezoneFromHeaders = GetTimezoneFromHeaders();
            var offsetFromHeaders = GetTimezoneOffsetFromHeaders();

            if (!string.IsNullOrEmpty(timezoneFromHeaders))
            {
                _logger.LogInformation("Using timezone from headers: {Timezone}", timezoneFromHeaders);
                
                // إنشاء GeolocationInfo من headers
                var headerInfo = new GeolocationInfo
                {
                    TimeZoneId = timezoneFromHeaders,
                    TimeZoneOffset = offsetFromHeaders,
                    Source = "Headers"
                };

                // محاولة استنتاج الدولة من timezone
                EnrichLocationFromTimezone(headerInfo);
                
                return headerInfo;
            }

            // 2. إذا لم توجد headers، استخدم IP
            if (string.IsNullOrEmpty(ipAddress))
            {
                ipAddress = GetClientIpAddress();
            }

            // التحقق من الـ cache
            var cacheKey = $"geo_{ipAddress}";
            if (_cache.TryGetValue<GeolocationInfo>(cacheKey, out var cachedInfo))
            {
                _logger.LogDebug("Returning cached location for IP: {IP}", ipAddress);
                return cachedInfo;
            }

            try
            {
                // استخدام خدمات IP للحصول على الموقع
                var info = await GetFromIpApiAsync(ipAddress) ??
                          await GetFromIpGeolocationAsync(ipAddress) ??
                          GetDefaultLocationInfo();

                info.Source = info.Source ?? "IP";

                // حفظ في الـ cache لمدة 24 ساعة
                _cache.Set(cacheKey, info, TimeSpan.FromHours(24));

                return info;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting geolocation for IP: {IpAddress}", ipAddress);
                return GetDefaultLocationInfo();
            }
        }

        /// <summary>
        /// تحويل التوقيت من UTC إلى توقيت المستخدم
        /// Convert from UTC to user timezone
        /// </summary>
        public DateTime ConvertFromUtc(DateTime utcDateTime, string timezoneId = null)
        {
            if (utcDateTime.Kind != DateTimeKind.Utc)
            {
                utcDateTime = DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc);
            }

            // استخدام timezone المحدد أو محاولة الحصول عليه من headers
            timezoneId = timezoneId ?? GetTimezoneFromHeaders();

            if (string.IsNullOrEmpty(timezoneId))
            {
                // محاولة استخدام offset
                var offset = GetTimezoneOffsetFromHeaders();
                if (offset.HasValue)
                {
                    return utcDateTime.AddMinutes(-offset.Value); // عكس الـ offset
                }

                // Default to Yemen time
                timezoneId = "Asia/Aden";
            }

            try
            {
                // التعامل مع UTC offset format
                if (timezoneId.StartsWith("UTC"))
                {
                    var offsetPart = timezoneId.Substring(3);
                    if (TimeSpan.TryParse(offsetPart, out var timeOffset))
                    {
                        return utcDateTime.Add(timeOffset);
                    }
                }

                // استخدام TimeZoneConverter للتعامل مع IANA و Windows time zones
                var timeZone = TZConvert.GetTimeZoneInfo(timezoneId);
                return TimeZoneInfo.ConvertTimeFromUtc(utcDateTime, timeZone);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error converting from UTC. TimeZone: {TimeZone}", timezoneId);
                // Fallback to Yemen time
                return utcDateTime.AddHours(3);
            }
        }

        /// <summary>
        /// تحويل التوقيت من توقيت المستخدم إلى UTC
        /// Convert from user timezone to UTC
        /// </summary>
        public DateTime ConvertToUtc(DateTime localDateTime, string timezoneId = null)
        {
            if (localDateTime.Kind == DateTimeKind.Utc)
                return localDateTime;

            // استخدام timezone المحدد أو محاولة الحصول عليه من headers
            timezoneId = timezoneId ?? GetTimezoneFromHeaders();

            if (string.IsNullOrEmpty(timezoneId))
            {
                // محاولة استخدام offset
                var offset = GetTimezoneOffsetFromHeaders();
                if (offset.HasValue)
                {
                    return localDateTime.AddMinutes(offset.Value);
                }

                // Default to Yemen time
                timezoneId = "Asia/Aden";
            }

            try
            {
                localDateTime = DateTime.SpecifyKind(localDateTime, DateTimeKind.Unspecified);

                // التعامل مع UTC offset format
                if (timezoneId.StartsWith("UTC"))
                {
                    var offsetPart = timezoneId.Substring(3);
                    if (TimeSpan.TryParse(offsetPart, out var timeOffset))
                    {
                        return localDateTime.Subtract(timeOffset);
                    }
                }

                var timeZone = TZConvert.GetTimeZoneInfo(timezoneId);
                return TimeZoneInfo.ConvertTimeToUtc(localDateTime, timeZone);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error converting to UTC. TimeZone: {TimeZone}", timezoneId);
                // Fallback
                return localDateTime.AddHours(-3);
            }
        }

        /// <summary>
        /// إثراء معلومات الموقع من المنطقة الزمنية
        /// Enrich location info from timezone
        /// </summary>
        private void EnrichLocationFromTimezone(GeolocationInfo info)
        {
            if (string.IsNullOrEmpty(info.TimeZoneId))
                return;

            // قائمة بسيطة لربط timezones بالدول
            var timezoneCountryMap = new Dictionary<string, (string Country, string CountryCode, string City)>
            {
                ["Asia/Aden"] = ("Yemen", "YE", "Sana'a"),
                ["Asia/Riyadh"] = ("Saudi Arabia", "SA", "Riyadh"),
                ["Asia/Dubai"] = ("United Arab Emirates", "AE", "Dubai"),
                ["Asia/Kuwait"] = ("Kuwait", "KW", "Kuwait City"),
                ["Asia/Muscat"] = ("Oman", "OM", "Muscat"),
                ["Asia/Qatar"] = ("Qatar", "QA", "Doha"),
                ["Asia/Bahrain"] = ("Bahrain", "BH", "Manama"),
                ["Africa/Cairo"] = ("Egypt", "EG", "Cairo"),
                ["Asia/Amman"] = ("Jordan", "JO", "Amman"),
                ["Asia/Damascus"] = ("Syria", "SY", "Damascus"),
                ["Asia/Baghdad"] = ("Iraq", "IQ", "Baghdad"),
                ["Asia/Beirut"] = ("Lebanon", "LB", "Beirut"),
                // إضافة المزيد حسب الحاجة
            };

            if (timezoneCountryMap.TryGetValue(info.TimeZoneId, out var locationData))
            {
                info.Country = info.Country ?? locationData.Country;
                info.CountryCode = info.CountryCode ?? locationData.CountryCode;
                info.City = info.City ?? locationData.City;
            }
        }

        /// <summary>
        /// الحصول على معلومات الموقع من ip-api.com
        /// Get location info from ip-api.com
        /// </summary>
        private async Task<GeolocationInfo> GetFromIpApiAsync(string ipAddress)
        {
            try
            {
                var client = _httpClientFactory.CreateClient();
                var response = await client.GetAsync($"http://ip-api.com/json/{ipAddress}");

                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    dynamic data = JsonConvert.DeserializeObject(json);

                    if (data?.status == "success")
                    {
                        return new GeolocationInfo
                        {
                            Country = data.country,
                            CountryCode = data.countryCode,
                            City = data.city,
                            TimeZoneId = data.timezone,
                            Latitude = data.lat,
                            Longitude = data.lon,
                            Region = data.regionName,
                            Source = "IP-API"
                        };
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to get location from ip-api");
            }

            return null;
        }

        /// <summary>
        /// الحصول على معلومات الموقع من ipgeolocation.io
        /// Get location info from ipgeolocation.io
        /// </summary>
        private async Task<GeolocationInfo> GetFromIpGeolocationAsync(string ipAddress)
        {
            try
            {
                var apiKey = _configuration["Geolocation:IpGeolocationApiKey"];
                if (string.IsNullOrEmpty(apiKey))
                    return null;

                var client = _httpClientFactory.CreateClient();
                var response = await client.GetAsync(
                    $"https://api.ipgeolocation.io/ipgeo?apiKey={apiKey}&ip={ipAddress}");

                if (response.IsSuccessStatusCode)
                {
                    var json = await response.Content.ReadAsStringAsync();
                    dynamic data = JsonConvert.DeserializeObject(json);

                    return new GeolocationInfo
                    {
                        Country = data.country_name,
                        CountryCode = data.country_code2,
                        City = data.city,
                        TimeZoneId = data.time_zone?.name,
                        TimeZoneOffset = (int?)data.time_zone?.offset * 60, // تحويل من ساعات إلى دقائق
                        Latitude = double.Parse(data.latitude?.ToString() ?? "0"),
                        Longitude = double.Parse(data.longitude?.ToString() ?? "0"),
                        Region = data.state_prov,
                        Source = "IPGeolocation"
                    };
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Failed to get location from ipgeolocation");
            }

            return null;
        }

        /// <summary>
        /// الحصول على معلومات الموقع الافتراضية (اليمن/صنعاء)
        /// Get default location info (Yemen/Sana'a)
        /// </summary>
        private GeolocationInfo GetDefaultLocationInfo()
        {
            return new GeolocationInfo
            {
                Country = "Yemen",
                CountryCode = "YE",
                City = "Sana'a",
                TimeZoneId = "Asia/Aden",
                TimeZoneOffset = 180, // +3 hours in minutes
                Latitude = 15.3694,
                Longitude = 44.1910,
                Region = "Sana'a",
                Source = "Default"
            };
        }

        // باقي الدوال تبقى كما هي...
        
        /// <summary>
        /// الحصول على الإحداثيات من العنوان
        /// Get coordinates from address
        /// </summary>
        public async Task<(double Latitude, double Longitude)> GetCoordinatesAsync(string address, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على الإحداثيات من العنوان: {Address}", address);
            try
            {
                var url = $"{_settings.GeocodingApiUrl}/search?format=json&q={Uri.EscapeDataString(address)}&limit=1";
                var response = await _httpClient.GetStringAsync(url);
                var elements = System.Text.Json.JsonSerializer.Deserialize<JsonElement[]>(response);
                if (elements != null && elements.Length > 0)
                {
                    var first = elements[0];
                    var lat = double.Parse(first.GetProperty("lat").GetString()!, CultureInfo.InvariantCulture);
                    var lon = double.Parse(first.GetProperty("lon").GetString()!, CultureInfo.InvariantCulture);
                    return (lat, lon);
                }
                return (0, 0);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء الحصول على الإحداثيات");
                throw;
            }
        }

        /// <summary>
        /// الحصول على العنوان من الإحداثيات
        /// Get address from coordinates
        /// </summary>
        public async Task<string> GetAddressAsync(double latitude, double longitude, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على العنوان من الإحداثيات: {Latitude},{Longitude}", latitude, longitude);
            try
            {
                var url = $"{_settings.GeocodingApiUrl}/reverse?format=json&lat={latitude.ToString(CultureInfo.InvariantCulture)}&lon={longitude.ToString(CultureInfo.InvariantCulture)}";
                var response = await _httpClient.GetStringAsync(url);
                var doc = JsonDocument.Parse(response);
                if (doc.RootElement.TryGetProperty("display_name", out var name))
                    return name.GetString()!;
                return string.Empty;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء الحصول على العنوان");
                throw;
            }
        }

        /// <summary>
        /// حساب المسافة بين نقطتين
        /// Calculate distance between two points
        /// </summary>
        public Task<double> CalculateDistanceAsync(double lat1, double lon1, double lat2, double lon2, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("حساب المسافة بين نقطتين: {Lat1},{Lon1} و {Lat2},{Lon2}", lat1, lon1, lat2, lon2);
            double ToRadians(double deg) => deg * Math.PI / 180.0;
            var R = 6371.0; // Earth radius in km
            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);
            var a = Math.Pow(Math.Sin(dLat / 2), 2) + Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) * Math.Pow(Math.Sin(dLon / 2), 2);
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            var distance = R * c;
            return Task.FromResult(distance);
        }

        /// <summary>
        /// العثور على الأماكن القريبة
        /// Find nearby places
        /// </summary>
        public async Task<IEnumerable<object>> FindNearbyPlacesAsync(double latitude, double longitude, double radiusKm, string placeType = "all", CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("العثور على الأماكن القريبة من: {Latitude},{Longitude} بنصف قطر: {RadiusKm} كم (Type: {PlaceType})", latitude, longitude, radiusKm, placeType);
            try
            {
                var radius = (int)(radiusKm * 1000);
                var filter = placeType.ToLower() == "all" ? "" : $"[amenity={placeType.ToLower()}]";
                var query = $"[out:json];node(around:{radius},{latitude.ToString(CultureInfo.InvariantCulture)},{longitude.ToString(CultureInfo.InvariantCulture)}){filter};out;";
                var url = $"https://overpass-api.de/api/interpreter?data={Uri.EscapeDataString(query)}";
                var response = await _httpClient.GetStringAsync(url);
                var doc = JsonDocument.Parse(response);
                var list = new List<object>();
                if (doc.RootElement.TryGetProperty("elements", out var elements))
                {
                    foreach (var el in elements.EnumerateArray())
                    {
                        var id = el.GetProperty("id").GetInt64();
                        var lat = el.GetProperty("lat").GetDouble();
                        var lon = el.GetProperty("lon").GetDouble();
                        var tags = el.TryGetProperty("tags", out var t) ? t : default;
                        list.Add(new { Id = id, Latitude = lat, Longitude = lon, Tags = tags });
                    }
                }
                return list;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء العثور على الأماكن القريبة");
                return Array.Empty<object>();
            }
        }

        /// <summary>
        /// التحقق من صحة الإحداثيات
        /// Validate coordinates
        /// </summary>
        public Task<bool> ValidateCoordinatesAsync(double latitude, double longitude, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("التحقق من صحة الإحداثيات: {Latitude},{Longitude}", latitude, longitude);
            var isValid = latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
            return Task.FromResult(isValid);
        }

        /// <summary>
        /// الحصول على معلومات المنطقة الزمنية من الإحداثيات
        /// Get timezone info from coordinates
        /// </summary>
        public async Task<string> GetTimezoneAsync(double latitude, double longitude, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("الحصول على معلومات المنطقة الزمنية للإحداثيات: {Latitude},{Longitude}", latitude, longitude);
            try
            {
                var timestamp = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
                var url = $"{_settings.TimezoneApiUrl}?key={_settings.ApiKey}&format=json&by=position&lat={latitude.ToString(CultureInfo.InvariantCulture)}&lng={longitude.ToString(CultureInfo.InvariantCulture)}&time={timestamp}";
                var response = await _httpClient.GetStringAsync(url);
                var doc = JsonDocument.Parse(response);
                if (doc.RootElement.TryGetProperty("zoneName", out var zone))
                    return zone.GetString()!;
                if (doc.RootElement.TryGetProperty("zone_name", out var zone2))
                    return zone2.GetString()!;
                return string.Empty;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء الحصول على معلومات المنطقة الزمنية");
                throw;
            }
        }
    }
}