// RedisIndexingService.cs
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using MessagePack;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Indexing.Models;
using YemenBooking.Core.Indexing.Models;
using System.Diagnostics;
using System.Text;
using MessagePack.Resolvers;
using System.Globalization;
using Microsoft.Extensions.Caching.Memory;
using System.Collections.Concurrent;
using YemenBooking.Infrastructure.Observability;
using YemenBooking.Infrastructure.Caching;

namespace YemenBooking.Infrastructure.Services
{
    public class RedisIndexingService : IIndexingService
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUnitRepository _unitRepository;
        private readonly IAvailabilityService _availabilityService;
        private readonly IPricingService _pricingService;
        private readonly IUnitFieldValueRepository _unitFieldValueRepository;
        private readonly IUnitTypeFieldRepository _unitTypeFieldRepository;
        private readonly ICurrencyExchangeRepository _currencyExchangeRepository;
        private readonly ILogger<RedisIndexingService> _logger;
        private readonly SemaphoreSlim _writeLimiter = new(5, 5);
        private readonly SemaphoreSlim _searchLimiter = new(50, 50);
        private readonly IMemoryCache _memoryCache;
        private readonly IDatabase _db;
        private readonly IPropertySearchService _searchService;
        private readonly IPropertyIndexingService _propertyIndexingService;
        private readonly IUnitIndexingService _unitIndexingService;
        private readonly IPriceCacheService _priceCacheService;

        // Redis Keys Prefixes
        private const string PROPERTY_KEY = "property:";
        private const string PROPERTY_SET = "properties:all";
        private const string CITY_SET = "city:";
        private const string TYPE_SET = "type:";
        private const string AMENITY_SET = "amenity:";
        private const string SERVICE_SET = "service:";
        private const string PRICE_SORTED_SET = "properties:by_price";
        private const string RATING_SORTED_SET = "properties:by_rating";
        private const string CREATED_SORTED_SET = "properties:by_created";
        private const string BOOKING_SORTED_SET = "properties:by_bookings";
        private const string GEO_KEY = "properties:geo";
        private const string AVAILABILITY_KEY = "availability:";
        private const string PRICING_KEY = "pricing:";
        private const string SEARCH_INDEX = "idx:properties";
        private const string DYNAMIC_FIELD_KEY = "dynamic:";
        private const string UNIT_KEY = "unit:";
        private const string PROPERTY_UNITS_SET = "property:units:";

        public RedisIndexingService(
            IRedisConnectionManager redisManager,
            IPropertyRepository propertyRepository,
            IUnitRepository unitRepository,
            IAvailabilityService availabilityService,
            IPricingService pricingService,
            ICurrencyExchangeRepository currencyExchangeRepository,
            IUnitFieldValueRepository unitFieldValueRepository,
            IUnitTypeFieldRepository unitTypeFieldRepository,
            ILogger<RedisIndexingService> logger,
            IMemoryCache memoryCache,
            IPropertySearchService searchService,
            IPropertyIndexingService propertyIndexingService,
            IUnitIndexingService unitIndexingService,
            IPriceCacheService priceCacheService)
        {
            _redisManager = redisManager;
            _propertyRepository = propertyRepository;
            _unitRepository = unitRepository;
            _availabilityService = availabilityService;
            _pricingService = pricingService;
            _currencyExchangeRepository = currencyExchangeRepository;
            _unitFieldValueRepository = unitFieldValueRepository;
            _unitTypeFieldRepository = unitTypeFieldRepository;
            _logger = logger;
            _memoryCache = memoryCache;
            _db = _redisManager.GetDatabase();
            _searchService = searchService;
            _propertyIndexingService = propertyIndexingService;
            _unitIndexingService = unitIndexingService;
            _priceCacheService = priceCacheService;

        }

        

        #region Initialization

        private void InitializeRedisIndexes()
        {
            try
            {
                // إنشاء فهارس Redis Search إذا كانت متاحة
                CreateSearchIndexes();
                _logger.LogInformation("تم تهيئة فهارس Redis بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Redis Search غير متاح، سيتم استخدام الفهرسة اليدوية");
            }
        }

