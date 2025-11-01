using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Caching.Memory;
using StackExchange.Redis;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Infrastructure.Redis.Search;
using YemenBooking.Infrastructure.Redis.Cache;
using YemenBooking.Infrastructure.Redis.Availability;
using YemenBooking.Infrastructure.Redis.Monitoring;
using YemenBooking.Infrastructure.Redis.Scripts;
using YemenBooking.Infrastructure.Redis.Models;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Infrastructure.Redis
{
    /// <summary>
    /// النظام الرئيسي للفهرسة والبحث في Redis
    /// نقطة الدخول الموحدة لجميع عمليات الفهرسة والبحث
    /// </summary>
    public class RedisIndexingSystem : IIndexingService
    {
        private readonly SmartIndexingLayer _indexingLayer;
        private readonly OptimizedSearchEngine _searchEngine;
        private readonly MultiLevelCache _cacheManager;
        private readonly AvailabilityProcessor _availabilityProcessor;
        private readonly ErrorHandlingAndMonitoring _errorHandler;
        private readonly IRedisConnectionManager _redisManager;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUnitRepository _unitRepository;
        private readonly ILogger<RedisIndexingSystem> _logger;
        private readonly IConfiguration _configuration;
        private bool _isInitialized = false;
        private readonly SemaphoreSlim _initializationLock = new SemaphoreSlim(1, 1);
        private Task<bool> _initializationTask = null;

        /// <summary>
        /// مُنشئ النظام الرئيسي للفهرسة
        /// </summary>
        public RedisIndexingSystem(
            SmartIndexingLayer indexingLayer,
            OptimizedSearchEngine searchEngine,
            MultiLevelCache cacheManager,
            AvailabilityProcessor availabilityProcessor,
            ErrorHandlingAndMonitoring errorHandler,
            IRedisConnectionManager redisManager,
            IPropertyRepository propertyRepository,
            IUnitRepository unitRepository,
            ILogger<RedisIndexingSystem> logger,
            IConfiguration configuration)
        {
            _indexingLayer = indexingLayer;
            _searchEngine = searchEngine;
            _cacheManager = cacheManager;
            _availabilityProcessor = availabilityProcessor;
            _errorHandler = errorHandler;
            _redisManager = redisManager;
            _propertyRepository = propertyRepository;
            _unitRepository = unitRepository;
            _logger = logger;
            _configuration = configuration;

            // لا نقوم بالتهيئة في المُنشئ لتجنب التأخير
            // سيتم التهيئة بشكل كسول عند أول استخدام
            _logger.LogInformation("✅ RedisIndexingSystem created (lazy initialization)");
        }

        #region التهيئة

        /// <summary>
        /// التأكد من أن النظام مُهيأ
        /// </summary>
        private async Task<bool> EnsureInitializedAsync()
        {
            if (_isInitialized)
                return true;

            await _initializationLock.WaitAsync();
            try
            {
                // تحقق مرة أخرى بعد الحصول على القفل
                if (_isInitialized)
                    return true;

                // إذا لم تبدأ التهيئة بعد، ابدأها
                if (_initializationTask == null)
                {
                    _initializationTask = InitializeSystemAsync();
                }

                _isInitialized = await _initializationTask;
                return _isInitialized;
            }
            finally
            {
                _initializationLock.Release();
            }
        }

        /// <summary>
        /// تهيئة النظام بالكامل
        /// </summary>
        private async Task<bool> InitializeSystemAsync()
        {
            try
            {
                _logger.LogInformation("🚀 بدء تهيئة نظام الفهرسة والبحث في Redis");

                // 1. التحقق من اتصال Redis
                var isConnected = await _redisManager.IsConnectedAsync();
                if (!isConnected)
                {
                    _logger.LogError("❌ فشل الاتصال بـ Redis");
                    return false;
                }

                // 2. تحميل Lua Scripts
                await LoadLuaScriptsAsync();

                // 3. إنشاء الفهارس إذا لم تكن موجودة
                await CreateIndexesIfNotExistAsync();

                // 4. تهيئة نظام المراقبة
                await InitializeMonitoringAsync();

                // 5. تحميل الإعدادات
                LoadConfiguration();

                _logger.LogInformation("✅ تمت تهيئة نظام الفهرسة بنجاح");
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ خطأ في تهيئة نظام الفهرسة");
                return false;
            }
        }

        /// <summary>
        /// تحميل Lua Scripts إلى Redis
        /// </summary>
        private async Task LoadLuaScriptsAsync()
        {
            _logger.LogInformation("📜 تحميل Lua Scripts");

            var server = _redisManager.GetServer();
            
            // تحميل السكريبتات
            var scripts = new Dictionary<string, string>
            {
                ["ComplexSearch"] = LuaScripts.COMPLEX_SEARCH_SCRIPT,
                ["CheckAvailability"] = LuaScripts.CHECK_AVAILABILITY_SCRIPT,
                ["UpdateStatistics"] = LuaScripts.UPDATE_STATISTICS_SCRIPT,
                ["RebuildIndex"] = LuaScripts.REBUILD_INDEX_SCRIPT,
                ["CleanupOldData"] = LuaScripts.CLEANUP_OLD_DATA_SCRIPT
            };

            foreach (var script in scripts)
            {
                try
                {
                    var sha = await server.ScriptLoadAsync(script.Value);
                    _logger.LogDebug("تم تحميل السكريبت {Name}: SHA={SHA}", script.Key, sha);
                }
                catch (Exception ex)
                {
                    _logger.LogWarning(ex, "فشل تحميل السكريبت {Name}", script.Key);
                }
            }
        }

        /// <summary>
        /// إنشاء الفهارس الأساسية
        /// </summary>
        private async Task CreateIndexesIfNotExistAsync()
        {
            _logger.LogInformation("🏗️ التحقق من الفهارس الأساسية");

            var db = _redisManager.GetDatabase();

            // التحقق من وجود RediSearch
            try
            {
                var cmdInfo = await db.ExecuteAsync("COMMAND", "INFO", "FT.CREATE");
                if (!cmdInfo.IsNull)
                {
                    // محاولة إنشاء فهرس RediSearch
                    await CreateRediSearchIndexAsync();
                }
                else
                {
                    _logger.LogInformation("RediSearch غير متاح، سيتم استخدام الفهرسة اليدوية");
                    await db.StringSetAsync("search:module:available", "0");
                }
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "RediSearch غير متاح");
                await db.StringSetAsync("search:module:available", "0");
            }
        }

        /// <summary>
        /// إنشاء فهرس RediSearch
        /// </summary>
        private async Task CreateRediSearchIndexAsync()
        {
            var db = _redisManager.GetDatabase();

            try
            {
                // التحقق من وجود الفهرس
                var info = await db.ExecuteAsync("FT.INFO", RedisKeySchemas.SEARCH_INDEX_NAME);
                if (!info.IsNull)
                {
                    _logger.LogInformation("فهرس RediSearch موجود بالفعل");
                    await db.StringSetAsync("search:module:available", "1");
                    return;
                }
            }
            catch
            {
                // الفهرس غير موجود، سنقوم بإنشائه
            }

            try
            {
                // إنشاء الفهرس
                await db.ExecuteAsync("FT.CREATE", RedisKeySchemas.SEARCH_INDEX_NAME,
                    "ON", "HASH",
                    "PREFIX", "1", RedisKeySchemas.SEARCH_KEY_PREFIX,
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
                    "latitude", "GEO",
                    "longitude", "GEO"
                );

                _logger.LogInformation("✅ تم إنشاء فهرس RediSearch بنجاح");
                await db.StringSetAsync("search:module:available", "1");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل إنشاء فهرس RediSearch");
                await db.StringSetAsync("search:module:available", "0");
            }
        }

        /// <summary>
        /// تهيئة نظام المراقبة
        /// </summary>
        private async Task InitializeMonitoringAsync()
        {
            _logger.LogInformation("📊 تهيئة نظام المراقبة");

            // إعادة تعيين الإحصائيات القديمة (اختياري)
            if (_configuration.GetValue<bool>("Redis:ResetStatsOnStartup", false))
            {
                await _errorHandler.ResetStatisticsAsync();
            }

            // بدء مراقبة الصحة
            _ = Task.Run(async () =>
            {
                while (true)
                {
                    try
                    {
                        await Task.Delay(TimeSpan.FromMinutes(5));
                        var health = await _errorHandler.CheckSystemHealthAsync();
                        
                        if (health.Status != HealthStatus.Healthy)
                        {
                            _logger.LogWarning("⚠️ حالة النظام: {Status}", health.Status);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "خطأ في مراقبة الصحة");
                    }
                }
            });
        }

        /// <summary>
        /// تحميل الإعدادات
        /// </summary>
        private void LoadConfiguration()
        {
            // تحميل إعدادات مختلفة من Configuration
            var redisConfig = _configuration.GetSection("Redis");
            
            _logger.LogInformation("📝 الإعدادات المحملة:");
            _logger.LogInformation("  - Database: {DB}", redisConfig["Database"]);
            _logger.LogInformation("  - Max Search Results: {Max}", 
                _configuration.GetValue<int>("Search:MaxResults", 1000));
            _logger.LogInformation("  - Cache TTL: {TTL} دقيقة", 
                _configuration.GetValue<int>("Cache:TTLMinutes", 10));
        }

        #endregion

        #region عمليات الفهرسة

        /// <summary>
        /// فهرسة عقار جديد
        /// </summary>
        public async Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            // التأكد من التهيئة أولاً
            if (!await EnsureInitializedAsync())
            {
                _logger.LogWarning("النظام غير مُهيأ، تخطي فهرسة العقار {PropertyId}", propertyId);
                return;
            }

            await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    var property = await GetPropertyByIdAsync(propertyId, cancellationToken);
                    if (property != null)
                    {
                        return await _indexingLayer.IndexPropertyAsync(property, cancellationToken);
                    }
                    return false;
                },
                $"IndexProperty_{propertyId}",
                new Dictionary<string, object> { ["PropertyId"] = propertyId }
            );
        }

        /// <summary>
        /// تحديث فهرسة عقار
        /// </summary>
        public async Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            // التأكد من التهيئة أولاً
            if (!await EnsureInitializedAsync())
            {
                _logger.LogWarning("النظام غير مُهيأ، تخطي تحديث العقار {PropertyId}", propertyId);
                return;
            }

            await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    var property = await GetPropertyByIdAsync(propertyId, cancellationToken);
                    if (property != null)
                    {
                        return await _indexingLayer.UpdatePropertyIndexAsync(property, cancellationToken);
                    }
                    return false;
                },
                $"UpdateProperty_{propertyId}",
                new Dictionary<string, object> { ["PropertyId"] = propertyId }
            );
        }

        /// <summary>
        /// حذف عقار من الفهارس
        /// </summary>
        public async Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    return await _indexingLayer.RemovePropertyFromIndexesAsync(propertyId, cancellationToken);
                },
                $"DeleteProperty_{propertyId}",
                new Dictionary<string, object> { ["PropertyId"] = propertyId }
            );
        }

        #endregion

        #region عمليات البحث

        /// <summary>
        /// البحث في العقارات
        /// </summary>
        public async Task<PropertySearchResult> SearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken = default)
        {
            // التأكد من التهيئة أولاً
            if (!await EnsureInitializedAsync())
            {
                _logger.LogWarning("النظام غير مُهيأ، إرجاع نتائج فارغة");
                return new PropertySearchResult
                {
                    Properties = new List<PropertySearchItem>(),
                    TotalCount = 0,
                    PageNumber = request.PageNumber,
                    PageSize = request.PageSize,
                    TotalPages = 0
                };
            }

            return await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    return await _searchEngine.SearchAsync(request, cancellationToken);
                },
                "SearchProperties",
                new Dictionary<string, object>
                {
                    ["SearchText"] = request.SearchText,
                    ["City"] = request.City,
                    ["PageNumber"] = request.PageNumber,
                    ["PageSize"] = request.PageSize
                }
            );
        }

        #endregion

        #region عمليات الإتاحة

        /// <summary>
        /// فحص إتاحة العقار
        /// </summary>
        public async Task<PropertyAvailabilityResult> CheckAvailabilityAsync(
            Guid propertyId,
            DateTime checkIn,
            DateTime checkOut,
            int guestsCount,
            CancellationToken cancellationToken = default)
        {
            return await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    return await _availabilityProcessor.CheckPropertyAvailabilityAsync(
                        propertyId,
                        checkIn,
                        checkOut,
                        guestsCount,
                        null,
                        cancellationToken);
                },
                $"CheckAvailability_{propertyId}",
                new Dictionary<string, object>
                {
                    ["PropertyId"] = propertyId,
                    ["CheckIn"] = checkIn,
                    ["CheckOut"] = checkOut,
                    ["GuestsCount"] = guestsCount
                }
            );
        }

        /// <summary>
        /// تحديث إتاحة وحدة
        /// </summary>
        public async Task OnAvailabilityChangedAsync(
            Guid unitId,
            Guid propertyId,
            List<(DateTime Start, DateTime End)> availableRanges,
            CancellationToken cancellationToken = default)
        {
            await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    var ranges = availableRanges.Select(r => new AvailabilityRange
                    {
                        StartDate = r.Start,
                        EndDate = r.End,
                        IsBookable = true
                    }).ToList();

                    await _availabilityProcessor.UpdateUnitAvailabilityAsync(
                        unitId,
                        ranges,
                        cancellationToken);

                    return true;
                },
                $"UpdateAvailability_{unitId}",
                new Dictionary<string, object>
                {
                    ["UnitId"] = unitId,
                    ["PropertyId"] = propertyId,
                    ["RangesCount"] = availableRanges.Count
                }
            );
        }

        #endregion

        #region عمليات الوحدات

        /// <summary>
        /// فهرسة وحدة جديدة
        /// </summary>
        public async Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    var unit = await GetUnitByIdAsync(unitId, cancellationToken);
                    if (unit != null)
                    {
                        return await _indexingLayer.IndexUnitAsync(unit, cancellationToken);
                    }
                    return false;
                },
                $"IndexUnit_{unitId}",
                new Dictionary<string, object>
                {
                    ["UnitId"] = unitId,
                    ["PropertyId"] = propertyId
                }
            );
        }

        /// <summary>
        /// تحديث فهرسة وحدة
        /// </summary>
        public async Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await OnUnitCreatedAsync(unitId, propertyId, cancellationToken);
        }

        /// <summary>
        /// حذف وحدة من الفهارس
        /// </summary>
        public async Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    var db = _redisManager.GetDatabase();
                    var tran = db.CreateTransaction();

                    // حذف من مجموعة الوحدات
                    _ = tran.SetRemoveAsync(
                        RedisKeySchemas.GetPropertyUnitsKey(propertyId),
                        unitId.ToString());

                    // حذف بيانات الوحدة
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitKey(unitId));
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitAvailabilityKey(unitId));
                    _ = tran.KeyDeleteAsync(RedisKeySchemas.GetUnitPricingKey(unitId));

                    return await tran.ExecuteAsync();
                },
                $"DeleteUnit_{unitId}",
                new Dictionary<string, object>
                {
                    ["UnitId"] = unitId,
                    ["PropertyId"] = propertyId
                }
            );
        }

        #endregion

        #region عمليات الصيانة

        /// <summary>
        /// إعادة بناء الفهرس بالكامل
        /// </summary>
        public async Task RebuildIndexAsync(CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("🔄 بدء إعادة بناء الفهرس الكامل");

            var stopwatch = System.Diagnostics.Stopwatch.StartNew();

            await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    // مسح الفهارس القديمة
                    await ClearAllIndexesAsync();

                    // جلب جميع العقارات النشطة
                    var properties = await GetAllActivePropertiesAsync(cancellationToken);
                    var totalCount = properties.Count();

                    _logger.LogInformation("معالجة {Count} عقار", totalCount);

                    var processed = 0;
                    var failed = 0;

                    // معالجة على دفعات صغيرة لتجنب مشاكل DbContext
                    foreach (var batch in properties.Chunk(10)) // تقليل حجم الدفعة من 50 إلى 10
                    {
                        cancellationToken.ThrowIfCancellationRequested();

                        // معالجة كل عقار في الدفعة بالتسلسل لتجنب مشاكل التزامن
                        foreach (var property in batch)
                        {
                            try
                            {
                                var result = await _indexingLayer.IndexPropertyAsync(
                                    property,
                                    cancellationToken);
                                
                                if (result)
                                    processed++;
                                else
                                    failed++;
                            }
                            catch (Exception ex)
                            {
                                _logger.LogError(ex, "فشل فهرسة العقار {PropertyId}", property.Id);
                                failed++;
                            }
                        }

                        _logger.LogInformation(
                            "التقدم: {Processed}/{Total} (فشل: {Failed})",
                            processed, totalCount, failed);
                    }

                    stopwatch.Stop();
                    _logger.LogInformation(
                        "✅ اكتملت إعادة بناء الفهرس في {Seconds} ثانية. نجح: {Processed}, فشل: {Failed}",
                        stopwatch.Elapsed.TotalSeconds, processed, failed);

                    return true;
                },
                "RebuildIndex"
            );
        }

        /// <summary>
        /// تحسين قاعدة البيانات
        /// </summary>
        public async Task OptimizeDatabaseAsync()
        {
            await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    _logger.LogInformation("🔧 بدء تحسين قاعدة البيانات");

                    var db = _redisManager.GetDatabase();
                    
                    // تشغيل سكريبت التنظيف
                    var cutoffDate = DateTime.UtcNow.AddDays(-90);
                    var result = await db.ScriptEvaluateAsync(
                        LuaScripts.CLEANUP_OLD_DATA_SCRIPT,
                        values: new[] 
                        { 
                            (RedisValue)cutoffDate.Ticks,
                            (RedisValue)1000
                        });

                    _logger.LogInformation("تم حذف {Count} عنصر قديم", (int)result);

                    // مسح الكاش
                    await _cacheManager.FlushAsync();

                    // إعادة تعيين الإحصائيات القديمة
                    await _errorHandler.ResetStatisticsAsync();

                    _logger.LogInformation("✅ اكتمل تحسين قاعدة البيانات");
                    return true;
                },
                "OptimizeDatabase"
            );
        }

        #endregion

        #region الإحصائيات والمراقبة

        /// <summary>
        /// الحصول على إحصائيات النظام
        /// </summary>
        public async Task<SystemStatistics> GetSystemStatisticsAsync()
        {
            var stats = new SystemStatistics();

            // إحصائيات الأداء
            var perfStats = await _errorHandler.GetPerformanceStatisticsAsync();
            stats.TotalRequests = perfStats.TotalRequests;
            stats.SuccessRate = perfStats.SuccessRate;
            stats.AverageLatencyMs = perfStats.AverageLatencyMs;

            // إحصائيات الكاش
            var cacheStats = await _cacheManager.GetStatisticsAsync();
            stats.CacheHitRate = cacheStats.HitRate;
            stats.L1Hits = cacheStats.L1Hits;
            stats.L2Hits = cacheStats.L2Hits;
            stats.L3Hits = cacheStats.L3Hits;

            // إحصائيات الفهرسة
            var db = _redisManager.GetDatabase();
            stats.TotalProperties = await db.SetLengthAsync(RedisKeySchemas.PROPERTIES_ALL_SET);
            stats.TotalIndexedProperties = stats.TotalProperties; // نفترض أن الكل مفهرس

            // صحة النظام
            var health = await _errorHandler.CheckSystemHealthAsync();
            stats.SystemHealth = health.Status.ToString();

            return stats;
        }

        #endregion

        #region دوال مساعدة خاصة

        /// <summary>
        /// جلب عقار من قاعدة البيانات
        /// </summary>
        private async Task<Property> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogDebug("جلب العقار {PropertyId} من قاعدة البيانات", propertyId);
                
                var property = await _propertyRepository.GetByIdAsync(propertyId);
                
                if (property == null)
                {
                    _logger.LogWarning("لم يتم العثور على العقار {PropertyId}", propertyId);
                }
                
                return property;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في جلب العقار {PropertyId}", propertyId);
                throw;
            }
        }

        /// <summary>
        /// جلب وحدة من قاعدة البيانات
        /// </summary>
        private async Task<Unit> GetUnitByIdAsync(Guid unitId, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogDebug("جلب الوحدة {UnitId} من قاعدة البيانات", unitId);
                
                var unit = await _unitRepository.GetByIdAsync(unitId);
                
                if (unit == null)
                {
                    _logger.LogWarning("لم يتم العثور على الوحدة {UnitId}", unitId);
                }
                
                return unit;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في جلب الوحدة {UnitId}", unitId);
                throw;
            }
        }

        /// <summary>
        /// جلب جميع العقارات النشطة
        /// </summary>
        private async Task<IEnumerable<Property>> GetAllActivePropertiesAsync(CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("جلب جميع العقارات النشطة من قاعدة البيانات");
                
                var activeProperties = new List<Property>();
                
                // جلب العقارات على دفعات لتجنب مشاكل الذاكرة
                var pageSize = 100;
                var pageNumber = 1;
                bool hasMore = true;
                
                while (hasMore && !cancellationToken.IsCancellationRequested)
                {
                    var (items, totalCount) = await _propertyRepository.GetPagedAsync(
                        pageNumber,
                        pageSize,
                        predicate: p => p.IsActive && p.IsApproved,
                        cancellationToken: cancellationToken);
                    
                    if (items != null && items.Any())
                    {
                        activeProperties.AddRange(items);
                        pageNumber++;
                        hasMore = (pageNumber - 1) * pageSize < totalCount;
                        
                        // حد أقصى للعقارات لتجنب المشاكل
                        if (activeProperties.Count >= 1000)
                        {
                            _logger.LogWarning("تم الوصول للحد الأقصى من العقارات (1000)");
                            break;
                        }
                    }
                    else
                    {
                        hasMore = false;
                    }
                }
                
                _logger.LogInformation("تم العثور على {Count} عقار نشط", activeProperties.Count);
                return activeProperties;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في جلب العقارات النشطة");
                // إرجاع قائمة فارغة بدلاً من رمي الاستثناء
                return new List<Property>();
            }
        }

        /// <summary>
        /// مسح جميع الفهارس
        /// </summary>
        private async Task ClearAllIndexesAsync()
        {
            var server = _redisManager.GetServer();
            var patterns = new[]
            {
                "property:*",
                "properties:*",
                "tag:*",
                "idx:*",
                "geo:*",
                "avail:*",
                "unit:*",
                "pricing:*",
                "cache:*",
                "temp:*"
            };

            foreach (var pattern in patterns)
            {
                var keys = server.Keys(pattern: pattern).ToArray();
                if (keys.Any())
                {
                    await _redisManager.GetDatabase().KeyDeleteAsync(keys);
                    _logger.LogDebug("تم حذف {Count} مفتاح من النمط {Pattern}", keys.Length, pattern);
                }
            }
        }

        #endregion

        #region واجهات غير مطبقة

        public Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId, List<PricingRule> pricingRules, CancellationToken cancellationToken = default)
        {
            // TODO: تنفيذ تحديث قواعد التسعير
            return Task.CompletedTask;
        }

        /// <summary>
        /// تحديث حقل ديناميكي للعقار
        /// </summary>
        public async Task OnDynamicFieldChangedAsync(
            Guid propertyId, 
            string fieldName, 
            string fieldValue, 
            bool isAdd, 
            CancellationToken cancellationToken = default)
        {
            await _errorHandler.ExecuteWithErrorHandlingAsync(
                async () =>
                {
                    var db = _redisManager.GetDatabase();
                    var propertyKey = RedisKeySchemas.GetPropertyKey(propertyId);
                    var dynamicFieldsKey = $"{propertyKey}:dynamic_fields";
                    
                    _logger.LogInformation(
                        "تحديث حقل ديناميكي: PropertyId={PropertyId}, Field={Field}, Value={Value}, IsAdd={IsAdd}",
                        propertyId, fieldName, fieldValue, isAdd);

                    if (isAdd)
                    {
                        // إضافة أو تحديث الحقل الديناميكي
                        if (!string.IsNullOrEmpty(fieldValue))
                        {
                            // حفظ القيمة في Hash
                            await db.HashSetAsync(dynamicFieldsKey, fieldName, fieldValue);
                            
                            // إضافة إلى فهرس البحث النصي
                            var searchKey = $"dynamic_field:{fieldName.ToLower()}:{propertyId}";
                            await db.StringSetAsync(searchKey, fieldValue, TimeSpan.FromDays(30));
                            
                            // إضافة إلى مجموعة الحقول الديناميكية للعقار
                            await db.SetAddAsync($"property:{propertyId}:dynamic_fields_set", fieldName);
                            
                            // إضافة إلى فهرس القيم للبحث السريع
                            var valueIndexKey = $"dynamic_value:{fieldName.ToLower()}:{fieldValue.ToLower()}";
                            await db.SetAddAsync(valueIndexKey, propertyId.ToString());
                            
                            // تحديث الكاش
                            await _cacheManager.RemoveAsync($"property:{propertyId}");
                        }
                    }
                    else
                    {
                        // حذف أو تحديث الحقل
                        if (string.IsNullOrEmpty(fieldValue))
                        {
                            // حذف الحقل
                            await db.HashDeleteAsync(dynamicFieldsKey, fieldName);
                            await db.SetRemoveAsync($"property:{propertyId}:dynamic_fields_set", fieldName);
                            
                            // حذف من فهرس البحث
                            var searchKey = $"dynamic_field:{fieldName.ToLower()}:{propertyId}";
                            await db.KeyDeleteAsync(searchKey);
                        }
                        else
                        {
                            // تحديث القيمة الموجودة
                            var oldValue = await db.HashGetAsync(dynamicFieldsKey, fieldName);
                            if (!oldValue.IsNullOrEmpty)
                            {
                                // حذف القيمة القديمة من الفهرس
                                var oldValueIndexKey = $"dynamic_value:{fieldName.ToLower()}:{oldValue.ToString().ToLower()}";
                                await db.SetRemoveAsync(oldValueIndexKey, propertyId.ToString());
                            }
                            
                            // إضافة القيمة الجديدة
                            await db.HashSetAsync(dynamicFieldsKey, fieldName, fieldValue);
                            var newValueIndexKey = $"dynamic_value:{fieldName.ToLower()}:{fieldValue.ToLower()}";
                            await db.SetAddAsync(newValueIndexKey, propertyId.ToString());
                        }
                        
                        // تحديث الكاش
                        await _cacheManager.RemoveAsync($"property:{propertyId}");
                    }
                    
                    // تحديث فهرس البحث الرئيسي
                    await UpdatePropertySearchIndexAsync(propertyId, cancellationToken);
                    
                    _logger.LogInformation("✅ تم تحديث الحقل الديناميكي بنجاح");
                    return true;
                },
                $"DynamicFieldChange_{propertyId}_{fieldName}",
                new Dictionary<string, object>
                {
                    ["PropertyId"] = propertyId,
                    ["FieldName"] = fieldName,
                    ["IsAdd"] = isAdd
                }
            );
        }
        
        /// <summary>
        /// تحديث فهرس البحث للعقار
        /// </summary>
        private async Task UpdatePropertySearchIndexAsync(Guid propertyId, CancellationToken cancellationToken)
        {
            try
            {
                var property = await GetPropertyByIdAsync(propertyId, cancellationToken);
                if (property != null)
                {
                    await _indexingLayer.UpdatePropertyIndexAsync(property, cancellationToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث فهرس البحث للعقار {PropertyId}", propertyId);
            }
        }

        #endregion
    }

    /// <summary>
    /// إحصائيات النظام
    /// </summary>
    public class SystemStatistics
    {
        public long TotalRequests { get; set; }
        public double SuccessRate { get; set; }
        public double AverageLatencyMs { get; set; }
        public double CacheHitRate { get; set; }
        public long L1Hits { get; set; }
        public long L2Hits { get; set; }
        public long L3Hits { get; set; }
        public long TotalProperties { get; set; }
        public long TotalIndexedProperties { get; set; }
        public string SystemHealth { get; set; }
    }
}
