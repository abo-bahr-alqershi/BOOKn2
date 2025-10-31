using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Interfaces.Repositories;
using TimeZoneConverter;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// خدمة المستخدم الحالي التي تستخرج معلومات المستخدم من HttpContext
    /// Implementation of ICurrentUserService that extracts user information from HttpContext
    /// </summary>
    public class CurrentUserService : ICurrentUserService
    {
        private readonly IHttpContextAccessor _httpContextAccessor;
        private readonly IUserRepository _userRepository;
        private readonly IGeolocationService _geolocationService;
        private readonly IMemoryCache _cache;
        private readonly ILogger<CurrentUserService> _logger;

        public CurrentUserService(
            IHttpContextAccessor httpContextAccessor, 
            IUserRepository userRepository, 
            IGeolocationService geolocationService, 
            IMemoryCache cache, 
            ILogger<CurrentUserService> logger)
        {
            _httpContextAccessor = httpContextAccessor;
            _userRepository = userRepository;
            _geolocationService = geolocationService;
            _cache = cache;
            _logger = logger;
        }

        private ClaimsPrincipal? User => _httpContextAccessor.HttpContext?.User;

        /// <summary>
        /// معرّف المستخدم الحالي
        /// </summary>
        public Guid UserId
        {
            get
            {
                var idClaim = User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
                return Guid.TryParse(idClaim, out var id) ? id : Guid.Empty;
            }
        }

        /// <summary>
        /// اسم المستخدم الحالي
        /// </summary>
        public string Username => User?.Identity?.Name ?? string.Empty;

        /// <summary>
        /// الدور الخاص بالمستخدم الحالي
        /// </summary>
        public string Role
        {
            get
            {
                var role = User?.FindFirst(ClaimTypes.Role)?.Value;
                if (string.IsNullOrWhiteSpace(role))
                {
                    role = User?.FindFirst("accountRole")?.Value;
                }
                if (string.IsNullOrWhiteSpace(role))
                {
                    var headerRole = _httpContextAccessor.HttpContext?.Request?.Headers?["X-Account-Role"].ToString();
                    if (!string.IsNullOrWhiteSpace(headerRole)) role = headerRole;
                }
                return role ?? string.Empty;
            }
        }

        /// <summary>
        /// نوع الحساب الموحّد
        /// </summary>
        public string AccountRole => User?.FindFirst("accountRole")?.Value ?? string.Empty;

        /// <summary>
        /// هل المستخدم الحالي مدير
        /// </summary>
        public bool IsAdmin => UserRoles.Contains("Admin");

        /// <summary>
        /// قائمة الأذونات الخاصة بالمستخدم الحالي
        /// </summary>
        public IEnumerable<string> Permissions =>
            User?.FindAll("permission")?.Select(c => c.Value) ?? Enumerable.Empty<string>();

        /// <summary>
        /// قائمة الأدوار الخاصة بالمستخدم الحالي
        /// </summary>
        public IEnumerable<string> UserRoles =>
            User?.FindAll(ClaimTypes.Role)?.Select(c => c.Value) ?? Enumerable.Empty<string>();

        /// <summary>
        /// معرف التتبّع لربط الطلبات
        /// </summary>
        public string CorrelationId => User?.FindFirst("correlationId")?.Value ?? Guid.NewGuid().ToString();

        /// <summary>
        /// معرف الكيان المرتبط بالمستخدم
        /// </summary>
        public Guid? PropertyId
        {
            get
            {
                var propIdClaim = User?.FindFirst("propertyId")?.Value;
                if (Guid.TryParse(propIdClaim, out var pid)) return pid;
                var headerVal = _httpContextAccessor.HttpContext?.Request?.Headers?["X-Property-Id"].ToString();
                if (!string.IsNullOrWhiteSpace(headerVal) && Guid.TryParse(headerVal, out var pid2)) return pid2;
                return null;
            }
        }

        /// <summary>
        /// اسم الكيان المرتبط بالمستخدم
        /// </summary>
        public string? PropertyName => User?.FindFirst("propertyName")?.Value;

        /// <summary>
        /// عملة العقار المرتبط بالمستخدم
        /// </summary>
        public string? PropertyCurrency
        {
            get
            {
                var v = User?.FindFirst("propertyCurrency")?.Value;
                if (!string.IsNullOrWhiteSpace(v)) return v;
                var headerVal = _httpContextAccessor.HttpContext?.Request?.Headers?["X-Property-Currency"].ToString();
                return string.IsNullOrWhiteSpace(headerVal) ? null : headerVal;
            }
        }

        /// <summary>
        /// معرف موظف الكيان المرتبط بالمستخدم
        /// </summary>
        public Guid? StaffId
        {
            get
            {
                var staffIdClaim = User?.FindFirst("staffId")?.Value;
                return Guid.TryParse(staffIdClaim, out var sid) ? sid : (Guid?)null;
            }
        }

        /// <summary>
        /// التحقق مما إذا كان المستخدم الحالي موظفاً في الكيان المحدد
        /// </summary>
        public bool IsStaffInProperty(Guid propertyId)
        {
            var userPropertyId = PropertyId;
            return userPropertyId.HasValue && userPropertyId.Value == propertyId &&
                   (UserRoles.Contains("Staff"));
        }

        /// <summary>
        /// جلب بيانات المستخدم الحالي من قاعدة البيانات
        /// </summary>
        public async Task<User> GetCurrentUserAsync(CancellationToken cancellationToken = default)
        {
            // التحقق من وجود هوية مصدقة
            if (User == null || UserId == Guid.Empty)
                throw new UnauthorizedAccessException("المستخدم غير مصدق عليه");

            // جلب الكيان من قاعدة البيانات
            var user = await _userRepository.GetUserByIdAsync(UserId, cancellationToken);
            if (user == null)
                throw new UnauthorizedAccessException($"المستخدم بالمعرف {UserId} غير موجود");

            return user;
        }

        public Task<bool> IsInRoleAsync(string role)
        {
            var hasRole = UserRoles != null && UserRoles.Contains(role);
            return Task.FromResult(hasRole);
        }

        /// <summary>
        /// الحصول على معلومات الموقع والمنطقة الزمنية للمستخدم
        /// Get user location and timezone info
        /// </summary>
        public async Task<UserLocationInfo> GetUserLocationAsync()
        {
            var cacheKey = $"user_location_{UserId}";
            
            // التحقق من الـ cache
            if (_cache.TryGetValue<UserLocationInfo>(cacheKey, out var cachedLocation))
            {
                _logger.LogDebug("Returning cached location for user {UserId}", UserId);
                return cachedLocation;
            }

            try
            {
                // 1. محاولة الحصول على المنطقة الزمنية من Headers أولاً
                var timezoneFromHeaders = _geolocationService.GetTimezoneFromHeaders();
                var offsetFromHeaders = _geolocationService.GetTimezoneOffsetFromHeaders();

                if (!string.IsNullOrEmpty(timezoneFromHeaders))
                {
                    _logger.LogInformation("Using timezone from headers for user {UserId}: {Timezone}", 
                        UserId, timezoneFromHeaders);

                    var locationInfo = CreateLocationInfoFromTimezone(
                        timezoneFromHeaders, 
                        offsetFromHeaders,
                        "Headers");

                    // Cache لمدة ساعة
                    _cache.Set(cacheKey, locationInfo, TimeSpan.FromHours(1));
                    
                    // حفظ في profile المستخدم للاستخدام المستقبلي
                    await UpdateUserTimezoneAsync(timezoneFromHeaders, locationInfo);
                    
                    return locationInfo;
                }

                // 2. محاولة الحصول من profile المستخدم
                var user = await GetCurrentUserAsync();
                if (!string.IsNullOrEmpty(user?.TimeZoneId))
                {
                    _logger.LogInformation("Using saved timezone for user {UserId}: {Timezone}", 
                        UserId, user.TimeZoneId);

                    var locationInfo = CreateLocationInfoFromTimezone(
                        user.TimeZoneId,
                        null,
                        "UserProfile");

                    locationInfo.Country = user.Country ?? locationInfo.Country;
                    locationInfo.City = user.City ?? locationInfo.City;
                    
                    _cache.Set(cacheKey, locationInfo, TimeSpan.FromHours(1));
                    return locationInfo;
                }

                // 3. استخدام IP geolocation كـ fallback
                _logger.LogInformation("Using IP geolocation for user {UserId}", UserId);
                var geoInfo = await _geolocationService.GetLocationInfoAsync();
                
                var ipLocationInfo = new UserLocationInfo
                {
                    Country = geoInfo.Country,
                    CountryCode = geoInfo.CountryCode,
                    City = geoInfo.City,
                    TimeZoneId = geoInfo.TimeZoneId,
                    UtcOffset = GetOffsetFromMinutes(geoInfo.TimeZoneOffset),
                    Source = geoInfo.Source
                };

                // تحديد timezone name
                try
                {
                    var timeZone = TZConvert.GetTimeZoneInfo(geoInfo.TimeZoneId);
                    ipLocationInfo.TimeZoneName = timeZone.DisplayName;
                    ipLocationInfo.IsDaylightSaving = timeZone.IsDaylightSavingTime(DateTime.Now);
                    ipLocationInfo.UtcOffset = timeZone.GetUtcOffset(DateTime.Now);
                }
                catch
                {
                    ipLocationInfo.TimeZoneName = $"UTC{ipLocationInfo.UtcOffset:hh\\:mm}";
                }

                _cache.Set(cacheKey, ipLocationInfo, TimeSpan.FromHours(1));
                
                // حفظ في profile المستخدم
                await UpdateUserTimezoneAsync(geoInfo.TimeZoneId, ipLocationInfo);
                
                return ipLocationInfo;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting user location for user {UserId}", UserId);
                return GetDefaultLocation();
            }
        }

        /// <summary>
        /// تحويل التوقيت من UTC إلى التوقيت المحلي للمستخدم
        /// Convert from UTC to user's local time
        /// </summary>
        public async Task<DateTime> ConvertFromUtcToUserLocalAsync(DateTime utcDateTime)
        {
            if (utcDateTime.Kind != DateTimeKind.Utc)
            {
                utcDateTime = DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc);
            }

            // محاولة استخدام GeolocationService مباشرة (يستخدم headers)
            var converted = _geolocationService.ConvertFromUtc(utcDateTime);
            if (converted != utcDateTime.AddHours(3)) // إذا لم يكن الـ default
            {
                return converted;
            }

            // fallback للطريقة القديمة
            var timeZoneId = await GetUserTimeZoneIdAsync();
            
            try
            {
                var timeZone = TZConvert.GetTimeZoneInfo(timeZoneId);
                return TimeZoneInfo.ConvertTimeFromUtc(utcDateTime, timeZone);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error converting from UTC to local time. TimeZone: {TimeZone}", timeZoneId);
                // Fallback to Yemen time
                return utcDateTime.AddHours(3);
            }
        }

        /// <summary>
        /// تحويل التوقيت من التوقيت المحلي للمستخدم إلى UTC
        /// Convert from user's local time to UTC
        /// </summary>
        public async Task<DateTime> ConvertFromUserLocalToUtcAsync(DateTime localDateTime)
        {
            // محاولة استخدام GeolocationService مباشرة (يستخدم headers)
            var converted = _geolocationService.ConvertToUtc(localDateTime);
            if (converted != localDateTime.AddHours(-3)) // إذا لم يكن الـ default
            {
                return converted;
            }

            // fallback للطريقة القديمة
            var timeZoneId = await GetUserTimeZoneIdAsync();
            
            try
            {
                if (localDateTime.Kind == DateTimeKind.Utc)
                    return localDateTime;

                localDateTime = DateTime.SpecifyKind(localDateTime, DateTimeKind.Unspecified);
                
                var timeZone = TZConvert.GetTimeZoneInfo(timeZoneId);
                return TimeZoneInfo.ConvertTimeToUtc(localDateTime, timeZone);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error converting from local to UTC time. TimeZone: {TimeZone}", timeZoneId);
                // Fallback
                return localDateTime.AddHours(-3);
            }
        }

        /// <summary>
        /// الحصول على معرف المنطقة الزمنية للمستخدم
        /// Get user's timezone ID
        /// </summary>
        public async Task<string> GetUserTimeZoneIdAsync()
        {
            // 1. محاولة من Headers
            var timezoneFromHeaders = _geolocationService.GetTimezoneFromHeaders();
            if (!string.IsNullOrEmpty(timezoneFromHeaders))
                return timezoneFromHeaders;

            // 2. من location info
            var location = await GetUserLocationAsync();
            return location?.TimeZoneId ?? "Asia/Aden";
        }

        /// <summary>
        /// الحصول على الإزاحة الزمنية الحالية للمستخدم من UTC
        /// Get user's current UTC offset
        /// </summary>
        public async Task<TimeSpan> GetUserTimeZoneOffsetAsync()
        {
            // 1. محاولة من Headers
            var offsetFromHeaders = _geolocationService.GetTimezoneOffsetFromHeaders();
            if (offsetFromHeaders.HasValue)
                return TimeSpan.FromMinutes(-offsetFromHeaders.Value);

            // 2. من location info
            var location = await GetUserLocationAsync();
            return location?.UtcOffset ?? TimeSpan.FromHours(3);
        }

        /// <summary>
        /// إنشاء معلومات الموقع من المنطقة الزمنية
        /// Create location info from timezone
        /// </summary>
        private UserLocationInfo CreateLocationInfoFromTimezone(string timeZoneId, int? offsetMinutes, string source)
        {
            try
            {
                UserLocationInfo info = new UserLocationInfo
                {
                    TimeZoneId = timeZoneId,
                    Source = source
                };

                // محاولة الحصول على معلومات المنطقة الزمنية
                if (!string.IsNullOrEmpty(timeZoneId) && !timeZoneId.StartsWith("UTC"))
                {
                    try
                    {
                        var timeZone = TZConvert.GetTimeZoneInfo(timeZoneId);
                        var now = DateTime.UtcNow;
                        info.UtcOffset = timeZone.GetUtcOffset(now);
                        info.TimeZoneName = timeZone.DisplayName;
                        info.IsDaylightSaving = timeZone.IsDaylightSavingTime(now);
                    }
                    catch
                    {
                        // في حالة فشل التحويل
                        if (offsetMinutes.HasValue)
                        {
                            info.UtcOffset = TimeSpan.FromMinutes(-offsetMinutes.Value);
                            info.TimeZoneName = $"UTC{info.UtcOffset:hh\\:mm}";
                        }
                    }
                }
                else if (offsetMinutes.HasValue)
                {
                    info.UtcOffset = TimeSpan.FromMinutes(-offsetMinutes.Value);
                    info.TimeZoneName = $"UTC{info.UtcOffset:hh\\:mm}";
                }

                // محاولة استنتاج الدولة من timezone
                EnrichLocationFromTimezone(info);

                return info;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating location info from timezone: {TimeZone}", timeZoneId);
                return GetDefaultLocation();
            }
        }

        /// <summary>
        /// إثراء معلومات الموقع من المنطقة الزمنية
        /// </summary>
        private void EnrichLocationFromTimezone(UserLocationInfo info)
        {
            var timezoneMap = new Dictionary<string, (string Country, string Code, string City)>
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
                // إضافة المزيد حسب الحاجة
            };

            if (timezoneMap.TryGetValue(info.TimeZoneId ?? "", out var location))
            {
                info.Country = info.Country ?? location.Country;
                info.CountryCode = info.CountryCode ?? location.Code;
                info.City = info.City ?? location.City;
            }
        }

        /// <summary>
        /// تحديث المنطقة الزمنية في profile المستخدم
        /// </summary>
        private async Task UpdateUserTimezoneAsync(string timeZoneId, UserLocationInfo locationInfo)
        {
            try
            {
                var user = await GetCurrentUserAsync();
                if (user != null && user.TimeZoneId != timeZoneId)
                {
                    user.TimeZoneId = timeZoneId;
                    user.Country = locationInfo.Country;
                    user.City = locationInfo.City;
                    await _userRepository.UpdateAsync(user);
                    
                    _logger.LogInformation("Updated timezone for user {UserId} to {TimeZone}", 
                        UserId, timeZoneId);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating user timezone");
            }
        }

        /// <summary>
        /// تحويل الدقائق إلى TimeSpan
        /// </summary>
        private TimeSpan GetOffsetFromMinutes(int? minutes)
        {
            if (!minutes.HasValue)
                return TimeSpan.FromHours(3);
            
            return TimeSpan.FromMinutes(-minutes.Value);
        }

        /// <summary>
        /// الحصول على معلومات الموقع الافتراضية
        /// </summary>
        private UserLocationInfo GetDefaultLocation()
        {
            return new UserLocationInfo
            {
                Country = "Yemen",
                CountryCode = "YE",
                City = "Sana'a",
                TimeZoneId = "Asia/Aden",
                UtcOffset = TimeSpan.FromHours(3),
                TimeZoneName = "(UTC+03:00) Yemen Time",
                IsDaylightSaving = false,
                Source = "Default"
            };
        }
    }
}