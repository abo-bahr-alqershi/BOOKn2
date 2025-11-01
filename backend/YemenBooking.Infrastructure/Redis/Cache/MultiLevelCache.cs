using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using MessagePack;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Redis.Cache
{
    /// <summary>
    /// نظام الكاش متعدد المستويات
    /// L1: Memory Cache (في الذاكرة) - سريع جداً
    /// L2: Redis Result Cache - سريع 
    /// L3: Redis Data Cache - متوسط
    /// </summary>
    public class MultiLevelCache : IMultiLevelCache
    {
        private readonly IMemoryCache _memoryCache;
        private readonly IRedisConnectionManager _redisManager;
        private readonly ILogger<MultiLevelCache> _logger;
        private IDatabase _db;
        private readonly object _dbLock = new object();

        // إعدادات TTL لكل مستوى
        private static readonly TimeSpan L1_TTL = TimeSpan.FromSeconds(30);
        private static readonly TimeSpan L2_TTL = TimeSpan.FromMinutes(2);
        private static readonly TimeSpan L3_TTL = TimeSpan.FromMinutes(10);

        /// <summary>
        /// مُنشئ نظام الكاش متعدد المستويات
        /// </summary>
        public MultiLevelCache(
            IMemoryCache memoryCache,
            IRedisConnectionManager redisManager,
            ILogger<MultiLevelCache> logger)
        {
            _memoryCache = memoryCache;
            _redisManager = redisManager;
            _logger = logger;
            _db = null; // تأجيل تهيئة Database
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

        #region عمليات القراءة

        /// <summary>
        /// الحصول على قيمة من الكاش مع البحث في جميع المستويات
        /// </summary>
        public async Task<T> GetAsync<T>(string key, CancellationToken cancellationToken = default) 
            where T : class
        {
            try
            {
                // 1. البحث في L1 (Memory Cache)
                var l1Key = GetL1Key(key);
                if (_memoryCache.TryGetValue<T>(l1Key, out var l1Value))
                {
                    _logger.LogDebug("✅ L1 Cache Hit: {Key}", key);
                    RecordCacheHit("L1");
                    return l1Value;
                }

                // 2. البحث في L2 (Redis Result Cache)
                var l2Key = GetL2Key(key);
                var l2Data = await GetDatabase().StringGetAsync(l2Key);
                if (!l2Data.IsNullOrEmpty)
                {
                    _logger.LogDebug("✅ L2 Cache Hit: {Key}", key);
                    RecordCacheHit("L2");
                    
                    var value = DeserializeValue<T>(l2Data);
                    
                    // ترقية إلى L1
                    await PromoteToL1(key, value);
                    
                    return value;
                }

                // 3. البحث في L3 (Redis Data Cache)
                var l3Key = GetL3Key(key);
                var l3Data = await GetDatabase().StringGetAsync(l3Key);
                if (!l3Data.IsNullOrEmpty)
                {
                    _logger.LogDebug("✅ L3 Cache Hit: {Key}", key);
                    RecordCacheHit("L3");
                    
                    var value = DeserializeValue<T>(l3Data);
                    
                    // ترقية إلى L2 و L1
                    await PromoteToL2(key, value);
                    await PromoteToL1(key, value);
                    
                    return value;
                }

                _logger.LogDebug("❌ Cache Miss: {Key}", key);
                RecordCacheMiss();
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في قراءة الكاش: {Key}", key);
                return null;
            }
        }

        /// <summary>
        /// الحصول على قيمة من مستوى محدد
        /// </summary>
        public async Task<T> GetFromLevelAsync<T>(string key, CacheLevel level, CancellationToken cancellationToken = default) 
            where T : class
        {
            try
            {
                switch (level)
                {
                    case CacheLevel.L1:
                        var l1Key = GetL1Key(key);
                        if (_memoryCache.TryGetValue<T>(l1Key, out var l1Value))
                        {
                            RecordCacheHit("L1");
                            return l1Value;
                        }
                        break;

                    case CacheLevel.L2:
                        var l2Key = GetL2Key(key);
                        var l2Data = await GetDatabase().StringGetAsync(l2Key);
                        if (!l2Data.IsNullOrEmpty)
                        {
                            RecordCacheHit("L2");
                            return DeserializeValue<T>(l2Data);
                        }
                        break;

                    case CacheLevel.L3:
                        var l3Key = GetL3Key(key);
                        var l3Data = await GetDatabase().StringGetAsync(l3Key);
                        if (!l3Data.IsNullOrEmpty)
                        {
                            RecordCacheHit("L3");
                            return DeserializeValue<T>(l3Data);
                        }
                        break;
                }

                RecordCacheMiss();
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في قراءة من المستوى {Level}: {Key}", level, key);
                return null;
            }
        }

        #endregion

        #region عمليات الكتابة

        /// <summary>
        /// حفظ قيمة في جميع مستويات الكاش
        /// </summary>
        public async Task SetAsync<T>(string key, T value, TimeSpan? expiry = null, CancellationToken cancellationToken = default) 
            where T : class
        {
            if (value == null)
            {
                _logger.LogWarning("محاولة حفظ قيمة null في الكاش: {Key}", key);
                return;
            }

            try
            {
                var serialized = SerializeValue(value);

                // حفظ في جميع المستويات بشكل متوازي
                var tasks = new[]
                {
                    SetL1Async(key, value),
                    SetL2Async(key, serialized),
                    SetL3Async(key, serialized)
                };

                await Task.WhenAll(tasks);

                _logger.LogDebug("✅ تم حفظ {Key} في جميع مستويات الكاش", key);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في حفظ الكاش: {Key}", key);
            }
        }

        /// <summary>
        /// حفظ في مستوى محدد
        /// </summary>
        public async Task SetInLevelAsync<T>(string key, T value, CacheLevel level, TimeSpan? expiry = null, CancellationToken cancellationToken = default) 
            where T : class
        {
            if (value == null) return;

            try
            {
                switch (level)
                {
                    case CacheLevel.L1:
                        await SetL1Async(key, value, expiry);
                        break;

                    case CacheLevel.L2:
                        var l2Serialized = SerializeValue(value);
                        await SetL2Async(key, l2Serialized, expiry);
                        break;

                    case CacheLevel.L3:
                        var l3Serialized = SerializeValue(value);
                        await SetL3Async(key, l3Serialized, expiry);
                        break;
                }

                _logger.LogDebug("✅ تم حفظ {Key} في المستوى {Level}", key, level);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في حفظ في المستوى {Level}: {Key}", level, key);
            }
        }

        #endregion

        #region عمليات الحذف

        /// <summary>
        /// حذف من جميع المستويات
        /// </summary>
        public async Task RemoveAsync(string key, CancellationToken cancellationToken = default)
        {
            try
            {
                var tasks = new[]
                {
                    RemoveFromL1(key),
                    RemoveFromL2(key),
                    RemoveFromL3(key)
                };

                await Task.WhenAll(tasks);

                _logger.LogDebug("✅ تم حذف {Key} من جميع مستويات الكاش", key);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في حذف الكاش: {Key}", key);
            }
        }

        /// <summary>
        /// حذف من مستوى محدد
        /// </summary>
        public async Task RemoveFromLevelAsync(string key, CacheLevel level, CancellationToken cancellationToken = default)
        {
            try
            {
                switch (level)
                {
                    case CacheLevel.L1:
                        await RemoveFromL1(key);
                        break;
                    case CacheLevel.L2:
                        await RemoveFromL2(key);
                        break;
                    case CacheLevel.L3:
                        await RemoveFromL3(key);
                        break;
                }

                _logger.LogDebug("✅ تم حذف {Key} من المستوى {Level}", key, level);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في حذف من المستوى {Level}: {Key}", level, key);
            }
        }

        /// <summary>
        /// مسح كامل للكاش
        /// </summary>
        public async Task FlushAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogWarning("بدء مسح جميع مستويات الكاش");

                // مسح L1 (Memory Cache) - لا يمكن مسحه بالكامل بسهولة
                // يحتاج إلى تنفيذ مخصص

                // مسح L2 و L3 من Redis
                var server = _redisManager.GetServer();
                var l2Pattern = "cache:search:l2:*";
                var l3Pattern = "cache:data:l3:*";

                var l2Keys = server.Keys(pattern: l2Pattern).ToArray();
                var l3Keys = server.Keys(pattern: l3Pattern).ToArray();

                if (l2Keys.Any())
                {
                    await GetDatabase().KeyDeleteAsync(l2Keys);
                }

                if (l3Keys.Any())
                {
                    await GetDatabase().KeyDeleteAsync(l3Keys);
                }

                _logger.LogWarning("✅ تم مسح جميع مستويات الكاش");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في مسح الكاش");
            }
        }

        #endregion

        #region إحصائيات الكاش

        /// <summary>
        /// الحصول على إحصائيات الكاش
        /// </summary>
        public async Task<CacheStatistics> GetStatisticsAsync()
        {
            try
            {
                var stats = new CacheStatistics();

                // إحصائيات الـ Hits
                var l1Hits = await GetDatabase().StringGetAsync("stats:cache:l1:hits");
                var l2Hits = await GetDatabase().StringGetAsync("stats:cache:l2:hits");
                var l3Hits = await GetDatabase().StringGetAsync("stats:cache:l3:hits");
                var misses = await GetDatabase().StringGetAsync("stats:cache:misses");

                stats.L1Hits = l1Hits.HasValue ? (long)l1Hits : 0;
                stats.L2Hits = l2Hits.HasValue ? (long)l2Hits : 0;
                stats.L3Hits = l3Hits.HasValue ? (long)l3Hits : 0;
                stats.TotalMisses = misses.HasValue ? (long)misses : 0;
                stats.TotalHits = stats.L1Hits + stats.L2Hits + stats.L3Hits;
                
                // حساب معدل النجاح
                var total = stats.TotalHits + stats.TotalMisses;
                stats.HitRate = total > 0 ? (double)stats.TotalHits / total * 100 : 0;

                // الحصول على أحجام الكاش (تقديرية)
                stats.L1Size = GetMemoryCacheSize();
                stats.L2Size = await GetRedisKeysCount("cache:search:l2:*");
                stats.L3Size = await GetRedisKeysCount("cache:data:l3:*");

                return stats;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في الحصول على إحصائيات الكاش");
                return new CacheStatistics();
            }
        }

        /// <summary>
        /// إعادة تعيين الإحصائيات
        /// </summary>
        public async Task ResetStatisticsAsync()
        {
            try
            {
                var keys = new[]
                {
                    "stats:cache:l1:hits",
                    "stats:cache:l2:hits",
                    "stats:cache:l3:hits",
                    "stats:cache:misses"
                };

                await GetDatabase().KeyDeleteAsync(keys.Select(k => (RedisKey)k).ToArray());
                
                _logger.LogInformation("تم إعادة تعيين إحصائيات الكاش");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إعادة تعيين الإحصائيات");
            }
        }

        #endregion

        #region دوال مساعدة خاصة

        /// <summary>
        /// بناء مفتاح L1
        /// </summary>
        private string GetL1Key(string key) => $"L1:{key}";

        /// <summary>
        /// بناء مفتاح L2
        /// </summary>
        private string GetL2Key(string key) => string.Format(RedisKeySchemas.CACHE_SEARCH_L2, key);

        /// <summary>
        /// بناء مفتاح L3
        /// </summary>
        private string GetL3Key(string key) => string.Format(RedisKeySchemas.CACHE_DATA_L3, key);

        /// <summary>
        /// حفظ في L1 (Memory Cache)
        /// </summary>
        private Task SetL1Async<T>(string key, T value, TimeSpan? expiry = null)
        {
            var l1Key = GetL1Key(key);
            var options = new MemoryCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = expiry ?? L1_TTL,
                Priority = CacheItemPriority.Normal
            };
            
            _memoryCache.Set(l1Key, value, options);
            return Task.CompletedTask;
        }

        /// <summary>
        /// حفظ في L2 (Redis Result Cache)
        /// </summary>
        private async Task SetL2Async(string key, byte[] serialized, TimeSpan? expiry = null)
        {
            var l2Key = GetL2Key(key);
            await GetDatabase().StringSetAsync(l2Key, serialized, expiry ?? L2_TTL);
        }

        /// <summary>
        /// حفظ في L3 (Redis Data Cache)
        /// </summary>
        private async Task SetL3Async(string key, byte[] serialized, TimeSpan? expiry = null)
        {
            var l3Key = GetL3Key(key);
            await GetDatabase().StringSetAsync(l3Key, serialized, expiry ?? L3_TTL);
        }

        /// <summary>
        /// ترقية قيمة إلى L1
        /// </summary>
        private Task PromoteToL1<T>(string key, T value) where T : class
        {
            return SetL1Async(key, value);
        }

        /// <summary>
        /// ترقية قيمة إلى L2
        /// </summary>
        private async Task PromoteToL2<T>(string key, T value) where T : class
        {
            var serialized = SerializeValue(value);
            await SetL2Async(key, serialized);
        }

        /// <summary>
        /// حذف من L1
        /// </summary>
        private Task RemoveFromL1(string key)
        {
            var l1Key = GetL1Key(key);
            _memoryCache.Remove(l1Key);
            return Task.CompletedTask;
        }

        /// <summary>
        /// حذف من L2
        /// </summary>
        private async Task RemoveFromL2(string key)
        {
            var l2Key = GetL2Key(key);
            await GetDatabase().KeyDeleteAsync(l2Key);
        }

        /// <summary>
        /// حذف من L3
        /// </summary>
        private async Task RemoveFromL3(string key)
        {
            var l3Key = GetL3Key(key);
            await GetDatabase().KeyDeleteAsync(l3Key);
        }

        /// <summary>
        /// سلسلة القيمة باستخدام MessagePack
        /// </summary>
        private byte[] SerializeValue<T>(T value)
        {
            return MessagePackSerializer.Serialize(value);
        }

        /// <summary>
        /// إلغاء سلسلة القيمة باستخدام MessagePack
        /// </summary>
        private T DeserializeValue<T>(byte[] data)
        {
            return MessagePackSerializer.Deserialize<T>(data);
        }

        /// <summary>
        /// تسجيل Cache Hit
        /// </summary>
        private void RecordCacheHit(string level)
        {
            _ = GetDatabase().StringIncrementAsync($"stats:cache:{level.ToLower()}:hits");
        }

        /// <summary>
        /// تسجيل Cache Miss
        /// </summary>
        private void RecordCacheMiss()
        {
            _ = GetDatabase().StringIncrementAsync("stats:cache:misses");
        }

        /// <summary>
        /// الحصول على حجم Memory Cache (تقديري)
        /// </summary>
        private long GetMemoryCacheSize()
        {
            // هذا تقديري لأن MemoryCache لا يوفر حجم مباشر
            // يمكن تحسينه بتتبع العدد يدوياً
            return -1; // غير متاح
        }

        /// <summary>
        /// عد المفاتيح في Redis
        /// </summary>
        private async Task<long> GetRedisKeysCount(string pattern)
        {
            try
            {
                var server = _redisManager.GetServer();
                var keys = server.Keys(pattern: pattern);
                return keys.Count();
            }
            catch
            {
                return 0;
            }
        }

        #endregion
    }

    /// <summary>
    /// واجهة نظام الكاش متعدد المستويات
    /// </summary>
    public interface IMultiLevelCache
    {
        Task<T> GetAsync<T>(string key, CancellationToken cancellationToken = default) where T : class;
        Task<T> GetFromLevelAsync<T>(string key, CacheLevel level, CancellationToken cancellationToken = default) where T : class;
        Task SetAsync<T>(string key, T value, TimeSpan? expiry = null, CancellationToken cancellationToken = default) where T : class;
        Task SetInLevelAsync<T>(string key, T value, CacheLevel level, TimeSpan? expiry = null, CancellationToken cancellationToken = default) where T : class;
        Task RemoveAsync(string key, CancellationToken cancellationToken = default);
        Task RemoveFromLevelAsync(string key, CacheLevel level, CancellationToken cancellationToken = default);
        Task FlushAsync(CancellationToken cancellationToken = default);
        Task<CacheStatistics> GetStatisticsAsync();
        Task ResetStatisticsAsync();
    }

    /// <summary>
    /// مستويات الكاش
    /// </summary>
    public enum CacheLevel
    {
        L1,  // Memory Cache
        L2,  // Redis Result Cache
        L3   // Redis Data Cache
    }

    /// <summary>
    /// إحصائيات الكاش
    /// </summary>
    public class CacheStatistics
    {
        public long L1Hits { get; set; }
        public long L2Hits { get; set; }
        public long L3Hits { get; set; }
        public long TotalHits { get; set; }
        public long TotalMisses { get; set; }
        public double HitRate { get; set; }
        public long L1Size { get; set; }
        public long L2Size { get; set; }
        public long L3Size { get; set; }
    }
}
