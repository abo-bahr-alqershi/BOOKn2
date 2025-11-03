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
using System.Text.Json;
using System.Text.RegularExpressions;
using YemenBooking.Infrastructure.Redis.Scripts;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Models;
using YemenBooking.Infrastructure.Redis.Cache;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Infrastructure.Redis.Search
{
    /// <summary>
    /// محرك البحث المحسن - الطبقة الثانية في النظام
    /// يحدد استراتيجية البحث المثلى وينفذها بكفاءة عالية
    /// </summary>
    public class OptimizedSearchEngine
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IPropertyRepository _propertyRepository;
        private readonly MultiLevelCache _cacheManager;
        private readonly ILogger<OptimizedSearchEngine> _logger;
        private readonly IMemoryCache _memoryCache;
        private IDatabase _db;
        private readonly SemaphoreSlim _searchLimiter;
        private readonly object _dbLock = new object();

        /// <summary>
        /// مُنشئ محرك البحث المحسن
        /// </summary>
        public OptimizedSearchEngine(
            IRedisConnectionManager redisManager,
            IPropertyRepository propertyRepository,
            MultiLevelCache cacheManager,
            ILogger<OptimizedSearchEngine> logger,
            IMemoryCache memoryCache)
        {
            _redisManager = redisManager;
            _propertyRepository = propertyRepository;
            _cacheManager = cacheManager;
            _logger = logger;
            _memoryCache = memoryCache;
            _db = null; // تأجيل تهيئة Database
            _searchLimiter = new SemaphoreSlim(50, 50); // حد أقصى 50 بحث متزامن
        }

        /// <summary>
        /// الحصول على مفتاح فهرس الترتيب المناسب
        /// </summary>
        private string GetSortIndexKey(string sortBy)
        {
            switch (sortBy?.ToLowerInvariant())
            {
                case "price_asc":
                case "price_desc":
                    return RedisKeySchemas.INDEX_PRICE;
                case "rating":
                    return RedisKeySchemas.INDEX_RATING;
                case "newest":
                    return RedisKeySchemas.INDEX_CREATED;
                case "popularity":
                default:
                    return RedisKeySchemas.INDEX_POPULARITY;
            }
        }

        private IDatabase GetDatabase()
        {
            if (_db != null)
                return _db;
                
            lock (_dbLock)
            {
                if (_db == null)
                {
                    _db = _redisManager.GetDatabase();
                }
            }
            return _db;
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

                // 1. التحقق من الكاش أولاً (مفتاح يعتمد على نسخة الفهرس)
                var cacheKey = await BuildCacheKeyAsync(request);
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

            // إذا كان هناك تواريخ، اعتبرها فلترة معقدة (لأن الإتاحة تعالج عبر Lua داخل Redis)
            if (request.CheckIn.HasValue && request.CheckOut.HasValue)
            {
                return SearchStrategy.ComplexFilter;
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

            // إذا وُجد تواريخ + فلتر سعر اعتبرها فلترة معقدة
            if ((request.MinPrice.HasValue || request.MaxPrice.HasValue) &&
                request.CheckIn.HasValue && request.CheckOut.HasValue)
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
                // التحقق من توفر RediSearch، وإلا فالتحويل للمسار اليدوي
                if (!await IsRediSearchAvailable())
                {
                    _logger.LogWarning("RediSearch غير متاح، التحويل للبحث اليدوي");
                    return await ExecuteManualTextSearchAsync(request, cancellationToken);
                }

                // بناء الاستعلام
                var query = BuildRediSearchQuery(request);
                var offset = (request.PageNumber - 1) * request.PageSize;

                // الحقول المطلوبة فقط لتقليل الحمولة
                var returnFields = new[]
                {
                    "id","name","city","property_type","min_price","currency",
                    "average_rating","star_rating","max_capacity","units_count","latitude","longitude"
                };

                var args = new List<object> { RedisKeySchemas.SEARCH_INDEX_NAME, query };
                args.Add("RETURN");
                args.Add(returnFields.Length);
                foreach (var f in returnFields) args.Add(f);

                // الترتيب
                AddSortingArgs(args, request.SortBy);

                // الصفحة
                args.AddRange(new object[] { "LIMIT", offset.ToString(), request.PageSize.ToString() });

                // المحاولة مع DIALECT 2 ثم fallback
                try
                {
                    var argsWithDialect = new List<object>(args) { "DIALECT", 2 };
                    var rr = await GetDatabase().ExecuteAsync("FT.SEARCH", argsWithDialect.ToArray());
                    var parsed = ParseRediSearchResult(rr, request);
                    if (parsed.TotalCount == 0)
                    {
                        _logger.LogDebug("FT.SEARCH أعاد 0 نتيجة، استخدام مسار البحث اليدوي كبديل");
                        return await ExecuteManualTextSearchAsync(request, cancellationToken);
                    }
                    return parsed;
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "FT.SEARCH مع DIALECT 2 فشل، محاولة بدون DIALECT");
                    try
                    {
                        var rr = await GetDatabase().ExecuteAsync("FT.SEARCH", args.ToArray());
                        var parsed = ParseRediSearchResult(rr, request);
                        if (parsed.TotalCount == 0)
                        {
                            _logger.LogDebug("FT.SEARCH أعاد 0 نتيجة (بدون DIALECT)، استخدام مسار البحث اليدوي كبديل");
                            return await ExecuteManualTextSearchAsync(request, cancellationToken);
                        }
                        return parsed;
                    }
                    catch (Exception ex2)
                    {
                        _logger.LogWarning(ex2, "FT.SEARCH غير متاح، استخدام البحث اليدوي كبديل");
                        return await ExecuteManualTextSearchAsync(request, cancellationToken);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في البحث النصي");
                throw;
            }
        }

        /// <summary>
        /// تنفيذ البحث الجغرافي باستخدام GeoRadius
        /// </summary>
        private async Task<PropertySearchResult> ExecuteGeoSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var geoKey = !string.IsNullOrWhiteSpace(request.City) 
                ? string.Format(RedisKeySchemas.GEO_CITY, request.City.ToLowerInvariant())
                : RedisKeySchemas.GEO_PROPERTIES;

            var geoResults = await GetDatabase().GeoRadiusAsync(
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

            var propertyIds = geoResults.Select(r => r.Member.ToString()).ToList();
            var properties = await GetPropertiesDetailsAsync(propertyIds);

            properties = ApplyFilters(properties, request);

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

            var result = await GetDatabase().ScriptEvaluateAsync(luaScript, keys, args);

            // تحليل النتائج: نأخذ معرّفات العقارات فقط، ثم نجلب تفاصيل الصفحة المطلوبة
            return await ParseLuaScriptResultAsync(result, request, cancellationToken);
        }

        /// <summary>
        /// تنفيذ البحث البسيط
        /// </summary>
        private async Task<PropertySearchResult> ExecuteSimpleSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            // تنفيذ الفلترة داخل Redis بالكامل عبر تقاطعات المجموعات وترتيب عبر الفهارس المرتبة
            var db = GetDatabase();

            // مفاتيح مؤقتة
            var opId = Guid.NewGuid().ToString("N");
            var tempBaseKey = string.Format(RedisKeySchemas.TEMP_OPERATION, "search:base", opId);
            var tempSortedKey = string.Format(RedisKeySchemas.TEMP_OPERATION, "search:sorted", opId);
            var tempPriceKey = string.Format(RedisKeySchemas.TEMP_OPERATION, "search:price", opId);
            var tempRatingKey = string.Format(RedisKeySchemas.TEMP_OPERATION, "search:rating", opId);
            var tempAdultsKey = string.Format(RedisKeySchemas.TEMP_OPERATION, "search:adults", opId);
            var tempChildrenKey = string.Format(RedisKeySchemas.TEMP_OPERATION, "search:children", opId);
            var tempCapacityKey = string.Format(RedisKeySchemas.TEMP_OPERATION, "search:capacity", opId);
            var tempCandidatesZKey = string.Format(RedisKeySchemas.TEMP_OPERATION, "search:candidates:z", opId);

            try
            {
                // 1) بناء قائمة مفاتيح الفلاتر (Sets)
                var filterKeys = new List<RedisKey>();
                // دائماً احصر النتائج بالعقارات النشطة والمعتمدة
                filterKeys.Add(RedisKeySchemas.PROPERTIES_ALL_SET);
                if (!string.IsNullOrWhiteSpace(request.City))
                {
                    filterKeys.Add(RedisKeySchemas.GetCityKey(request.City));
                }

                if (!string.IsNullOrWhiteSpace(request.PropertyType))
                {
                    if (Guid.TryParse(request.PropertyType, out var typeGuid))
                    {
                        filterKeys.Add(RedisKeySchemas.GetTypeKey(typeGuid));
                    }
                    else
                    {
                        var typeKeyByName = string.Format(RedisKeySchemas.TAG_TYPE, request.PropertyType.ToLowerInvariant());
                        filterKeys.Add(typeKeyByName);
                    }
                }

                if (request.RequiredAmenityIds?.Any() == true)
                {
                    foreach (var amenityId in request.RequiredAmenityIds)
                    {
                        if (Guid.TryParse(amenityId, out var amenityGuid))
                        {
                            filterKeys.Add(RedisKeySchemas.GetAmenityKey(amenityGuid));
                        }
                    }
                }

                if (request.DynamicFieldFilters?.Any() == true)
                {
                    foreach (var kv in request.DynamicFieldFilters)
                    {
                        var field = kv.Key;
                        var val = kv.Value?.ToString();
                        if (!string.IsNullOrWhiteSpace(field) && !string.IsNullOrWhiteSpace(val))
                        {
                            filterKeys.Add(RedisKeySchemas.GetDynamicFieldValueKey(field, val));
                        }
                    }
                }

                // 2) إنشاء مجموعة المرشحين SINTERSTORE
                if (filterKeys.Count == 1)
                {
                    // نسخ إلى مفتاح مؤقت لضمان عدم تعديل المصدر
                    await db.ExecuteAsync("SUNIONSTORE", tempBaseKey, filterKeys[0]);
                }
                else
                {
                    var interArgs = new List<object> { tempBaseKey };
                    interArgs.AddRange(filterKeys.Select(k => (object)k));
                    await db.ExecuteAsync("SINTERSTORE", interArgs.ToArray());
                }

                // TTL للمفاتيح المؤقتة
                _ = db.KeyExpireAsync(tempBaseKey, TimeSpan.FromMinutes(2));

                // في حال عدم وجود مرشحين
                var candidatesCount = await db.SetLengthAsync(tempBaseKey);
                if (candidatesCount == 0)
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

                // 3) تحويل المرشحين (Set) إلى مجموعة مرتبة مؤقتة (ZSet) عبر SMEMBERS + ZADD بدرجة 0
                var candidateMembers = await db.SetMembersAsync(tempBaseKey);
                if (candidateMembers.Length > 0)
                {
                    var batch = db.CreateBatch();
                    foreach (var member in candidateMembers)
                    {
                        _ = batch.SortedSetAddAsync(tempCandidatesZKey, member, 0);
                    }
                    batch.Execute();
                }

                _ = db.KeyExpireAsync(tempCandidatesZKey, TimeSpan.FromMinutes(2));

                // تقاطع المجموعة المرتبة للترتيب مع المرشحين
                var sortIndex = GetSortIndexKey(request.SortBy);
                await db.ExecuteAsync(
                    "ZINTERSTORE",
                    tempSortedKey,
                    2,
                    sortIndex,
                    tempCandidatesZKey,
                    "WEIGHTS", 1, 0);
                _ = db.KeyExpireAsync(tempSortedKey, TimeSpan.FromMinutes(2));

                // 4) تطبيق فلاتر رقمية اختيارية مع الحفاظ على ترتيب sortIndex
                // فلتر السعر
                if (request.MinPrice.HasValue || request.MaxPrice.HasValue)
                {
                    var min = request.MinPrice ?? 0;
                    var max = request.MaxPrice ?? decimal.MaxValue;

                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempPriceKey,
                        2,
                        RedisKeySchemas.INDEX_PRICE,
                        tempCandidatesZKey,
                        "WEIGHTS", 1, 0);
                    _ = db.KeyExpireAsync(tempPriceKey, TimeSpan.FromMinutes(2));

                    // إزالة ما هو خارج النطاق
                    await db.SortedSetRemoveRangeByScoreAsync(tempPriceKey, double.NegativeInfinity, (double)min - double.Epsilon);
                    await db.SortedSetRemoveRangeByScoreAsync(tempPriceKey, (double)max + double.Epsilon, double.PositiveInfinity);

                    // تقاطع مع مجموعة الترتيب الحالية مع الحفاظ على الدرجات من tempSortedKey
                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempSortedKey,
                        2,
                        tempSortedKey,
                        tempPriceKey,
                        "WEIGHTS", 1, 0);
                }

                // فلتر التقييم الأدنى
                if (request.MinRating.HasValue)
                {
                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempRatingKey,
                        2,
                        RedisKeySchemas.INDEX_RATING,
                        tempCandidatesZKey,
                        "WEIGHTS", 1, 0);
                    _ = db.KeyExpireAsync(tempRatingKey, TimeSpan.FromMinutes(2));

                    await db.SortedSetRemoveRangeByScoreAsync(tempRatingKey, double.NegativeInfinity, (double)request.MinRating.Value - double.Epsilon);

                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempSortedKey,
                        2,
                        tempSortedKey,
                        tempRatingKey,
                        "WEIGHTS", 1, 0);
                }

                // فلتر الحد الأدنى للبالغين
                if (request.MinAdults.HasValue && request.MinAdults.Value > 0)
                {
                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempAdultsKey,
                        2,
                        RedisKeySchemas.INDEX_MAX_ADULTS,
                        tempCandidatesZKey,
                        "WEIGHTS", 1, 0);
                    _ = db.KeyExpireAsync(tempAdultsKey, TimeSpan.FromMinutes(2));
                    await db.SortedSetRemoveRangeByScoreAsync(tempAdultsKey, double.NegativeInfinity, request.MinAdults.Value - double.Epsilon);
                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempSortedKey,
                        2,
                        tempSortedKey,
                        tempAdultsKey,
                        "WEIGHTS", 1, 0);
                }

                // فلتر الحد الأدنى للأطفال
                if (request.MinChildren.HasValue && request.MinChildren.Value > 0)
                {
                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempChildrenKey,
                        2,
                        RedisKeySchemas.INDEX_MAX_CHILDREN,
                        tempCandidatesZKey,
                        "WEIGHTS", 1, 0);
                    _ = db.KeyExpireAsync(tempChildrenKey, TimeSpan.FromMinutes(2));
                    await db.SortedSetRemoveRangeByScoreAsync(tempChildrenKey, double.NegativeInfinity, request.MinChildren.Value - double.Epsilon);
                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempSortedKey,
                        2,
                        tempSortedKey,
                        tempChildrenKey,
                        "WEIGHTS", 1, 0);
                }

                // فلتر السعة العامة (GuestsCount)
                if (request.GuestsCount.HasValue && request.GuestsCount.Value > 0)
                {
                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempCapacityKey,
                        2,
                        RedisKeySchemas.INDEX_MAX_CAPACITY,
                        tempCandidatesZKey,
                        "WEIGHTS", 1, 0);
                    _ = db.KeyExpireAsync(tempCapacityKey, TimeSpan.FromMinutes(2));

                    await db.SortedSetRemoveRangeByScoreAsync(
                        tempCapacityKey,
                        double.NegativeInfinity,
                        request.GuestsCount.Value - double.Epsilon);

                    await db.ExecuteAsync(
                        "ZINTERSTORE",
                        tempSortedKey,
                        2,
                        tempSortedKey,
                        tempCapacityKey,
                        "WEIGHTS", 1, 0);
                }

                // 5) قراءة صفحة النتائج من المجموعة المرتبة
                var start = (request.PageNumber - 1) * request.PageSize;
                var stop = start + request.PageSize - 1;

                var sortLower = request.SortBy?.ToLowerInvariant();
                var descending = sortLower == "price_desc" || sortLower == "rating" || sortLower == "newest" || sortLower == "popularity";

                RedisValue[] pageMembers = descending
                    ? await db.SortedSetRangeByRankAsync(tempSortedKey, start, stop, Order.Descending)
                    : await db.SortedSetRangeByRankAsync(tempSortedKey, start, stop, Order.Ascending);

                var total = (int)await db.SortedSetLengthAsync(tempSortedKey);

                var pageIds = pageMembers.Select(v => v.ToString()).Where(s => !string.IsNullOrEmpty(s)).ToList();

                var pageDocs = await GetPropertiesDetailsAsync(pageIds);
                return BuildSearchResult(pageDocs, total, request);
            }
            finally
            {
                // تنظيف المفاتيح المؤقتة
                try
                {
                    var cleanup = new List<Task>
                    {
                        db.KeyDeleteAsync(tempBaseKey),
                        db.KeyDeleteAsync(tempSortedKey),
                        db.KeyDeleteAsync(tempPriceKey),
                        db.KeyDeleteAsync(tempRatingKey),
                        db.KeyDeleteAsync(tempCapacityKey),
                        db.KeyDeleteAsync(tempCandidatesZKey),
                        db.KeyDeleteAsync(tempAdultsKey),
                        db.KeyDeleteAsync(tempChildrenKey)
                    };
                    await Task.WhenAll(cleanup);
                }
                catch { /* تجاهل أخطاء التنظيف */ }
            }
        }

        /// <summary>
        /// البحث النصي اليدوي (عندما RediSearch غير متاح)
        /// </summary>
        private async Task<PropertySearchResult> ExecuteManualTextSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var searchText = request.SearchText?.ToLowerInvariant();
            var tokens = BuildPlainTokens(searchText);
            var allProperties = await GetDatabase().SetMembersAsync(RedisKeySchemas.PROPERTIES_ALL_SET);
            var matchedProperties = new List<PropertyIndexDocument>();

            foreach (var propertyId in allProperties)
            {
                var propertyKey = RedisKeySchemas.GetPropertyKey(Guid.Parse(propertyId));
                var propertyData = await GetDatabase().HashGetAllAsync(propertyKey);
                
                if (propertyData.Length == 0) continue;
                
                var doc = PropertyIndexDocument.FromHashEntries(propertyData);
                
                // بحث في الاسم والوصف عبر التوكينات لتجاوز الفواصل/التطويل
                bool textMatch = false;
                if (tokens.Count == 0)
                {
                    textMatch = string.IsNullOrWhiteSpace(searchText);
                }
                else
                {
                    foreach (var tk in tokens)
                    {
                        if (doc.NameNormalized?.Contains(tk) == true ||
                            doc.Description?.ToLowerInvariant().Contains(tk) == true ||
                            doc.City?.ToLowerInvariant().Contains(tk) == true)
                        {
                            textMatch = true;
                            break;
                        }
                    }
                }

                if (textMatch)
                {
                    matchedProperties.Add(doc);
                }
                
                // البحث في الحقول الديناميكية أيضاً
                if (doc.DynamicFields != null)
                {
                    foreach (var field in doc.DynamicFields.Values)
                    {
                        if (string.IsNullOrWhiteSpace(field)) continue;
                        var fval = field.ToLowerInvariant();
                        foreach (var tk in tokens)
                        {
                            if (fval.Contains(tk))
                            {
                                matchedProperties.Add(doc);
                                goto AddedDoc;
                            }
                        }
                    }
                }
            AddedDoc:
                ;
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
                var db = GetDatabase();
                var marker = await db.StringGetAsync("search:module:available");
                if (marker == "1") return true;

                // Probe using FT.INFO to detect availability even if marker missing
                try
                {
                    var info = await db.ExecuteAsync("FT.INFO", RedisKeySchemas.SEARCH_INDEX_NAME);
                    if (!info.IsNull)
                    {
                        await db.StringSetAsync("search:module:available", "1");
                        return true;
                    }
                }
                catch
                {
                    // ignore and set unavailable
                }

                await db.StringSetAsync("search:module:available", "0");
                return false;
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
                var escaped = PrepareSearchTokens(request.SearchText);
                if (!string.IsNullOrWhiteSpace(escaped))
                {
                    queryParts.Add($"(@name:({escaped}) | @description:({escaped}) | @dynamic_fields:({escaped}))");
                }
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

            // حد أدنى للبالغين/الأطفال
            if (request.MinAdults.HasValue && request.MinAdults.Value > 0)
            {
                queryParts.Add($"@max_adults:[{request.MinAdults.Value} +inf]");
            }
            if (request.MinChildren.HasValue && request.MinChildren.Value > 0)
            {
                queryParts.Add($"@max_children:[{request.MinChildren.Value} +inf]");
            }

            // حد أدنى للسعة العامة
            if (request.GuestsCount.HasValue && request.GuestsCount.Value > 0)
            {
                queryParts.Add($"@max_capacity:[{request.GuestsCount.Value} +inf]");
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
            var batch = GetDatabase().CreateBatch();
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
            // دائماً فلتر بحسب حالة النشاط والاعتماد
            properties = properties.Where(p => p.IsActive && p.IsApproved).ToList();

            // فلتر نوع العقار - مهم جداً
            if (!string.IsNullOrWhiteSpace(request.PropertyType))
            {
                _logger.LogInformation("🔍 تطبيق فلتر نوع العقار: {PropertyType}", request.PropertyType);
                
                // محاولة التحليل كـ GUID (معرف نوع العقار)
                if (Guid.TryParse(request.PropertyType, out var propertyTypeId))
                {
                    properties = properties.Where(p => p.PropertyTypeId == propertyTypeId).ToList();
                    _logger.LogInformation("✅ تم فلترة {Count} عقار بنوع: {TypeId}", properties.Count, propertyTypeId);
                }
                else
                {
                    // البحث بالاسم النصي
                    properties = properties.Where(p => 
                        string.Equals(p.PropertyTypeName, request.PropertyType, StringComparison.OrdinalIgnoreCase)
                    ).ToList();
                    _logger.LogInformation("✅ تم فلترة {Count} عقار بنوع: {TypeName}", properties.Count, request.PropertyType);
                }
            }

            // فلتر نوع الوحدة
            if (!string.IsNullOrWhiteSpace(request.UnitTypeId))
            {
                _logger.LogInformation("🔍 تطبيق فلتر نوع الوحدة: {UnitTypeId}", request.UnitTypeId);
                
                if (Guid.TryParse(request.UnitTypeId, out var unitTypeId))
                {
                    properties = properties.Where(p => 
                        p.UnitTypeIds != null && p.UnitTypeIds.Contains(unitTypeId)
                    ).ToList();
                    _logger.LogInformation("✅ تم فلترة {Count} عقار بنوع الوحدة", properties.Count);
                }
            }

            // فلتر السعر
            if (request.MinPrice.HasValue)
            {
                _logger.LogInformation("🔍 تطبيق فلتر السعر الأدنى: {MinPrice}", request.MinPrice.Value);
                properties = properties.Where(p => p.MinPrice >= request.MinPrice.Value).ToList();
                _logger.LogInformation("✅ تبقى {Count} عقار بعد فلتر السعر الأدنى", properties.Count);
            }

            if (request.MaxPrice.HasValue)
            {
                _logger.LogInformation("🔍 تطبيق فلتر السعر الأقصى: {MaxPrice}", request.MaxPrice.Value);
                properties = properties.Where(p => p.MinPrice <= request.MaxPrice.Value).ToList();
                _logger.LogInformation("✅ تبقى {Count} عقار بعد فلتر السعر الأقصى", properties.Count);
            }

            // فلتر التقييم
            if (request.MinRating.HasValue)
            {
                _logger.LogInformation("🔍 تطبيق فلتر التقييم: {MinRating}", request.MinRating.Value);
                properties = properties.Where(p => p.AverageRating >= request.MinRating.Value).ToList();
                _logger.LogInformation("✅ تبقى {Count} عقار بعد فلتر التقييم", properties.Count);
            }

            // فلتر السعة
            if (request.GuestsCount.HasValue)
            {
                _logger.LogInformation("🔍 تطبيق فلتر عدد الضيوف: {GuestsCount}", request.GuestsCount.Value);
                properties = properties.Where(p => p.MaxCapacity >= request.GuestsCount.Value).ToList();
                _logger.LogInformation("✅ تبقى {Count} عقار بعد فلتر عدد الضيوف", properties.Count);
            }

            // فلتر المرافق
            if (request.RequiredAmenityIds?.Any() == true)
            {
                _logger.LogInformation("🔍 تطبيق فلتر المرافق: {Count} مرفق", request.RequiredAmenityIds.Count);
                
                foreach (var amenityId in request.RequiredAmenityIds)
                {
                    if (Guid.TryParse(amenityId, out var amenityGuid))
                    {
                        properties = properties.Where(p => 
                            p.AmenityIds != null && p.AmenityIds.Contains(amenityGuid)
                        ).ToList();
                    }
                }
                _logger.LogInformation("✅ تبقى {Count} عقار بعد فلتر المرافق", properties.Count);
            }

            // فلتر الخدمات
            if (request.ServiceIds?.Any() == true)
            {
                _logger.LogInformation("🔍 تطبيق فلتر الخدمات: {Count} خدمة", request.ServiceIds.Count);
                
                foreach (var serviceId in request.ServiceIds)
                {
                    if (Guid.TryParse(serviceId, out var serviceGuid))
                    {
                        properties = properties.Where(p => 
                            p.ServiceIds != null && p.ServiceIds.Contains(serviceGuid)
                        ).ToList();
                    }
                }
                _logger.LogInformation("✅ تبقى {Count} عقار بعد فلتر الخدمات", properties.Count);
            }

            // فلتر الحقول الديناميكية
            if (request.DynamicFieldFilters?.Any() == true)
            {
                _logger.LogInformation("🔍 تطبيق فلاتر الحقول الديناميكية: {Count} حقل", request.DynamicFieldFilters.Count);
                
                foreach (var filter in request.DynamicFieldFilters)
                {
                    var fieldName = filter.Key;
                    var fieldValue = filter.Value?.ToString();
                    
                    if (!string.IsNullOrWhiteSpace(fieldValue))
                    {
                        properties = properties.Where(p =>
                            p.DynamicFields != null &&
                            p.DynamicFields.ContainsKey(fieldName) &&
                            string.Equals(p.DynamicFields[fieldName], fieldValue, StringComparison.OrdinalIgnoreCase)
                        ).ToList();
                    }
                }
                _logger.LogInformation("✅ تبقى {Count} عقار بعد فلاتر الحقول الديناميكية", properties.Count);
            }

            // فلتر التواريخ والإتاحة
            if (request.CheckIn.HasValue && request.CheckOut.HasValue)
            {
                _logger.LogInformation("🔍 تطبيق فلتر الإتاحة: {CheckIn} - {CheckOut}", 
                    request.CheckIn.Value.ToString("yyyy-MM-dd"), 
                    request.CheckOut.Value.ToString("yyyy-MM-dd"));
                
                // مؤقتاً: نعرض فقط العقارات المتاحة
                // في المستقبل، سيتم التحقق من الإتاحة الفعلية للتواريخ المحددة
                var beforeAvailability = properties.Count;
                
                // نفلتر العقارات غير المتاحة بالكامل
                properties = properties.Where(p => 
                    p.IsActive && // العقار نشط
                    p.TotalUnits > 0 // لديه وحدات
                ).ToList();
                
                if (beforeAvailability != properties.Count)
                {
                    _logger.LogInformation("✅ تم فلتر {Count} عقار غير متاح", 
                        beforeAvailability - properties.Count);
                }
            }

            // فلتر الحالة - يجب أن يكون دائماً في النهاية
            var beforeStatusFilter = properties.Count;
            properties = properties.Where(p => p.IsActive && p.IsApproved).ToList();
            
            if (beforeStatusFilter != properties.Count)
            {
                _logger.LogInformation("⚠️ تم استبعاد {Count} عقار غير نشط أو غير معتمد", 
                    beforeStatusFilter - properties.Count);
            }

            _logger.LogInformation("📊 النتيجة النهائية بعد الفلترة: {Count} عقار", properties.Count);

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
        private async Task<string> BuildCacheKeyAsync(PropertySearchRequest request)
        {
            // قراءة نسخة الفهرس الحالية من Redis لضمان عدم إعادة استخدام نتائج قديمة
            string version = "0";
            try
            {
                var v = await GetDatabase().StringGetAsync("search:version");
                if (v.HasValue) version = v.ToString();
            }
            catch { /* تجاهل أخطاء القراءة من Redis */ }

            var key = $"search:{request.SearchText}:{request.City}:{request.PropertyType}:" +
                     $"{request.MinPrice}:{request.MaxPrice}:{request.MinRating}:" +
                     $"{request.GuestsCount}:{request.CheckIn?.Ticks}:{request.CheckOut?.Ticks}:" +
                     $"{request.PageNumber}:{request.PageSize}:{request.SortBy}:v={version}";

            return Convert.ToBase64String(System.Text.Encoding.UTF8.GetBytes(key));
        }

        /// <summary>
        /// تسجيل المقاييس
        /// </summary>
        private void RecordMetrics(long elapsedMs, bool fromCache, bool isError = false)
        {
            // تسجيل المقاييس للمراقبة
            var db = GetDatabase();
            _ = db.StringIncrementAsync(RedisKeySchemas.STATS_SEARCH_COUNT);
            
            if (fromCache)
            {
                _ = db.StringIncrementAsync("stats:cache:hits");
            }
            else
            {
                _ = db.StringIncrementAsync("stats:cache:misses");
            }
            
            if (isError)
            {
                _ = db.StringIncrementAsync(string.Format(RedisKeySchemas.STATS_ERRORS, "search"));
            }
            
            _ = db.StringSetAsync($"stats:search:last_latency", elapsedMs);
        }

        /// <summary>
        /// تحليل نتائج RediSearch
        /// </summary>
        private PropertySearchResult ParseRediSearchResult(RedisResult result, PropertySearchRequest request)
        {
            try
            {
                var arr = (RedisResult[])result;
                if (arr == null || arr.Length == 0)
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

                var total = (int)arr[0];
                var items = new List<PropertySearchItem>();

                for (int i = 1; i < arr.Length; i += 2)
                {
                    var key = (string)arr[i];
                    if (i + 1 >= arr.Length) break;
                    var fieldsArr = (RedisResult[])arr[i + 1];
                    if (fieldsArr == null || fieldsArr.Length == 0) continue;

                    var dict = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
                    for (int j = 0; j + 1 < fieldsArr.Length; j += 2)
                    {
                        var fname = (string)fieldsArr[j];
                        var fval = (string)fieldsArr[j + 1];
                        dict[fname] = fval;
                    }

                    // بناء عنصر النتيجة مباشرة
                    var item = new PropertySearchItem
                    {
                        Id = dict.GetValueOrDefault("id", key.Replace("property:", string.Empty)),
                        Name = dict.GetValueOrDefault("name", string.Empty),
                        City = dict.GetValueOrDefault("city", string.Empty),
                        PropertyType = dict.GetValueOrDefault("property_type", string.Empty),
                        MinPrice = decimal.TryParse(dict.GetValueOrDefault("min_price", "0"), out var mp) ? mp : 0,
                        Currency = dict.GetValueOrDefault("currency", "YER"),
                        AverageRating = decimal.TryParse(dict.GetValueOrDefault("average_rating", "0"), out var ar) ? ar : 0,
                        StarRating = int.TryParse(dict.GetValueOrDefault("star_rating", "0"), out var sr) ? sr : 0,
                        ImageUrls = new List<string>(),
                        MaxCapacity = int.TryParse(dict.GetValueOrDefault("max_capacity", "0"), out var mc) ? mc : 0,
                        UnitsCount = int.TryParse(dict.GetValueOrDefault("units_count", "0"), out var uc) ? uc : 0,
                        DynamicFields = new Dictionary<string, string>(),
                        Latitude = double.TryParse(dict.GetValueOrDefault("latitude", "0"), out var lat) ? lat : 0,
                        Longitude = double.TryParse(dict.GetValueOrDefault("longitude", "0"), out var lon) ? lon : 0
                    };
                    items.Add(item);
                }

                return new PropertySearchResult
                {
                    Properties = items,
                    TotalCount = total,
                    PageNumber = request.PageNumber,
                    PageSize = request.PageSize,
                    TotalPages = (int)Math.Ceiling((double)total / request.PageSize)
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "فشل تحليل نتائج RediSearch");
                return new PropertySearchResult
                {
                    Properties = new List<PropertySearchItem>(),
                    TotalCount = 0,
                    PageNumber = request.PageNumber,
                    PageSize = request.PageSize,
                    TotalPages = 0
                };
            }
        }

        /// <summary>
        /// تجهيز كلمات البحث مع الهروب والتحويل إلى بادئات (prefix) لاستخدامها في RediSearch
        /// </summary>
        private string PrepareSearchTokens(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return string.Empty;
            // احتفظ بالأحرف العربية واللاتينية والأرقام وحول الباقي لمسافات
            var lowered = text.ToLowerInvariant().Replace("\u0640", string.Empty); // إزالة التطويل العربي
            var normalized = Regex.Replace(lowered, @"[^\p{L}\p{N}]+", " ");
            var tokens = normalized.Split(' ', StringSplitOptions.RemoveEmptyEntries)
                .Select(t => t + "*")
                .ToList();
            return string.Join("|", tokens);
        }

        /// <summary>
        /// بناء توكينات نصية بسيطة بدون wildcard لاستخدامها في البحث اليدوي
        /// </summary>
        private List<string> BuildPlainTokens(string text)
        {
            if (string.IsNullOrWhiteSpace(text)) return new List<string>();
            var normalized = Regex.Replace(text.ToLowerInvariant(), @"[^\p{L}\p{N}]+", " ");
            return normalized.Split(' ', StringSplitOptions.RemoveEmptyEntries)
                .Distinct()
                .ToList();
        }

        /// <summary>
        /// الحصول على Lua Script للفلترة المعقدة
        /// </summary>
        private string GetComplexFilterLuaScript()
        {
            // استخدام السكربت الجاهز في الطبقة Scripts
            return LuaScripts.COMPLEX_SEARCH_SCRIPT;
        }

        /// <summary>
        /// بناء مفاتيح Lua Script
        /// </summary>
        private RedisKey[] BuildLuaScriptKeys(PropertySearchRequest request)
        {
            // هذا السكربت لا يعتمد على KEYS صريحة بل يستخدم مفاتيح ثابتة
            return Array.Empty<RedisKey>();
        }

        /// <summary>
        /// بناء معطيات Lua Script
        /// </summary>
        private RedisValue[] BuildLuaScriptArgs(PropertySearchRequest request)
        {
            var searchText = request.SearchText ?? string.Empty;
            var city = request.City ?? string.Empty;

            // السكربت يتوقع معرف نوع العقار (GUID) فقط
            var propertyTypeArg = Guid.TryParse(request.PropertyType, out var typeGuid)
                ? typeGuid.ToString()
                : string.Empty;

            var minPrice = request.MinPrice?.ToString() ?? "0";
            var maxPrice = request.MaxPrice?.ToString() ?? decimal.MaxValue.ToString();
            var minRating = request.MinRating?.ToString() ?? "0";
            var guests = request.GuestsCount?.ToString() ?? "0";
            var checkIn = request.CheckIn?.Ticks.ToString() ?? string.Empty;
            var checkOut = request.CheckOut?.Ticks.ToString() ?? string.Empty;
            var sortBy = request.SortBy ?? "popularity";
            var pageNumber = request.PageNumber.ToString();
            var pageSize = request.PageSize.ToString();

            var amenityIds = request.RequiredAmenityIds?.ToList() ?? new List<string>();
            var amenityJson = JsonSerializer.Serialize(amenityIds);
            var preferredCurrency = request.PreferredCurrency ?? string.Empty;

            return new RedisValue[]
            {
                searchText,
                city,
                propertyTypeArg,
                minPrice,
                maxPrice,
                minRating,
                guests,
                checkIn,
                checkOut,
                sortBy,
                pageNumber,
                pageSize,
                amenityJson,
                preferredCurrency
            };
        }

        /// <summary>
        /// تحليل نتائج Lua Script
        /// </summary>
        private async Task<PropertySearchResult> ParseLuaScriptResultAsync(
            RedisResult result,
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            try
            {
                var json = (string)result;
                if (string.IsNullOrWhiteSpace(json))
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

                using var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;
                var total = root.GetProperty("total_count").GetInt32();
                var results = root.GetProperty("results");
                var ids = new List<string>();

                foreach (var item in results.EnumerateArray())
                {
                    if (item.ValueKind == JsonValueKind.Array && item.GetArrayLength() >= 1)
                    {
                        var id = item[0].GetString();
                        if (!string.IsNullOrWhiteSpace(id)) ids.Add(id);
                    }
                }

                var docs = await GetPropertiesDetailsAsync(ids);
                return BuildSearchResult(docs, total, request);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحليل نتيجة Lua Script");
                return new PropertySearchResult
                {
                    Properties = new List<PropertySearchItem>(),
                    TotalCount = 0,
                    PageNumber = request.PageNumber,
                    PageSize = request.PageSize,
                    TotalPages = 0
                };
            }
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
