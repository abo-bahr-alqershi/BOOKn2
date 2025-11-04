using System;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;

namespace YemenBooking.Infrastructure.Redis.Cache
{
    /// <summary>
    /// تنفيذ التخزين المؤقت باستخدام Redis
    /// </summary>
    public sealed class RedisCache : IRedisCache
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly ILogger<RedisCache> _logger;
        private readonly JsonSerializerOptions _jsonOptions;
        private readonly SemaphoreSlim _cacheLock;
        
        // إحصائيات
        private long _hits;
        private long _misses;
        private DateTime _lastFlush;

        public RedisCache(
            IRedisConnectionManager redisManager,
            ILogger<RedisCache> logger)
        {
            _redisManager = redisManager ?? throw new ArgumentNullException(nameof(redisManager));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            
            _cacheLock = new SemaphoreSlim(1, 1);
            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = false
            };
            
            _lastFlush = DateTime.UtcNow;
        }

        /// <summary>
        /// الحصول على قيمة من الكاش
        /// </summary>
        public async Task<T> GetAsync<T>(string key, CancellationToken cancellationToken = default) where T : class
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("Key cannot be null or empty", nameof(key));
            }

            try
            {
                var db = _redisManager.GetDatabase();
                var value = await db.StringGetAsync(key);
                
                if (value.HasValue)
                {
                    Interlocked.Increment(ref _hits);
                    _logger.LogDebug("Cache hit for key: {Key}", key);
                    
                    var result = JsonSerializer.Deserialize<T>(value, _jsonOptions);
                    return result;
                }
                
                Interlocked.Increment(ref _misses);
                _logger.LogDebug("Cache miss for key: {Key}", key);
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting value from cache for key: {Key}", key);
                Interlocked.Increment(ref _misses);
                return null;
            }
        }

        /// <summary>
        /// تخزين قيمة في الكاش
        /// </summary>
        public async Task<bool> SetAsync<T>(string key, T value, TimeSpan? expiry = null, CancellationToken cancellationToken = default) where T : class
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("Key cannot be null or empty", nameof(key));
            }

            if (value == null)
            {
                throw new ArgumentNullException(nameof(value));
            }

            try
            {
                var db = _redisManager.GetDatabase();
                var json = JsonSerializer.Serialize(value, _jsonOptions);
                
                var result = await db.StringSetAsync(key, json, expiry);
                
                if (result)
                {
                    _logger.LogDebug("Cached value for key: {Key} with expiry: {Expiry}", key, expiry);
                }
                else
                {
                    _logger.LogWarning("Failed to cache value for key: {Key}", key);
                }
                
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error setting value in cache for key: {Key}", key);
                return false;
            }
        }

        /// <summary>
        /// حذف قيمة من الكاش
        /// </summary>
        public async Task<bool> RemoveAsync(string key, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("Key cannot be null or empty", nameof(key));
            }

            try
            {
                var db = _redisManager.GetDatabase();
                var result = await db.KeyDeleteAsync(key);
                
                if (result)
                {
                    _logger.LogDebug("Removed key from cache: {Key}", key);
                }
                
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error removing key from cache: {Key}", key);
                return false;
            }
        }

        /// <summary>
        /// التحقق من وجود مفتاح
        /// </summary>
        public async Task<bool> ExistsAsync(string key, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("Key cannot be null or empty", nameof(key));
            }

            try
            {
                var db = _redisManager.GetDatabase();
                return await db.KeyExistsAsync(key);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error checking if key exists: {Key}", key);
                return false;
            }
        }

        /// <summary>
        /// الحصول على قيمة أو إنشاؤها
        /// </summary>
        public async Task<T> GetOrCreateAsync<T>(
            string key, 
            Func<Task<T>> factory, 
            TimeSpan? expiry = null, 
            CancellationToken cancellationToken = default) where T : class
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("Key cannot be null or empty", nameof(key));
            }

            if (factory == null)
            {
                throw new ArgumentNullException(nameof(factory));
            }

            // محاولة الحصول على القيمة من الكاش
            var cachedValue = await GetAsync<T>(key, cancellationToken);
            if (cachedValue != null)
            {
                return cachedValue;
            }

            // استخدام lock لتجنب التحميل المتعدد
            await _cacheLock.WaitAsync(cancellationToken);
            try
            {
                // التحقق مرة أخرى بعد الحصول على lock
                cachedValue = await GetAsync<T>(key, cancellationToken);
                if (cachedValue != null)
                {
                    return cachedValue;
                }

                // إنشاء القيمة
                _logger.LogDebug("Creating value for key: {Key}", key);
                var value = await factory();
                
                if (value != null)
                {
                    await SetAsync(key, value, expiry, cancellationToken);
                }
                
                return value;
            }
            finally
            {
                _cacheLock.Release();
            }
        }

        /// <summary>
        /// تحديث وقت انتهاء الصلاحية
        /// </summary>
        public async Task<bool> RefreshAsync(string key, TimeSpan expiry, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(key))
            {
                throw new ArgumentException("Key cannot be null or empty", nameof(key));
            }

            try
            {
                var db = _redisManager.GetDatabase();
                var result = await db.KeyExpireAsync(key, expiry);
                
                if (result)
                {
                    _logger.LogDebug("Refreshed expiry for key: {Key} to {Expiry}", key, expiry);
                }
                
                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error refreshing expiry for key: {Key}", key);
                return false;
            }
        }

        /// <summary>
        /// مسح الكاش بالكامل
        /// </summary>
        public async Task FlushAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogWarning("Flushing entire cache");
                
                var server = _redisManager.GetServer();
                await server.FlushDatabaseAsync();
                
                _lastFlush = DateTime.UtcNow;
                Interlocked.Exchange(ref _hits, 0);
                Interlocked.Exchange(ref _misses, 0);
                
                _logger.LogInformation("Cache flushed successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error flushing cache");
                throw;
            }
        }

        /// <summary>
        /// الحصول على إحصائيات الكاش
        /// </summary>
        public async Task<CacheStatistics> GetStatisticsAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                var db = _redisManager.GetDatabase();
                var server = _redisManager.GetServer();
                
                // الحصول على معلومات الخادم
                var info = await server.InfoAsync();
                var dbSize = await server.DatabaseSizeAsync();
                
                // استخراج معلومات الذاكرة
                long memoryUsage = 0;
                foreach (var group in info)
                {
                    foreach (var kvp in group)
                    {
                        if (kvp.Key == "used_memory")
                        {
                            if (long.TryParse(kvp.Value, out var usage))
                            {
                                memoryUsage = usage;
                            }
                            break;
                        }
                    }
                }
                
                return new CacheStatistics
                {
                    TotalKeys = dbSize,
                    Hits = _hits,
                    Misses = _misses,
                    MemoryUsage = memoryUsage,
                    LastFlush = _lastFlush
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting cache statistics");
                
                return new CacheStatistics
                {
                    TotalKeys = 0,
                    Hits = _hits,
                    Misses = _misses,
                    MemoryUsage = 0,
                    LastFlush = _lastFlush
                };
            }
        }
    }
}