        private void CreateSearchIndexes()
        {
            // إنشاء فهرس RediSearch للبحث المتقدم (يتطلب RediSearch module)
            try
            {
                var cmdInfo = _db.Execute("COMMAND", "INFO", "FT.CREATE");
                if (cmdInfo.IsNull)
                {
                    _logger.LogDebug("CreateSearchIndexes: FT.CREATE command not available");
                    // علّم أن RediSearch غير متاح لتجنّب FT.INFO لاحقاً
                    _db.StringSet("search:module:available", "0");
                    return;
                }

                // إذا كان الفهرس موجوداً فلا داعي لإعادة إنشائه
                try
                {
                    var info = _db.Execute("FT.INFO", "idx:properties");
                    if (!info.IsNull)
                    {
                        _logger.LogInformation("فهرس RediSearch موجود مسبقاً: idx:properties");
                        _db.StringSet("search:module:available", "1");
                        return;
                    }
                }
                catch
                {
                    // FT.INFO سيلقي استثناء إذا لم يوجد الفهرس -> سنقوم بإنشائه
                }

                // إنشاء الفهرس الجديد
                _db.Execute("FT.CREATE", "idx:properties", 
                    "ON", "HASH", 
                    "PREFIX", "1", "property:", 
                    "SCHEMA", 
                    "name", "TEXT", "WEIGHT", "5.0", "SORTABLE",
                    "name_lower", "TEXT",
                    "description", "TEXT", "WEIGHT", "2.0",
                    "city", "TAG", "SORTABLE",
                    "property_type", "TAG", "SORTABLE",
                    "min_price", "NUMERIC", "SORTABLE",
                    "max_price", "NUMERIC", "SORTABLE",
                    "average_rating", "NUMERIC", "SORTABLE",
                    "reviews_count", "NUMERIC", "SORTABLE",
                    "booking_count", "NUMERIC", "SORTABLE",
                    "max_capacity", "NUMERIC", "SORTABLE",
                    "is_active", "TAG",
                    "is_approved", "TAG",
                    "is_featured", "TAG",
                    "created_at", "NUMERIC", "SORTABLE",
                    "updated_at", "NUMERIC", "SORTABLE",
                    "latitude", "NUMERIC",
                    "longitude", "NUMERIC"
                );
                
                _logger.LogInformation("تم إنشاء فهرس RediSearch بنجاح: idx:properties");
                _db.StringSet("search:module:available", "1");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل إنشاء فهرس RediSearch - سيتم استخدام البحث اليدوي");
                try { _db.StringSet("search:module:available", "0"); } catch {}
            }
        }

        #endregion

        #region Property CRUD Operations

        public async Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                await _propertyIndexingService.OnPropertyCreatedAsync(propertyId, cancellationToken);
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        public async Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                await _propertyIndexingService.OnPropertyUpdatedAsync(propertyId, cancellationToken);
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        public async Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                await _propertyIndexingService.OnPropertyDeletedAsync(propertyId, cancellationToken);
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        #endregion

        #region Unit Operations

        public async Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                await _unitIndexingService.OnUnitCreatedAsync(unitId, propertyId, cancellationToken);
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        public async Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                await _unitIndexingService.OnUnitUpdatedAsync(unitId, propertyId, cancellationToken);
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        public async Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                await _unitIndexingService.OnUnitDeletedAsync(unitId, propertyId, cancellationToken);
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        #endregion

        #region Availability & Pricing

        public async Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId,
            List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                await _unitIndexingService.OnAvailabilityChangedAsync(unitId, propertyId, availableRanges, cancellationToken);
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        public async Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId,
            List<PricingRule> pricingRules, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                await _unitIndexingService.OnPricingRuleChangedAsync(unitId, propertyId, pricingRules, cancellationToken);
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        #endregion

        #region Dynamic Fields

        public async Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName,
            string fieldValue, bool isAdd, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                await _propertyIndexingService.OnDynamicFieldChangedAsync(propertyId, fieldName, fieldValue, isAdd, cancellationToken);
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        #endregion

        #region Helper Methods

        

        

        

        

        /// <summary>
        /// تنفيذ البحث المطلوب في Interface
        /// </summary>
        public async Task<PropertySearchResult> SearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                // التحقق من الكاش أولاً
                var cacheKey = $"search:{GenerateSearchCacheKey(request)}";
                var cachedResult = await GetCachedSearchResult(cacheKey);
                if (cachedResult != null)
                {
                    _logger.LogDebug("إرجاع نتائج البحث من الكاش");
                    return cachedResult;
                }

                // البحث الفعلي
                var result = await PerformSearchAsync(request, cancellationToken);

