using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Caching.Memory;
using StackExchange.Redis;
using MessagePack;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Models;
using YemenBooking.Infrastructure.Redis.Cache;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Redis.Search
{
    /// <summary>
    /// محرك البحث المحسن - الطبقة الثانية في النظام
    /// يحدد استراتيجية البحث المثلى وينفذها بكفاءة عالية
    /// </summary>
    public class OptimizedSearchEngine
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IMultiLevelCache _cacheManager;
        private readonly ILogger<OptimizedSearchEngine> _logger;
        private readonly IDatabase _db;
        private readonly IMemoryCache _memoryCache;
        private readonly SemaphoreSlim _searchLimiter;

        /// <summary>
        /// مُنشئ محرك البحث المحسن
        /// </summary>
        public OptimizedSearchEngine(
            IRedisConnectionManager redisManager,
            IMultiLevelCache cacheManager,
            ILogger<OptimizedSearchEngine> logger,
            IMemoryCache memoryCache)
        {
            _redisManager = redisManager;
            _cacheManager = cacheManager;
            _logger = logger;
            _memoryCache = memoryCache;
            _db = _redisManager.GetDatabase();
            _searchLimiter = new SemaphoreSlim(50, 50); // حد أقصى 50 بحث متزامن
        }

        #region البحث الرئيسي

        /// <summary>
        /// تنفيذ البحث الرئيسي مع تحديد الاستراتيجية المثلى
        /// </summary>
        public async Task<PropertySearchResult> SearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            await _searchLimiter.WaitAsync(cancellationToken);
            
            try
            {
                _logger.LogInformation("🔎 بدء البحث: {SearchText}, المدينة: {City}", 
                    request.SearchText, request.City);

                // 1. التحقق من الكاش أولاً
                var cacheKey = GenerateCacheKey(request);
                var cachedResult = await _cacheManager.GetAsync<PropertySearchResult>(cacheKey);
                
                if (cachedResult != null)
                {
                    _logger.LogInformation("✅ إرجاع النتائج من الكاش (~{ElapsedMs}ms)", 
                        stopwatch.ElapsedMilliseconds);
                    RecordMetrics(stopwatch.ElapsedMilliseconds, true);
                    return cachedResult;
                }

                // 2. تحليل الطلب وتحديد الاستراتيجية
                var strategy = DetermineSearchStrategy(request);
                _logger.LogInformation("📋 استراتيجية البحث المحددة: {Strategy}", strategy);

                // 3. تنفيذ البحث حسب الاستراتيجية
                PropertySearchResult result;
                
                switch (strategy)
                {
                    case SearchStrategy.TextSearch:
                        result = await ExecuteTextSearchAsync(request, cancellationToken);
                        break;
                        
                    case SearchStrategy.GeoSearch:
                        result = await ExecuteGeoSearchAsync(request, cancellationToken);
                        break;
                        
                    case SearchStrategy.ComplexFilter:
                        result = await ExecuteComplexFilterAsync(request, cancellationToken);
                        break;
                        
                    case SearchStrategy.SimpleSearch:
                    default:
                        result = await ExecuteSimpleSearchAsync(request, cancellationToken);
                        break;
                }

                // 4. حفظ النتائج في الكاش
                await _cacheManager.SetAsync(cacheKey, result, TimeSpan.FromMinutes(10));

                var elapsed = stopwatch.ElapsedMilliseconds;
                _logger.LogInformation("✅ اكتمل البحث في {ElapsedMs}ms، النتائج: {Count}", 
                    elapsed, result.TotalCount);
                
                RecordMetrics(elapsed, false);
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ خطأ في البحث");
                RecordMetrics(stopwatch.ElapsedMilliseconds, false, true);
                throw;
            }
            finally
            {
                _searchLimiter.Release();
            }
        }

        #endregion

        #region استراتيجيات البحث

        /// <summary>
        /// تحديد استراتيجية البحث المثلى بناءً على معايير الطلب
        /// </summary>
        private SearchStrategy DetermineSearchStrategy(PropertySearchRequest request)
        {
            // إذا كان هناك نص بحث
            if (!string.IsNullOrWhiteSpace(request.SearchText))
            {
                return SearchStrategy.TextSearch;
            }

            // إذا كان هناك إحداثيات جغرافية
            if (request.Latitude.HasValue && request.Longitude.HasValue && request.RadiusKm.HasValue)
            {
                return SearchStrategy.GeoSearch;
            }

            // إذا كان هناك معايير متعددة معقدة
            var filterCount = 0;
            if (!string.IsNullOrWhiteSpace(request.City)) filterCount++;
            if (!string.IsNullOrWhiteSpace(request.PropertyType)) filterCount++;
            if (request.MinPrice.HasValue || request.MaxPrice.HasValue) filterCount++;
            if (request.RequiredAmenityIds?.Any() == true) filterCount++;
            if (request.CheckIn.HasValue && request.CheckOut.HasValue) filterCount++;
            if (request.DynamicFieldFilters?.Any() == true) filterCount++;

            if (filterCount >= 3)
            {
                return SearchStrategy.ComplexFilter;
            }

            // بحث بسيط
            return SearchStrategy.SimpleSearch;
        }

        /// <summary>
        /// تنفيذ البحث النصي باستخدام RediSearch
        /// </summary>
        private async Task<PropertySearchResult> ExecuteTextSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            try
            {
                // التحقق من توفر RediSearch
                if (!await IsRediSearchAvailable())
                {
                    _logger.LogWarning("RediSearch غير متاح، التحويل للبحث اليدوي");
                    return await ExecuteManualTextSearchAsync(request, cancellationToken);
                }

                // بناء استعلام RediSearch
                var query = BuildRediSearchQuery(request);
                var offset = (request.PageNumber - 1) * request.PageSize;

                // تنفيذ البحث
                var args = new List<object> { RedisKeySchemas.SEARCH_INDEX_NAME, query };
                
                // إضافة الترتيب
                AddSortingArgs(args, request.SortBy);
                
                // إضافة الصفحة
                args.AddRange(new object[] { "LIMIT", offset.ToString(), request.PageSize.ToString() });

                var result = await _db.ExecuteAsync("FT.SEARCH", args.ToArray());
                return ParseRediSearchResult(result, request);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في البحث النصي");
                throw;
            }
        }

        /// <summary>
        /// تنفيذ البحث الجغرافي
        /// </summary>
        private async Task<PropertySearchResult> ExecuteGeoSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var results = new List<PropertyIndexDocument>();

            // البحث في النطاق الجغرافي
            var geoKey = !string.IsNullOrWhiteSpace(request.City) 
                ? string.Format(RedisKeySchemas.GEO_CITY, request.City.ToLowerInvariant())
                : RedisKeySchemas.GEO_PROPERTIES;

            // استخدام GeoRadius للبحث الجغرافي
            var geoResults = await _db.GeoRadiusAsync(
                geoKey,
                request.Longitude.Value,
                request.Latitude.Value,
                request.RadiusKm.Value,
                GeoUnit.Kilometers,
                100,
                Order.Ascending);

            if (geoResults.Length == 0)
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

            // جلب تفاصيل العقارات
            var propertyIds = geoResults.Select(r => r.Member.ToString()).ToList();
            var properties = await GetPropertiesDetailsAsync(propertyIds);

            // تطبيق الفلاتر الإضافية
            properties = ApplyFilters(properties, request);

            // الترتيب والصفحة
            properties = ApplySorting(properties, request.SortBy);
            var pagedProperties = ApplyPaging(properties, request.PageNumber, request.PageSize);

            return BuildSearchResult(pagedProperties, properties.Count(), request);
        }

        /// <summary>
        /// تنفيذ الفلترة المعقدة باستخدام Lua Script
        /// </summary>
        private async Task<PropertySearchResult> ExecuteComplexFilterAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            // استخدام Lua Script للفلترة المعقدة على جانب الخادم
            var luaScript = GetComplexFilterLuaScript();
            var keys = BuildLuaScriptKeys(request);
            var args = BuildLuaScriptArgs(request);

            var result = await _db.ScriptEvaluateAsync(luaScript, keys, args);
            return ParseLuaScriptResult(result, request);
        }

        /// <summary>
        /// تنفيذ البحث البسيط
        /// </summary>
        private async Task<PropertySearchResult> ExecuteSimpleSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var propertyIds = new HashSet<string>();

            // البدء بجميع العقارات أو مجموعة محددة
            if (!string.IsNullOrWhiteSpace(request.City))
            {
                var cityKey = RedisKeySchemas.GetCityKey(request.City);
                var cityProperties = await _db.SetMembersAsync(cityKey);
                propertyIds = cityProperties.Select(p => p.ToString()).ToHashSet();
            }
            else
            {
                var allProperties = await _db.SetMembersAsync(RedisKeySchemas.PROPERTIES_ALL_SET);
                propertyIds = allProperties.Select(p => p.ToString()).ToHashSet();
            }

            // تطبيق فلتر النوع
            if (!string.IsNullOrWhiteSpace(request.PropertyType))
            {
                var typeKey = string.Format(RedisKeySchemas.TAG_TYPE, request.PropertyType);
                var typeProperties = await _db.SetMembersAsync(typeKey);
                propertyIds.IntersectWith(typeProperties.Select(p => p.ToString()));
            }

            // تطبيق فلتر المرافق
            if (request.RequiredAmenityIds?.Any() == true)
            {
                foreach (var amenityId in request.RequiredAmenityIds)
                {
                    var amenityKey = RedisKeySchemas.GetAmenityKey(Guid.Parse(amenityId));
                    var amenityProperties = await _db.SetMembersAsync(amenityKey);
                    propertyIds.IntersectWith(amenityProperties.Select(p => p.ToString()));
                }
            }

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

            // جلب التفاصيل وتطبيق الفلاتر
            var properties = await GetPropertiesDetailsAsync(propertyIds.ToList());
            properties = ApplyFilters(properties, request);
            properties = ApplySorting(properties, request.SortBy);
            var pagedProperties = ApplyPaging(properties, request.PageNumber, request.PageSize);

            return BuildSearchResult(pagedProperties, properties.Count(), request);
        }

        /// <summary>
        /// البحث النصي اليدوي (عندما RediSearch غير متاح)
        /// </summary>
        private async Task<PropertySearchResult> ExecuteManualTextSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var searchText = request.SearchText?.ToLowerInvariant();
            var allProperties = await _db.SetMembersAsync(RedisKeySchemas.PROPERTIES_ALL_SET);
            var matchedProperties = new List<PropertyIndexDocument>();

            foreach (var propertyId in allProperties)
            {
                var propertyKey = RedisKeySchemas.GetPropertyKey(Guid.Parse(propertyId));
                var propertyData = await _db.HashGetAllAsync(propertyKey);
                
                if (propertyData.Length == 0) continue;
                
                var doc = PropertyIndexDocument.FromHashEntries(propertyData);
                
                // بحث في الاسم والوصف
                if (doc.NameNormalized?.Contains(searchText) == true ||
                    doc.Description?.ToLowerInvariant().Contains(searchText) == true ||
                    doc.City?.ToLowerInvariant().Contains(searchText) == true)
                {
                    matchedProperties.Add(doc);
                }
            }

            // تطبيق الفلاتر والترتيب
            matchedProperties = ApplyFilters(matchedProperties, request);
            matchedProperties = ApplySorting(matchedProperties, request.SortBy);
            var pagedProperties = ApplyPaging(matchedProperties, request.PageNumber, request.PageSize);

            return BuildSearchResult(pagedProperties, matchedProperties.Count, request);
        }

        #endregion

        #region دوال مساعدة

        /// <summary>
        /// التحقق من توفر RediSearch
        /// </summary>
        private async Task<bool> IsRediSearchAvailable()
        {
            try
            {
                var marker = await _db.StringGetAsync("search:module:available");
                return marker == "1";
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// بناء استعلام RediSearch
        /// </summary>
        private string BuildRediSearchQuery(PropertySearchRequest request)
        {
            var queryParts = new List<string>();

            // النص البحثي
            if (!string.IsNullOrWhiteSpace(request.SearchText))
            {
                queryParts.Add($"(@name:{request.SearchText}* | @description:{request.SearchText})");
            }

            // المدينة
            if (!string.IsNullOrWhiteSpace(request.City))
            {
                queryParts.Add($"@city:{{{request.City}}}");
            }

            // نوع العقار
            if (!string.IsNullOrWhiteSpace(request.PropertyType))
            {
                queryParts.Add($"@property_type:{{{request.PropertyType}}}");
            }

            // نطاق السعر
            if (request.MinPrice.HasValue || request.MaxPrice.HasValue)
            {
                var min = request.MinPrice ?? 0;
                var max = request.MaxPrice ?? decimal.MaxValue;
                queryParts.Add($"@min_price:[{min} {max}]");
            }

            // التقييم الأدنى
            if (request.MinRating.HasValue)
            {
                queryParts.Add($"@average_rating:[{request.MinRating.Value} +inf]");
            }

            // الحالة النشطة والمعتمدة
            queryParts.Add("@is_active:{1} @is_approved:{1}");

            return queryParts.Any() ? string.Join(" ", queryParts) : "*";
        }

        /// <summary>
        /// إضافة معايير الترتيب
        /// </summary>
        private void AddSortingArgs(List<object> args, string sortBy)
        {
            switch (sortBy?.ToLowerInvariant())
            {
                case "price_asc":
                    args.AddRange(new object[] { "SORTBY", "min_price", "ASC" });
                    break;
                case "price_desc":
                    args.AddRange(new object[] { "SORTBY", "min_price", "DESC" });
                    break;
                case "rating":
                    args.AddRange(new object[] { "SORTBY", "average_rating", "DESC" });
                    break;
                case "newest":
                    args.AddRange(new object[] { "SORTBY", "created_at", "DESC" });
                    break;
                case "popularity":
                    args.AddRange(new object[] { "SORTBY", "booking_count", "DESC" });
                    break;
            }
        }

        /// <summary>
        /// جلب تفاصيل العقارات
        /// </summary>
        private async Task<List<PropertyIndexDocument>> GetPropertiesDetailsAsync(List<string> propertyIds)
        {
            var properties = new List<PropertyIndexDocument>();
            var batch = _db.CreateBatch();
            var tasks = new List<Task<HashEntry[]>>();

            foreach (var propertyId in propertyIds)
            {
                var propertyKey = RedisKeySchemas.GetPropertyKey(Guid.Parse(propertyId));
                tasks.Add(batch.HashGetAllAsync(propertyKey));
            }

            batch.Execute();
            var results = await Task.WhenAll(tasks);

            foreach (var data in results)
            {
                if (data.Length > 0)
                {
                    properties.Add(PropertyIndexDocument.FromHashEntries(data));
                }
            }

            return properties;
        }

        /// <summary>
        /// تطبيق الفلاتر على النتائج
        /// </summary>
        private List<PropertyIndexDocument> ApplyFilters(
            List<PropertyIndexDocument> properties,
            PropertySearchRequest request)
        {
            // فلتر السعر
            if (request.MinPrice.HasValue)
            {
                properties = properties.Where(p => p.MinPrice >= request.MinPrice.Value).ToList();
            }

            if (request.MaxPrice.HasValue)
            {
                properties = properties.Where(p => p.MinPrice <= request.MaxPrice.Value).ToList();
            }

            // فلتر التقييم
            if (request.MinRating.HasValue)
            {
                properties = properties.Where(p => p.AverageRating >= request.MinRating.Value).ToList();
            }

            // فلتر السعة
            if (request.GuestsCount.HasValue)
            {
                properties = properties.Where(p => p.MaxCapacity >= request.GuestsCount.Value).ToList();
            }

            // فلتر الحالة
            properties = properties.Where(p => p.IsActive && p.IsApproved).ToList();

            return properties;
        }

        /// <summary>
        /// تطبيق الترتيب على النتائج
        /// </summary>
        private List<PropertyIndexDocument> ApplySorting(
            List<PropertyIndexDocument> properties,
            string sortBy)
        {
            return sortBy?.ToLowerInvariant() switch
            {
                "price_asc" => properties.OrderBy(p => p.MinPrice).ToList(),
                "price_desc" => properties.OrderByDescending(p => p.MinPrice).ToList(),
                "rating" => properties.OrderByDescending(p => p.AverageRating)
                    .ThenByDescending(p => p.ReviewsCount).ToList(),
                "newest" => properties.OrderByDescending(p => p.CreatedAt).ToList(),
                "popularity" => properties.OrderByDescending(p => p.PopularityScore).ToList(),
                _ => properties.OrderByDescending(p => p.PopularityScore).ToList()
            };
        }

        /// <summary>
        /// تطبيق التقسيم على النتائج
        /// </summary>
        private List<PropertyIndexDocument> ApplyPaging(
            List<PropertyIndexDocument> properties,
            int pageNumber,
            int pageSize)
        {
            return properties
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToList();
        }

        /// <summary>
        /// بناء نتيجة البحث النهائية
        /// </summary>
        private PropertySearchResult BuildSearchResult(
            List<PropertyIndexDocument> properties,
            int totalCount,
            PropertySearchRequest request)
        {
            var items = properties.Select(p => new PropertySearchItem
            {
                Id = p.Id.ToString(),
                Name = p.Name,
                City = p.City,
                PropertyType = p.PropertyTypeName,
                MinPrice = p.MinPrice,
                Currency = p.BaseCurrency,
                AverageRating = p.AverageRating,
                StarRating = p.StarRating,
                ImageUrls = p.ImageUrls,
                MaxCapacity = p.MaxCapacity,
                UnitsCount = p.TotalUnits,
                Latitude = p.Latitude,
                Longitude = p.Longitude
            }).ToList();

            return new PropertySearchResult
            {
                Properties = items,
                TotalCount = totalCount,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = (int)Math.Ceiling((double)totalCount / request.PageSize)
            };
        }

        /// <summary>
        /// توليد مفتاح الكاش الفريد
        /// </summary>
        private string GenerateCacheKey(PropertySearchRequest request)
        {
            var key = $"search:{request.SearchText}:{request.City}:{request.PropertyType}:" +
                     $"{request.MinPrice}:{request.MaxPrice}:{request.MinRating}:" +
                     $"{request.GuestsCount}:{request.CheckIn?.Ticks}:{request.CheckOut?.Ticks}:" +
                     $"{request.PageNumber}:{request.PageSize}:{request.SortBy}";
            
            return Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(key));
        }

        /// <summary>
        /// تسجيل المقاييس
        /// </summary>
        private void RecordMetrics(long elapsedMs, bool fromCache, bool isError = false)
        {
            // تسجيل المقاييس للمراقبة
            _ = _db.StringIncrementAsync(RedisKeySchemas.STATS_SEARCH_COUNT);
            
            if (fromCache)
            {
                _ = _db.StringIncrementAsync("stats:cache:hits");
            }
            else
            {
                _ = _db.StringIncrementAsync("stats:cache:misses");
            }
            
            if (isError)
            {
                _ = _db.StringIncrementAsync(string.Format(RedisKeySchemas.STATS_ERRORS, "search"));
            }
            
            _ = _db.StringSetAsync($"stats:search:last_latency", elapsedMs);
        }

        /// <summary>
        /// تحليل نتائج RediSearch
        /// </summary>
        private PropertySearchResult ParseRediSearchResult(RedisResult result, PropertySearchRequest request)
        {
            // TODO: تنفيذ تحليل النتائج من RediSearch
            return new PropertySearchResult();
        }

        /// <summary>
        /// الحصول على Lua Script للفلترة المعقدة
        /// </summary>
        private string GetComplexFilterLuaScript()
        {
            // TODO: إضافة Lua Script للفلترة المعقدة
            return "";
        }

        /// <summary>
        /// بناء مفاتيح Lua Script
        /// </summary>
        private RedisKey[] BuildLuaScriptKeys(PropertySearchRequest request)
        {
            // TODO: بناء المفاتيح
            return new RedisKey[0];
        }

        /// <summary>
        /// بناء معطيات Lua Script
        /// </summary>
        private RedisValue[] BuildLuaScriptArgs(PropertySearchRequest request)
        {
            // TODO: بناء المعطيات
            return new RedisValue[0];
        }

        /// <summary>
        /// تحليل نتائج Lua Script
        /// </summary>
        private PropertySearchResult ParseLuaScriptResult(RedisResult result, PropertySearchRequest request)
        {
            // TODO: تحليل النتائج
            return new PropertySearchResult();
        }

        #endregion

        /// <summary>
        /// تعداد استراتيجيات البحث
        /// </summary>
        private enum SearchStrategy
        {
            TextSearch,     // بحث نصي
            GeoSearch,      // بحث جغرافي
            ComplexFilter,  // فلترة معقدة
            SimpleSearch    // بحث بسيط
        }
    }
}
