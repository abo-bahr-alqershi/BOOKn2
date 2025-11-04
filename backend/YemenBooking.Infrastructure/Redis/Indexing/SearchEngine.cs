using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using StackExchange.Redis;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Data.Context;
using System.Text.Json;

namespace YemenBooking.Infrastructure.Redis.Indexing
{
    /// <summary>
    /// محرك البحث - يطبق مبادئ العزل والأداء
    /// </summary>
    internal sealed class SearchEngine
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger _logger;
        private readonly JsonSerializerOptions _jsonOptions;

        // مفاتيح Redis
        private const string PROPERTY_KEY_PREFIX = "property:";
        private const string CITY_INDEX_KEY = "index:city:";
        private const string TYPE_INDEX_KEY = "index:type:";
        private const string PRICE_INDEX_KEY = "index:price";
        private const string RATING_INDEX_KEY = "index:rating";
        private const string SEARCH_INDEX_KEY = "search:index";

        public SearchEngine(
            IRedisConnectionManager redisManager,
            IServiceProvider serviceProvider,
            ILogger logger)
        {
            _redisManager = redisManager ?? throw new ArgumentNullException(nameof(redisManager));
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            
            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = false
            };
        }

        /// <summary>
        /// تنفيذ البحث
        /// </summary>
        public async Task<PropertySearchResult> ExecuteSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                var stopwatch = System.Diagnostics.Stopwatch.StartNew();
                
                // الحصول على معرفات العقارات المطابقة
                var propertyIds = await GetMatchingPropertyIdsAsync(request, cancellationToken);
                
                if (!propertyIds.Any())
                {
                    return new PropertySearchResult
                    {
                        Properties = new List<PropertySearchItem>(),
                        TotalCount = 0,
                        PageNumber = request.PageNumber,
                        PageSize = request.PageSize,
                        TotalPages = 0
                    };
                }

                // تطبيق الترتيب
                propertyIds = await ApplySortingAsync(propertyIds, request.SortBy, cancellationToken);
                
                // حساب الصفحات
                var totalCount = propertyIds.Count;
                var totalPages = (int)Math.Ceiling(totalCount / (double)request.PageSize);
                
                // تطبيق التصفح
                var pagedIds = propertyIds
                    .Skip((request.PageNumber - 1) * request.PageSize)
                    .Take(request.PageSize)
                    .ToList();
                
                // جلب تفاصيل العقارات
                var properties = await GetPropertyDetailsAsync(pagedIds, cancellationToken);
                
                stopwatch.Stop();
                _logger.LogInformation(
                    "Search completed in {ElapsedMs}ms. Found {TotalCount} results, returned {ReturnedCount}",
                    stopwatch.ElapsedMilliseconds, totalCount, properties.Count);
                
                return new PropertySearchResult
                {
                    Properties = properties,
                    TotalCount = totalCount,
                    PageNumber = request.PageNumber,
                    PageSize = request.PageSize,
                    TotalPages = totalPages
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing search");
                throw;
            }
        }

        /// <summary>
        /// الحصول على معرفات العقارات المطابقة
        /// </summary>
        private async Task<List<string>> GetMatchingPropertyIdsAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var db = _redisManager.GetDatabase();
            var sets = new List<RedisKey>();
            
            // البحث بالمدينة
            if (!string.IsNullOrWhiteSpace(request.City))
            {
                sets.Add($"{CITY_INDEX_KEY}{request.City.ToLower()}");
            }
            
            // البحث بنوع العقار
            if (!string.IsNullOrWhiteSpace(request.PropertyType))
            {
                sets.Add($"{TYPE_INDEX_KEY}{request.PropertyType}");
            }
            
            // إذا لم تكن هناك فلاتر، استخدم الفهرس الرئيسي
            if (sets.Count == 0)
            {
                sets.Add(SEARCH_INDEX_KEY);
            }
            
            // تقاطع المجموعات
            RedisValue[] baseResults;
            if (sets.Count == 1)
            {
                baseResults = await db.SetMembersAsync(sets[0]);
            }
            else
            {
                // إنشاء مفتاح مؤقت للتقاطع
                var tempKey = $"temp:search:{Guid.NewGuid():N}";
                await db.SetCombineAndStoreAsync(SetOperation.Intersect, tempKey, sets.ToArray());
                baseResults = await db.SetMembersAsync(tempKey);
                await db.KeyDeleteAsync(tempKey);
            }
            
            var propertyIds = baseResults.Select(r => r.ToString()).ToList();
            
            // تطبيق فلاتر إضافية
            propertyIds = await ApplyAdditionalFiltersAsync(propertyIds, request, cancellationToken);
            
            return propertyIds;
        }

        /// <summary>
        /// تطبيق فلاتر إضافية
        /// </summary>
        private async Task<List<string>> ApplyAdditionalFiltersAsync(
            List<string> propertyIds,
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            if (!propertyIds.Any())
                return propertyIds;
            
            var db = _redisManager.GetDatabase();
            var filteredIds = new List<string>();
            
            // تطبيق فلتر السعر
            if (request.MinPrice.HasValue || request.MaxPrice.HasValue)
            {
                var minPrice = request.MinPrice ?? 0;
                var maxPrice = request.MaxPrice ?? decimal.MaxValue;
                
                var priceFilteredIds = await db.SortedSetRangeByScoreAsync(
                    PRICE_INDEX_KEY,
                    (double)minPrice,
                    (double)maxPrice);
                
                var priceSet = new HashSet<string>(priceFilteredIds.Select(v => v.ToString()));
                propertyIds = propertyIds.Where(id => priceSet.Contains(id)).ToList();
            }
            
            // تطبيق فلتر التقييم
            if (request.MinRating.HasValue)
            {
                var ratingFilteredIds = await db.SortedSetRangeByScoreAsync(
                    RATING_INDEX_KEY,
                    (double)request.MinRating.Value,
                    5.0);
                
                var ratingSet = new HashSet<string>(ratingFilteredIds.Select(v => v.ToString()));
                propertyIds = propertyIds.Where(id => ratingSet.Contains(id)).ToList();
            }
            
            // تطبيق فلتر البحث النصي
            if (!string.IsNullOrWhiteSpace(request.SearchText))
            {
                propertyIds = await ApplyTextSearchAsync(propertyIds, request.SearchText, cancellationToken);
            }
            
            // تطبيق فلتر المرافق
            if (request.RequiredAmenityIds?.Any() == true)
            {
                propertyIds = await ApplyAmenitiesFilterAsync(propertyIds, request.RequiredAmenityIds, cancellationToken);
            }
            
            // تطبيق فلتر الإتاحة
            if (request.CheckIn.HasValue && request.CheckOut.HasValue)
            {
                propertyIds = await ApplyAvailabilityFilterAsync(
                    propertyIds,
                    request.CheckIn.Value,
                    request.CheckOut.Value,
                    cancellationToken);
            }
            
            return propertyIds;
        }

        /// <summary>
        /// تطبيق البحث النصي
        /// </summary>
        private async Task<List<string>> ApplyTextSearchAsync(
            List<string> propertyIds,
            string searchText,
            CancellationToken cancellationToken)
        {
            if (!propertyIds.Any() || string.IsNullOrWhiteSpace(searchText))
                return propertyIds;
            
            var db = _redisManager.GetDatabase();
            var searchTerms = searchText.ToLower().Split(' ', StringSplitOptions.RemoveEmptyEntries);
            var matchingIds = new List<string>();
            
            // البحث في بيانات كل عقار
            foreach (var propertyId in propertyIds)
            {
                var propertyKey = $"{PROPERTY_KEY_PREFIX}{propertyId}";
                var json = await db.StringGetAsync(propertyKey);
                
                if (json.HasValue)
                {
                    var jsonString = json.ToString().ToLower();
                    
                    // التحقق من وجود جميع كلمات البحث
                    if (searchTerms.All(term => jsonString.Contains(term)))
                    {
                        matchingIds.Add(propertyId);
                    }
                }
            }
            
            return matchingIds;
        }

        /// <summary>
        /// تطبيق فلتر المرافق
        /// </summary>
        private async Task<List<string>> ApplyAmenitiesFilterAsync(
            List<string> propertyIds,
            List<string> requiredAmenities,
            CancellationToken cancellationToken)
        {
            if (!propertyIds.Any() || !requiredAmenities.Any())
                return propertyIds;
            
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // الحصول على العقارات التي تحتوي على جميع المرافق المطلوبة
            var guids = propertyIds.Select(id => Guid.Parse(id)).ToList();
            
            var matchingPropertyIds = await dbContext.Properties
                .Where(p => guids.Contains(p.Id))
                .Where(p => requiredAmenities.All(amenityId => 
                    p.Amenities.Any(a => a.Id.ToString() == amenityId)))
                .Select(p => p.Id)
                .ToListAsync(cancellationToken);
            
            return matchingPropertyIds.Select(id => id.ToString()).ToList();
        }

        /// <summary>
        /// تطبيق فلتر الإتاحة
        /// </summary>
        private async Task<List<string>> ApplyAvailabilityFilterAsync(
            List<string> propertyIds,
            DateTime checkIn,
            DateTime checkOut,
            CancellationToken cancellationToken)
        {
            if (!propertyIds.Any())
                return propertyIds;
            
            var db = _redisManager.GetDatabase();
            var availablePropertyIds = new List<string>();
            
            foreach (var propertyId in propertyIds)
            {
                // التحقق من إتاحة وحدات العقار
                var isAvailable = await CheckPropertyAvailabilityAsync(
                    Guid.Parse(propertyId),
                    checkIn,
                    checkOut,
                    cancellationToken);
                
                if (isAvailable)
                {
                    availablePropertyIds.Add(propertyId);
                }
            }
            
            return availablePropertyIds;
        }

        /// <summary>
        /// التحقق من إتاحة العقار
        /// </summary>
        private async Task<bool> CheckPropertyAvailabilityAsync(
            Guid propertyId,
            DateTime checkIn,
            DateTime checkOut,
            CancellationToken cancellationToken)
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // التحقق من وجود وحدات متاحة في الفترة المطلوبة
            var hasAvailableUnits = await dbContext.Units
                .Where(u => u.PropertyId == propertyId && u.IsActive)
                .AnyAsync(u => !u.Bookings.Any(b => 
                    b.Status != YemenBooking.Core.Enums.BookingStatus.Cancelled &&
                    b.CheckIn < checkOut &&
                    b.CheckOut > checkIn), cancellationToken);
            
            return hasAvailableUnits;
        }

        /// <summary>
        /// تطبيق الترتيب
        /// </summary>
        private async Task<List<string>> ApplySortingAsync(
            List<string> propertyIds,
            string sortBy,
            CancellationToken cancellationToken)
        {
            if (!propertyIds.Any())
                return propertyIds;
            
            var db = _redisManager.GetDatabase();
            
            switch (sortBy?.ToLower())
            {
                case "price_asc":
                    return await SortByPriceAsync(propertyIds, true, cancellationToken);
                    
                case "price_desc":
                    return await SortByPriceAsync(propertyIds, false, cancellationToken);
                    
                case "rating":
                case "rating_desc":
                    return await SortByRatingAsync(propertyIds, false, cancellationToken);
                    
                case "newest":
                    return await SortByDateAsync(propertyIds, false, cancellationToken);
                    
                case "oldest":
                    return await SortByDateAsync(propertyIds, true, cancellationToken);
                    
                default:
                    // الترتيب الافتراضي - حسب الصلة
                    return propertyIds;
            }
        }

        /// <summary>
        /// الترتيب حسب السعر
        /// </summary>
        private async Task<List<string>> SortByPriceAsync(
            List<string> propertyIds,
            bool ascending,
            CancellationToken cancellationToken)
        {
            var db = _redisManager.GetDatabase();
            var propertyPrices = new List<(string Id, double Price)>();
            
            foreach (var propertyId in propertyIds)
            {
                var score = await db.SortedSetScoreAsync(PRICE_INDEX_KEY, propertyId);
                if (score.HasValue)
                {
                    propertyPrices.Add((propertyId, score.Value));
                }
            }
            
            if (ascending)
            {
                return propertyPrices.OrderBy(p => p.Price).Select(p => p.Id).ToList();
            }
            else
            {
                return propertyPrices.OrderByDescending(p => p.Price).Select(p => p.Id).ToList();
            }
        }

        /// <summary>
        /// الترتيب حسب التقييم
        /// </summary>
        private async Task<List<string>> SortByRatingAsync(
            List<string> propertyIds,
            bool ascending,
            CancellationToken cancellationToken)
        {
            var db = _redisManager.GetDatabase();
            var propertyRatings = new List<(string Id, double Rating)>();
            
            foreach (var propertyId in propertyIds)
            {
                var score = await db.SortedSetScoreAsync(RATING_INDEX_KEY, propertyId);
                if (score.HasValue)
                {
                    propertyRatings.Add((propertyId, score.Value));
                }
                else
                {
                    propertyRatings.Add((propertyId, 0));
                }
            }
            
            if (ascending)
            {
                return propertyRatings.OrderBy(p => p.Rating).Select(p => p.Id).ToList();
            }
            else
            {
                return propertyRatings.OrderByDescending(p => p.Rating).Select(p => p.Id).ToList();
            }
        }

        /// <summary>
        /// الترتيب حسب التاريخ
        /// </summary>
        private async Task<List<string>> SortByDateAsync(
            List<string> propertyIds,
            bool ascending,
            CancellationToken cancellationToken)
        {
            var db = _redisManager.GetDatabase();
            var propertyDates = new List<(string Id, DateTime Date)>();
            
            foreach (var propertyId in propertyIds)
            {
                var propertyKey = $"{PROPERTY_KEY_PREFIX}{propertyId}";
                var json = await db.StringGetAsync(propertyKey);
                
                if (json.HasValue)
                {
                    try
                    {
                        var data = JsonSerializer.Deserialize<PropertyIndexData>(json, _jsonOptions);
                        propertyDates.Add((propertyId, data.CreatedAt));
                    }
                    catch
                    {
                        propertyDates.Add((propertyId, DateTime.MinValue));
                    }
                }
            }
            
            if (ascending)
            {
                return propertyDates.OrderBy(p => p.Date).Select(p => p.Id).ToList();
            }
            else
            {
                return propertyDates.OrderByDescending(p => p.Date).Select(p => p.Id).ToList();
            }
        }

        /// <summary>
        /// الحصول على تفاصيل العقارات
        /// </summary>
        private async Task<List<PropertySearchItem>> GetPropertyDetailsAsync(
            List<string> propertyIds,
            CancellationToken cancellationToken)
        {
            if (!propertyIds.Any())
                return new List<PropertySearchItem>();
            
            var db = _redisManager.GetDatabase();
            var properties = new List<PropertySearchItem>();
            
            foreach (var propertyId in propertyIds)
            {
                var propertyKey = $"{PROPERTY_KEY_PREFIX}{propertyId}";
                var json = await db.StringGetAsync(propertyKey);
                
                if (json.HasValue)
                {
                    try
                    {
                        var data = JsonSerializer.Deserialize<PropertyIndexData>(json, _jsonOptions);
                        
                        properties.Add(new PropertySearchItem
                        {
                            Id = data.Id.ToString(),
                            Name = data.Name,
                            City = data.City,
                            PropertyType = data.PropertyTypeName,
                            MinPrice = data.MinPrice,
                            Currency = "YER",
                            AverageRating = data.AverageRating,
                            StarRating = (int)Math.Round(data.AverageRating),
                            ImageUrls = new List<string>(), // يمكن إضافة URLs الصور لاحقاً
                            MaxCapacity = 0, // يمكن حسابها من الوحدات
                            UnitsCount = data.TotalUnits,
                            DynamicFields = new Dictionary<string, string>(),
                            Latitude = 0,
                            Longitude = 0
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Error deserializing property {PropertyId}", propertyId);
                    }
                }
            }
            
            return properties;
        }
    }
}