                // حفظ النتائج في الكاش
                await CacheSearchResult(cacheKey, result, TTLPolicy.SearchResults);

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في البحث");
                throw;
            }
        }

        private async Task<PropertySearchResult> PerformSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var stopwatch = Stopwatch.StartNew();
            try
            {
                return await _searchService.SearchAsync(request, cancellationToken);
            }
            finally
            {
                var elapsed = stopwatch.ElapsedMilliseconds;
                AppMetrics.RecordSearch(elapsed);
                _logger.LogInformation("وقت البحث: {ElapsedMs}ms", elapsed);
            }
        }

        

        

        

        

        

        #endregion

        #region Database Optimization - الدالة المفقودة الثانية

        /// <summary>
        /// تحسين وصيانة قاعدة بيانات Redis
        /// </summary>
        public async Task OptimizeDatabaseAsync()
        {
            await _writeLimiter.WaitAsync();
            try
            {
                _logger.LogInformation("بدء تحسين قاعدة بيانات Redis");

                var server = _redisManager.GetServer();
                var db = _redisManager.GetDatabase();

                // 1. تحليل استخدام الذاكرة
                await AnalyzeMemoryUsageAsync(server);

                // 2. تنظيف المفاتيح المنتهية
                await CleanupExpiredKeysAsync(db, server);

                // 3. تنظيف البيانات القديمة
                await CleanupOldDataAsync(db, server);

                // 4. إعادة بناء الفهارس التالفة
                await RebuildCorruptedIndexesAsync(db);

                // 5. تحسين الأداء
                await OptimizePerformanceAsync(server);

                // 6. إنشاء نقطة حفظ
                await CreateBackupPointAsync(server);

                _logger.LogInformation("اكتمل تحسين قاعدة بيانات Redis بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحسين قاعدة بيانات Redis");
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        private async Task AnalyzeMemoryUsageAsync(IServer server)
        {
            var info = await server.InfoAsync("memory");
            var memorySection = info.FirstOrDefault(s => s.Key == "Memory");

            if (memorySection != null && memorySection.Any())
            {
                var stats = new Dictionary<string, string>();
                foreach (var item in memorySection)
                {
                    stats[item.Key] = item.Value;
                }

                var usedMemory = stats.GetValueOrDefault("used_memory_human", "N/A");
                var peakMemory = stats.GetValueOrDefault("used_memory_peak_human", "N/A");
                var fragmentation = stats.GetValueOrDefault("mem_fragmentation_ratio", "N/A");

                _logger.LogInformation(
                    "تحليل الذاكرة - المستخدم: {Used}, الذروة: {Peak}, التجزئة: {Frag}",
                    usedMemory, peakMemory, fragmentation);

                // تحذير إذا كانت نسبة التجزئة عالية
                if (double.TryParse(fragmentation, out var fragRatio) && fragRatio > 1.5)
                {
                    _logger.LogWarning("نسبة تجزئة الذاكرة عالية: {Ratio}", fragRatio);
                    await server.ExecuteAsync("MEMORY", "PURGE");
                }
            }
        }

        private async Task CleanupExpiredKeysAsync(IDatabase db, IServer server)
        {
            _logger.LogInformation("بدء تنظيف المفاتيح المنتهية");

            // فرض تنظيف المفاتيح المنتهية
            await server.ExecuteAsync("MEMORY", "DOCTOR");

            // تنظيف مفاتيح البحث المؤقتة
            var tempKeys = server.Keys(pattern: "temp:*");
            var keysToDelete = new List<RedisKey>();

            foreach (var key in tempKeys.Take(1000)) // معالجة دفعات
            {
                keysToDelete.Add(key);
            }

            if (keysToDelete.Any())
            {
                await db.KeyDeleteAsync(keysToDelete.ToArray());
                _logger.LogInformation("تم حذف {Count} مفتاح مؤقت", keysToDelete.Count);
            }
        }

        private async Task CleanupOldDataAsync(IDatabase db, IServer server)
        {
            var cutoffDate = DateTime.UtcNow.AddDays(-90);
            var deletedCount = 0;

            // تنظيف بيانات الإتاحة القديمة
            var availabilityKeys = server.Keys(pattern: $"{AVAILABILITY_KEY}*");

            foreach (var key in availabilityKeys.Take(500))
            {
                var ranges = await db.SortedSetRangeByScoreAsync(
                    key,
                    0,
                    cutoffDate.Ticks);

                if (ranges.Length > 0)
                {
                    await db.SortedSetRemoveRangeByScoreAsync(
                        key,
                        0,
                        cutoffDate.Ticks);
                    deletedCount += ranges.Length;
                }
            }

            // تنظيف بيانات التسعير القديمة
            var pricingKeys = server.Keys(pattern: $"{PRICING_KEY}*");

            foreach (var key in pricingKeys.Take(500))
            {
                var hash = await db.HashGetAllAsync(key);
                var toRemove = new List<RedisValue>();

                foreach (var entry in hash)
                {
                    var parts = entry.Name.ToString().Split(':');
                    if (parts.Length == 2)
                    {
                        var endDate = new DateTime(long.Parse(parts[1]));
                        if (endDate < cutoffDate)
                        {
                            toRemove.Add(entry.Name);
                        }
                    }
                }

                if (toRemove.Any())
                {
                    await db.HashDeleteAsync(key, toRemove.ToArray());
                    deletedCount += toRemove.Count;
                }
            }

            _logger.LogInformation("تم تنظيف {Count} عنصر قديم", deletedCount);
        }

        private async Task RebuildCorruptedIndexesAsync(IDatabase db)
        {
            _logger.LogInformation("فحص وإصلاح الفهارس");

            // فحص تناسق الفهارس
            var propertyCount = await db.SetLengthAsync(PROPERTY_SET);
            var priceIndexCount = await db.SortedSetLengthAsync(PRICE_SORTED_SET);
            var ratingIndexCount = await db.SortedSetLengthAsync(RATING_SORTED_SET);
            var geoIndexCount = await db.SortedSetLengthAsync(GEO_KEY);

            _logger.LogInformation(
                "إحصائيات الفهارس - العقارات: {Props}, السعر: {Price}, التقييم: {Rating}, الموقع: {Geo}",
                propertyCount, priceIndexCount, ratingIndexCount, geoIndexCount);

            // إصلاح عدم التطابق
            if (Math.Abs(propertyCount - priceIndexCount) > 10)
            {
                _logger.LogWarning("اكتشاف عدم تطابق في فهرس الأسعار، جاري الإصلاح...");
                await RebuildPriceIndexAsync(db);
            }

            if (Math.Abs(propertyCount - ratingIndexCount) > 10)
            {
                _logger.LogWarning("اكتشاف عدم تطابق في فهرس التقييم، جاري الإصلاح...");
                await RebuildRatingIndexAsync(db);
            }
        }

        private async Task RebuildPriceIndexAsync(IDatabase db)
        {
            var members = await db.SetMembersAsync(PROPERTY_SET);
            var tran = db.CreateTransaction();

            // مسح الفهرس القديم
            _ = tran.KeyDeleteAsync(PRICE_SORTED_SET);

            // إعادة بناء
            foreach (var propertyId in members)
            {
                var minPrice = await db.HashGetAsync($"{PROPERTY_KEY}{propertyId}", "min_price");
                if (!minPrice.IsNullOrEmpty && double.TryParse(minPrice.ToString(), out var parsedMin))
                {
                    _ = tran.SortedSetAddAsync(
                        PRICE_SORTED_SET,
                        propertyId,
                        parsedMin);
                }
            }

            await tran.ExecuteAsync();
            _logger.LogInformation("تم إعادة بناء فهرس الأسعار");
        }

        private async Task RebuildRatingIndexAsync(IDatabase db)
        {
            var members = await db.SetMembersAsync(PROPERTY_SET);
            var tran = db.CreateTransaction();

            // مسح الفهرس القديم
            _ = tran.KeyDeleteAsync(RATING_SORTED_SET);

            // إعادة بناء
            foreach (var propertyId in members)
            {
                var rating = await db.HashGetAsync($"{PROPERTY_KEY}{propertyId}", "average_rating");
                if (!rating.IsNullOrEmpty && double.TryParse(rating.ToString(), out var parsedRating))
                {
                    _ = tran.SortedSetAddAsync(
                        RATING_SORTED_SET,
                        propertyId,
                        parsedRating);
                }
            }

            await tran.ExecuteAsync();
            _logger.LogInformation("تم إعادة بناء فهرس التقييمات");
        }

        private async Task OptimizePerformanceAsync(IServer server)
        {
            _logger.LogInformation("تحسين أداء Redis");

            // قراءة حالة عمليات الحفظ/إعادة كتابة AOF
            bool rdbInProgress = false;
            bool aofInProgress = false;
            try
            {
                var persistence = await server.InfoAsync("persistence");
                var section = persistence.FirstOrDefault(s => s.Key == "Persistence");
                if (section != null && section.Any())
                {
                    rdbInProgress = section.Any(kv => kv.Key == "rdb_bgsave_in_progress" && kv.Value == "1");
                    aofInProgress = section.Any(kv => kv.Key == "aof_rewrite_in_progress" && kv.Value == "1");
                }
            }
            catch { }

            // 1. إعادة كتابة AOF في الخلفية
            try
            {
                if (!aofInProgress && !rdbInProgress)
                {
                    await server.ExecuteAsync("BGREWRITEAOF");
                    _logger.LogInformation("بدء إعادة كتابة AOF");
                }
                else
                {
                    _logger.LogDebug("تخطي BGREWRITEAOF بسبب عملية خلفية نشطة");
                }
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "AOF غير مفعل أو جاري العمل عليه");
            }

            // 2. حفظ RDB باستخدام الجدولة لتجنب أخطاء التعارض
            try
            {
                await server.ExecuteAsync("BGSAVE", "SCHEDULE");
                _logger.LogInformation("تم جدولة BGSAVE للتنفيذ عند توفر الإمكانية");
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "تعذر جدولة BGSAVE");
            }

            // 3. تحسين استخدام الذاكرة
            await server.ExecuteAsync("MEMORY", "PURGE");

            // 4. جلب إحصائيات الأوامر البطيئة
            var slowLog = await server.SlowlogGetAsync(10);
            if (slowLog.Any())
            {
                _logger.LogWarning("تم اكتشاف {Count} أمر بطيء:", slowLog.Length);
                foreach (var entry in slowLog.Take(5))
                {
                    _logger.LogWarning(
                        "أمر بطيء: {Command} - الوقت: {Duration}μs",
                        string.Join(" ", entry.Arguments),
                        entry.Duration.TotalMicroseconds);
                }
            }
        }

        private async Task CreateBackupPointAsync(IServer server)
        {
            try
            {
                var lastSave = await server.LastSaveAsync();
                var timeSinceLastSave = DateTime.UtcNow - lastSave;

                if (timeSinceLastSave > TimeSpan.FromHours(1))
                {
                    // استخدم الجدولة دائماً لتفادي أخطاء التعارض
                    await server.ExecuteAsync("BGSAVE", "SCHEDULE");
                    _logger.LogInformation("تم جدولة نقطة حفظ عبر BGSAVE SCHEDULE");
                }
                else
                {
                    _logger.LogDebug(
                        "آخر نقطة حفظ كانت قبل {Minutes} دقيقة",
                        timeSinceLastSave.TotalMinutes);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل في إنشاء نقطة الحفظ");
            }
        }

        #endregion

        #region إعادة بناء الفهرس الكامل

        /// <summary>
        /// إعادة بناء الفهرس بالكامل من PostgreSQL
        /// </summary>
        public async Task RebuildIndexAsync(CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("بدء إعادة بناء فهرس Redis بالكامل");

            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                // 1. مسح البيانات القديمة
                await ClearAllIndexesAsync();

                // 2. جلب جميع العقارات النشطة
                var properties = await _propertyRepository.GetActivePropertiesAsync(cancellationToken);
                var propertiesList = properties.ToList();
                var totalCount = propertiesList.Count;
                
                _logger.LogInformation("تم جلب {Count} عقار من قاعدة البيانات", totalCount);
                
                var processed = 0;
                var failed = 0;

                if (totalCount == 0)
                {
                    _logger.LogWarning("لا توجد عقارات معتمدة للفهرسة");
                    return;
                }

                // 3. معالجة على دفعات
                var batches = propertiesList.Chunk(50); // دفعات من 50 عقار

                _logger.LogInformation("بدء معالجة {Count} عقار على دفعات", totalCount);
                
                foreach (var batch in batches)
                {
                    cancellationToken.ThrowIfCancellationRequested();

                    _logger.LogDebug("معالجة دفعة من {Count} عقار", batch.Count());

                    foreach (var property in batch)
                    {
                        try
                        {
                            _logger.LogInformation("RebuildIndex: بدء فهرسة العقار {PropertyId} - {PropertyName}", property.Id, property.Name);
                            await IndexPropertyAsync(property.Id, cancellationToken);
                            processed++;
                            _logger.LogInformation("RebuildIndex: تمت فهرسة العقار {PropertyId} بنجاح", property.Id);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "RebuildIndex: فشل في فهرسة العقار {PropertyId}", property.Id);
                            failed++;
                        }
                    }

                    _logger.LogInformation(
                        "تقدم إعادة البناء: {Processed}/{Total} (فشل: {Failed})",
                        processed, totalCount, failed);
                }

                // 4. تحسين بعد إعادة البناء
                await OptimizeDatabaseAsync();

                _logger.LogInformation(
                    "اكتملت إعادة بناء الفهرس. تمت معالجة {Processed} عقار، فشل {Failed}",
                    processed, failed);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إعادة بناء الفهرس");
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        private async Task ClearAllIndexesAsync()
        {
            _logger.LogWarning("مسح جميع الفهارس الحالية");

            var server = _redisManager.GetServer();

            // يمكن استخدام FLUSHDB لمسح قاعدة البيانات بالكامل
            // أو مسح مفاتيح محددة فقط

            var patterns = new[]
            {
                $"{PROPERTY_KEY}*",
                $"{PROPERTY_SET}",
                $"{CITY_SET}*",
                $"{TYPE_SET}*",
                $"{AMENITY_SET}*",
                $"{SERVICE_SET}*",
                $"{PRICE_SORTED_SET}",
                $"{RATING_SORTED_SET}",
                $"{CREATED_SORTED_SET}",
                $"{BOOKING_SORTED_SET}",
                $"{GEO_KEY}",
                $"{AVAILABILITY_KEY}*",
                $"{PRICING_KEY}*",
                $"{DYNAMIC_FIELD_KEY}*",
                $"{UNIT_KEY}*",
                $"{PROPERTY_UNITS_SET}*"
            };

            foreach (var pattern in patterns)
            {
                var keys = server.Keys(pattern: pattern).ToArray();
                if (keys.Any())
                {
                    await _db.KeyDeleteAsync(keys);
                    _logger.LogDebug("تم حذف {Count} مفتاح من نمط {Pattern}", keys.Length, pattern);
                }
            }
        }

        private async Task IndexPropertyAsync(Guid propertyId, CancellationToken cancellationToken)
        {
            // استخدام الدالة الموجودة
            await OnPropertyCreatedAsync(propertyId, cancellationToken);
        }

        #endregion

        #region Helper Methods - إضافات للدوال المساعدة

        private string GenerateSearchCacheKey(PropertySearchRequest request)
        {
            var key = new StringBuilder();
            key.Append(request.SearchText ?? "");
            key.Append($"_{request.City ?? ""}");
            key.Append($"_{request.PropertyType ?? ""}");
            key.Append($"_{request.MinPrice?.ToString() ?? ""}");
            key.Append($"_{request.MaxPrice?.ToString() ?? ""}");
            key.Append($"_{request.MinRating?.ToString() ?? ""}");
            key.Append($"_{request.GuestsCount?.ToString() ?? ""}");
            key.Append($"_{request.CheckIn?.Ticks}");
            key.Append($"_{request.CheckOut?.Ticks}");
            key.Append($"_{request.PageNumber}_{request.PageSize}");
            key.Append($"_{request.SortBy ?? "default"}");

            // إضافة hash للحقول الديناميكية
            if (request.DynamicFieldFilters?.Any() == true)
            {
                var dynamicHash = string.Join(",",
                    request.DynamicFieldFilters.Select(f => $"{f.Key}:{f.Value}"));
                key.Append($"_{dynamicHash.GetHashCode()}");
            }

            // إضافة hash للمرافق
            if (request.RequiredAmenityIds?.Any() == true)
            {
                var amenityHash = string.Join(",", request.RequiredAmenityIds.OrderBy(a => a));
                key.Append($"_{amenityHash.GetHashCode()}");
            }

            return Convert.ToBase64String(
                System.Text.Encoding.UTF8.GetBytes(key.ToString()));
        }

        private async Task<PropertySearchResult?> GetCachedSearchResult(string cacheKey)
        {
            var cached = await _db.StringGetAsync(cacheKey);
            if (!cached.IsNullOrEmpty)
            {
                var options = MessagePackSerializerOptions.Standard.WithResolver(ContractlessStandardResolver.Instance);
                return MessagePackSerializer.Deserialize<PropertySearchResult>(cached, options);
            }
            return null;
        }

        private async Task CacheSearchResult(
            string cacheKey,
            PropertySearchResult result,
            TimeSpan expiry)
        {
            var options = MessagePackSerializerOptions.Standard.WithResolver(ContractlessStandardResolver.Instance);
            var serialized = MessagePackSerializer.Serialize(result, options);
            await _db.StringSetAsync(cacheKey, serialized, expiry);
        }

        

        

        

        
        
        #endregion
    }
}
