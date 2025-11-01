using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Polly;
using Polly.CircuitBreaker;
using StackExchange.Redis;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Redis.Monitoring
{
    /// <summary>
    /// نظام معالجة الأخطاء والمراقبة الذكي
    /// يوفر آليات متقدمة لمعالجة الأخطاء وتتبع الأداء
    /// </summary>
    public class ErrorHandlingAndMonitoring
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly ILogger<ErrorHandlingAndMonitoring> _logger;
        private readonly IDatabase _db;
        private readonly IAsyncPolicy _retryPolicy;
        private readonly IAsyncPolicy _circuitBreakerPolicy;
        
        // عدادات المراقبة
        private long _totalRequests;
        private long _successfulRequests;
        private long _failedRequests;
        private long _retryAttempts;
        private long _circuitBreakerTrips;

        /// <summary>
        /// مُنشئ نظام معالجة الأخطاء والمراقبة
        /// </summary>
        public ErrorHandlingAndMonitoring(
            IRedisConnectionManager redisManager,
            ILogger<ErrorHandlingAndMonitoring> logger)
        {
            _redisManager = redisManager;
            _logger = logger;
            _db = _redisManager.GetDatabase();

            // إعداد سياسة إعادة المحاولة
            _retryPolicy = BuildRetryPolicy();
            
            // إعداد قاطع الدائرة
            _circuitBreakerPolicy = BuildCircuitBreakerPolicy();
        }

        #region سياسات المعالجة

        /// <summary>
        /// بناء سياسة إعادة المحاولة
        /// </summary>
        private IAsyncPolicy BuildRetryPolicy()
        {
            return Policy
                .Handle<RedisException>()
                .Or<TimeoutException>()
                .Or<RedisTimeoutException>()
                .WaitAndRetryAsync(
                    retryCount: 3,
                    sleepDurationProvider: retryAttempt => TimeSpan.FromMilliseconds(Math.Pow(2, retryAttempt) * 100),
                    onRetry: async (outcome, timespan, retryCount, context) =>
                    {
                        Interlocked.Increment(ref _retryAttempts);
                        
                        var operationName = context.ContainsKey("OperationName") 
                            ? context["OperationName"].ToString() 
                            : "Unknown";
                        
                        _logger.LogWarning(
                            "⚠️ إعادة المحاولة #{RetryCount} للعملية {Operation} بعد {Delay}ms",
                            retryCount, operationName, timespan.TotalMilliseconds);
                        
                        // تسجيل في Redis
                        await RecordRetryAsync(operationName, retryCount);
                    });
        }

        /// <summary>
        /// بناء سياسة قاطع الدائرة
        /// </summary>
        private IAsyncPolicy BuildCircuitBreakerPolicy()
        {
            return Policy
                .Handle<Exception>()
                .CircuitBreakerAsync(
                    5, // عدد الأخطاء المسموح قبل فتح الدائرة
                    TimeSpan.FromSeconds(30), // مدة فتح الدائرة
                    (exception, duration) =>
                    {
                        Interlocked.Increment(ref _circuitBreakerTrips);
                        
                        _logger.LogError(exception,
                            "🔴 فتح قاطع الدائرة لمدة {Duration} ثانية",
                            duration.TotalSeconds);
                        
                        // تسجيل في Redis
                        Task.Run(async () => await RecordCircuitBreakerTripAsync(exception.Message, duration));
                        
                        // إرسال تنبيه
                        Task.Run(async () => await SendAlertAsync(
                            AlertLevel.Critical,
                            "Circuit Breaker Opened",
                            exception.Message));
                    },
                    () =>
                    {
                        _logger.LogInformation("🟢 إعادة تعيين قاطع الدائرة");
                    },
                    () =>
                    {
                        _logger.LogInformation("🟡 قاطع الدائرة في وضع نصف مفتوح");
                    });
        }

        #endregion

        #region تنفيذ العمليات بمعالجة الأخطاء

        /// <summary>
        /// تنفيذ عملية مع معالجة الأخطاء الكاملة
        /// </summary>
        public async Task<T> ExecuteWithErrorHandlingAsync<T>(
            Func<Task<T>> operation,
            string operationName,
            Dictionary<string, object> metadata = null)
        {
            Interlocked.Increment(ref _totalRequests);
            var stopwatch = Stopwatch.StartNew();

            var context = new Context(operationName)
            {
                ["OperationName"] = operationName,
                ["StartTime"] = DateTime.UtcNow
            };

            if (metadata != null)
            {
                foreach (var kvp in metadata)
                {
                    context[kvp.Key] = kvp.Value;
                }
            }

            try
            {
                // تطبيق السياسات المدمجة
                var result = await Policy.WrapAsync(_circuitBreakerPolicy, _retryPolicy)
                    .ExecuteAsync(async (ctx) =>
                    {
                        return await operation();
                    }, context);

                Interlocked.Increment(ref _successfulRequests);
                
                // تسجيل النجاح
                await RecordSuccessAsync(operationName, stopwatch.ElapsedMilliseconds);
                
                return result;
            }
            catch (BrokenCircuitException ex)
            {
                Interlocked.Increment(ref _failedRequests);
                
                _logger.LogError(ex, "❌ قاطع الدائرة مفتوح للعملية {Operation}", operationName);
                
                // تسجيل الفشل
                await RecordFailureAsync(operationName, "CircuitBreakerOpen", stopwatch.ElapsedMilliseconds);
                
                throw new ServiceUnavailableException($"الخدمة غير متاحة مؤقتاً: {operationName}", ex);
            }
            catch (Exception ex)
            {
                Interlocked.Increment(ref _failedRequests);
                
                _logger.LogError(ex, "❌ فشلت العملية {Operation} بعد جميع المحاولات", operationName);
                
                // تسجيل الفشل
                await RecordFailureAsync(operationName, ex.GetType().Name, stopwatch.ElapsedMilliseconds);
                
                // إرسال تنبيه إذا كان خطأ حرج
                if (IsCriticalError(ex))
                {
                    await SendAlertAsync(AlertLevel.Error, operationName, ex.Message);
                }
                
                throw;
            }
            finally
            {
                stopwatch.Stop();
                
                // تسجيل المقاييس
                await RecordMetricsAsync(operationName, stopwatch.ElapsedMilliseconds);
            }
        }

        /// <summary>
        /// تنفيذ عملية مع Fallback
        /// </summary>
        public async Task<T> ExecuteWithFallbackAsync<T>(
            Func<Task<T>> primaryOperation,
            Func<Task<T>> fallbackOperation,
            string operationName)
        {
            try
            {
                return await ExecuteWithErrorHandlingAsync(primaryOperation, operationName);
            }
            catch (Exception primaryEx)
            {
                _logger.LogWarning(primaryEx,
                    "⚠️ فشلت العملية الأساسية {Operation}، محاولة البديل",
                    operationName);

                try
                {
                    return await fallbackOperation();
                }
                catch (Exception fallbackEx)
                {
                    _logger.LogError(fallbackEx,
                        "❌ فشلت العملية البديلة أيضاً للعملية {Operation}",
                        operationName);
                    
                    throw new AggregateException(
                        $"فشلت العملية الأساسية والبديلة: {operationName}",
                        primaryEx,
                        fallbackEx);
                }
            }
        }

        #endregion

        #region المراقبة والإحصائيات

        /// <summary>
        /// الحصول على إحصائيات الأداء
        /// </summary>
        public async Task<PerformanceStatistics> GetPerformanceStatisticsAsync()
        {
            var stats = new PerformanceStatistics
            {
                TotalRequests = _totalRequests,
                SuccessfulRequests = _successfulRequests,
                FailedRequests = _failedRequests,
                RetryAttempts = _retryAttempts,
                CircuitBreakerTrips = _circuitBreakerTrips,
                SuccessRate = _totalRequests > 0 
                    ? (double)_successfulRequests / _totalRequests * 100 
                    : 0
            };

            // جلب إحصائيات من Redis
            var avgLatency = await _db.StringGetAsync("stats:avg_latency");
            var p95Latency = await _db.StringGetAsync("stats:p95_latency");
            var p99Latency = await _db.StringGetAsync("stats:p99_latency");

            stats.AverageLatencyMs = avgLatency.HasValue ? (double)avgLatency : 0;
            stats.P95LatencyMs = p95Latency.HasValue ? (double)p95Latency : 0;
            stats.P99LatencyMs = p99Latency.HasValue ? (double)p99Latency : 0;

            // جلب أبطأ العمليات
            var slowOps = await _db.SortedSetRangeByRankWithScoresAsync(
                "stats:slow_operations",
                0,
                9,
                Order.Descending);

            stats.SlowestOperations = new List<OperationMetric>();
            foreach (var op in slowOps)
            {
                stats.SlowestOperations.Add(new OperationMetric
                {
                    Name = op.Element,
                    LatencyMs = op.Score
                });
            }

            // جلب الأخطاء الأكثر تكراراً
            var topErrors = await _db.SortedSetRangeByRankWithScoresAsync(
                "stats:error_counts",
                0,
                9,
                Order.Descending);

            stats.TopErrors = new List<ErrorMetric>();
            foreach (var error in topErrors)
            {
                stats.TopErrors.Add(new ErrorMetric
                {
                    ErrorType = error.Element,
                    Count = (long)error.Score
                });
            }

            return stats;
        }

        /// <summary>
        /// مراقبة صحة النظام
        /// </summary>
        public async Task<HealthCheckResult> CheckSystemHealthAsync()
        {
            var result = new HealthCheckResult
            {
                Timestamp = DateTime.UtcNow,
                Status = HealthStatus.Healthy
            };

            var checks = new List<HealthCheck>();

            // 1. فحص اتصال Redis
            var redisCheck = await CheckRedisHealthAsync();
            checks.Add(redisCheck);

            // 2. فحص استخدام الذاكرة
            var memoryCheck = await CheckMemoryUsageAsync();
            checks.Add(memoryCheck);

            // 3. فحص معدل الأخطاء
            var errorRateCheck = CheckErrorRate();
            checks.Add(errorRateCheck);

            // 4. فحص زمن الاستجابة
            var latencyCheck = await CheckLatencyAsync();
            checks.Add(latencyCheck);

            // 5. فحص قاطع الدائرة
            var circuitBreakerCheck = CheckCircuitBreakerStatus();
            checks.Add(circuitBreakerCheck);

            result.Checks = checks;

            // تحديد الحالة الإجمالية
            if (checks.Any(c => c.Status == HealthStatus.Unhealthy))
            {
                result.Status = HealthStatus.Unhealthy;
            }
            else if (checks.Any(c => c.Status == HealthStatus.Degraded))
            {
                result.Status = HealthStatus.Degraded;
            }

            // إرسال تنبيه إذا كان النظام غير صحي
            if (result.Status == HealthStatus.Unhealthy)
            {
                await SendAlertAsync(
                    AlertLevel.Critical,
                    "System Health Check Failed",
                    $"System is unhealthy: {string.Join(", ", checks.Where(c => c.Status == HealthStatus.Unhealthy).Select(c => c.Name))}");
            }

            return result;
        }

        #endregion

        #region فحوصات الصحة

        /// <summary>
        /// فحص صحة Redis
        /// </summary>
        private async Task<HealthCheck> CheckRedisHealthAsync()
        {
            try
            {
                var stopwatch = Stopwatch.StartNew();
                await _db.PingAsync();
                stopwatch.Stop();

                return new HealthCheck
                {
                    Name = "Redis Connection",
                    Status = stopwatch.ElapsedMilliseconds < 100 
                        ? HealthStatus.Healthy 
                        : HealthStatus.Degraded,
                    ResponseTimeMs = stopwatch.ElapsedMilliseconds,
                    Message = $"Ping: {stopwatch.ElapsedMilliseconds}ms"
                };
            }
            catch (Exception ex)
            {
                return new HealthCheck
                {
                    Name = "Redis Connection",
                    Status = HealthStatus.Unhealthy,
                    Message = ex.Message
                };
            }
        }

        /// <summary>
        /// فحص استخدام الذاكرة
        /// </summary>
        private async Task<HealthCheck> CheckMemoryUsageAsync()
        {
            try
            {
                var server = _redisManager.GetServer();
                var info = await server.InfoAsync("memory");
                var memorySection = info.FirstOrDefault(s => s.Key == "Memory");

                if (memorySection != null && memorySection.Any())
                {
                    var usedMemory = memorySection
                        .FirstOrDefault(kv => kv.Key == "used_memory")
                        .Value;
                    
                    var maxMemory = memorySection
                        .FirstOrDefault(kv => kv.Key == "maxmemory")
                        .Value;

                    if (long.TryParse(usedMemory, out var used) && 
                        long.TryParse(maxMemory, out var max) && 
                        max > 0)
                    {
                        var usagePercent = (double)used / max * 100;
                        
                        return new HealthCheck
                        {
                            Name = "Memory Usage",
                            Status = usagePercent < 80 
                                ? HealthStatus.Healthy 
                                : usagePercent < 90 
                                    ? HealthStatus.Degraded 
                                    : HealthStatus.Unhealthy,
                            Message = $"Memory usage: {usagePercent:F2}%"
                        };
                    }
                }

                return new HealthCheck
                {
                    Name = "Memory Usage",
                    Status = HealthStatus.Healthy,
                    Message = "Memory usage normal"
                };
            }
            catch (Exception ex)
            {
                return new HealthCheck
                {
                    Name = "Memory Usage",
                    Status = HealthStatus.Unknown,
                    Message = ex.Message
                };
            }
        }

        /// <summary>
        /// فحص معدل الأخطاء
        /// </summary>
        private HealthCheck CheckErrorRate()
        {
            var errorRate = _totalRequests > 0 
                ? (double)_failedRequests / _totalRequests * 100 
                : 0;

            return new HealthCheck
            {
                Name = "Error Rate",
                Status = errorRate < 1 
                    ? HealthStatus.Healthy 
                    : errorRate < 5 
                        ? HealthStatus.Degraded 
                        : HealthStatus.Unhealthy,
                Message = $"Error rate: {errorRate:F2}%"
            };
        }

        /// <summary>
        /// فحص زمن الاستجابة
        /// </summary>
        private async Task<HealthCheck> CheckLatencyAsync()
        {
            var avgLatency = await _db.StringGetAsync("stats:avg_latency");
            
            if (!avgLatency.HasValue)
            {
                return new HealthCheck
                {
                    Name = "Response Latency",
                    Status = HealthStatus.Unknown,
                    Message = "No latency data available"
                };
            }

            var latency = (double)avgLatency;
            
            return new HealthCheck
            {
                Name = "Response Latency",
                Status = latency < 100 
                    ? HealthStatus.Healthy 
                    : latency < 500 
                        ? HealthStatus.Degraded 
                        : HealthStatus.Unhealthy,
                ResponseTimeMs = latency,
                Message = $"Average latency: {latency:F2}ms"
            };
        }

        /// <summary>
        /// فحص حالة قاطع الدائرة
        /// </summary>
        private HealthCheck CheckCircuitBreakerStatus()
        {
            // هذا يحتاج إلى الوصول لحالة CircuitBreaker الفعلية
            return new HealthCheck
            {
                Name = "Circuit Breaker",
                Status = _circuitBreakerTrips == 0 
                    ? HealthStatus.Healthy 
                    : HealthStatus.Degraded,
                Message = $"Circuit breaker trips: {_circuitBreakerTrips}"
            };
        }

        #endregion

        #region دوال مساعدة خاصة

        /// <summary>
        /// تسجيل النجاح
        /// </summary>
        private async Task RecordSuccessAsync(string operationName, long latencyMs)
        {
            try
            {
                var batch = _db.CreateBatch();
                _ = batch.StringIncrementAsync($"stats:success:{operationName}");
                _ = batch.StringSetAsync($"stats:last_success:{operationName}", DateTime.UtcNow.Ticks);
                _ = batch.SortedSetAddAsync("stats:latencies", operationName, latencyMs, SortedSetWhen.Always);
                batch.Execute();

                // تحديث متوسط زمن الاستجابة
                await UpdateAverageLatencyAsync(latencyMs);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل تسجيل النجاح");
            }
        }

        /// <summary>
        /// تسجيل الفشل
        /// </summary>
        private async Task RecordFailureAsync(string operationName, string errorType, long latencyMs)
        {
            try
            {
                var batch = _db.CreateBatch();
                _ = batch.StringIncrementAsync($"stats:failure:{operationName}");
                _ = batch.StringIncrementAsync($"stats:error:{errorType}");
                _ = batch.StringSetAsync($"stats:last_failure:{operationName}", DateTime.UtcNow.Ticks);
                _ = batch.SortedSetIncrementAsync("stats:error_counts", errorType, 1);
                batch.Execute();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل تسجيل الفشل");
            }
        }

        /// <summary>
        /// تسجيل إعادة المحاولة
        /// </summary>
        private async Task RecordRetryAsync(string operationName, int retryCount)
        {
            try
            {
                await _db.StringIncrementAsync($"stats:retry:{operationName}:{retryCount}");
            }
            catch { }
        }

        /// <summary>
        /// تسجيل فتح قاطع الدائرة
        /// </summary>
        private async Task RecordCircuitBreakerTripAsync(string reason, TimeSpan duration)
        {
            try
            {
                var tripData = new
                {
                    Timestamp = DateTime.UtcNow,
                    Reason = reason,
                    DurationSeconds = duration.TotalSeconds
                };

                await _db.ListRightPushAsync(
                    "stats:circuit_breaker_trips",
                    System.Text.Json.JsonSerializer.Serialize(tripData));

                // الاحتفاظ بآخر 100 حدث فقط
                await _db.ListTrimAsync("stats:circuit_breaker_trips", -100, -1);
            }
            catch { }
        }

        /// <summary>
        /// تسجيل المقاييس
        /// </summary>
        private async Task RecordMetricsAsync(string operationName, long latencyMs)
        {
            try
            {
                // تسجيل في Sorted Set للعمليات البطيئة
                if (latencyMs > 1000)
                {
                    await _db.SortedSetAddAsync(
                        "stats:slow_operations",
                        operationName,
                        latencyMs,
                        SortedSetWhen.Always);
                }
            }
            catch { }
        }

        /// <summary>
        /// تحديث متوسط زمن الاستجابة
        /// </summary>
        private async Task UpdateAverageLatencyAsync(long latencyMs)
        {
            try
            {
                // حساب المتوسط المتحرك
                var currentAvg = await _db.StringGetAsync("stats:avg_latency");
                var count = await _db.StringIncrementAsync("stats:request_count");
                
                double newAvg;
                if (currentAvg.HasValue)
                {
                    var current = (double)currentAvg;
                    newAvg = ((current * (count - 1)) + latencyMs) / count;
                }
                else
                {
                    newAvg = latencyMs;
                }

                await _db.StringSetAsync("stats:avg_latency", newAvg);
            }
            catch { }
        }

        /// <summary>
        /// إرسال تنبيه
        /// </summary>
        private async Task SendAlertAsync(AlertLevel level, string title, string message)
        {
            try
            {
                var alert = new
                {
                    Level = level.ToString(),
                    Title = title,
                    Message = message,
                    Timestamp = DateTime.UtcNow,
                    Source = "Redis Indexing System"
                };

                // حفظ التنبيه في Redis
                await _db.ListRightPushAsync(
                    $"alerts:{level.ToString().ToLower()}",
                    System.Text.Json.JsonSerializer.Serialize(alert));

                // يمكن إضافة إرسال بريد إلكتروني أو إشعارات أخرى هنا

                _logger.LogWarning("🚨 Alert: {Level} - {Title}: {Message}", level, title, message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "فشل إرسال التنبيه");
            }
        }

        /// <summary>
        /// التحقق من كون الخطأ حرج
        /// </summary>
        private bool IsCriticalError(Exception ex)
        {
            return ex is OutOfMemoryException ||
                   ex is StackOverflowException ||
                   ex is RedisConnectionException ||
                   ex is RedisServerException;
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
                    "stats:cache:misses",
                    "stats:success:*",
                    "stats:failure:*",
                    "stats:error:*",
                    "stats:retry:*",
                    "stats:avg_latency",
                    "stats:p95_latency",
                    "stats:p99_latency",
                    "stats:request_count",
                    "stats:total_requests",
                    "stats:slow_operations",
                    "stats:error_counts",
                    "stats:latencies"
                };

                var server = _redisManager.GetServer();
                foreach (var pattern in keys)
                {
                    if (pattern.Contains("*"))
                    {
                        var matchingKeys = server.Keys(pattern: pattern).ToArray();
                        if (matchingKeys.Any())
                        {
                            await _db.KeyDeleteAsync(matchingKeys);
                        }
                    }
                    else
                    {
                        await _db.KeyDeleteAsync(pattern);
                    }
                }

                // إعادة تعيين العدادات المحلية
                _totalRequests = 0;
                _successfulRequests = 0;
                _failedRequests = 0;
                _retryAttempts = 0;
                _circuitBreakerTrips = 0;

                _logger.LogInformation("تم إعادة تعيين جميع الإحصائيات");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إعادة تعيين الإحصائيات");
            }
        }

        #endregion
    }

    #region نماذج البيانات

    /// <summary>
    /// إحصائيات الأداء
    /// </summary>
    public class PerformanceStatistics
    {
        public long TotalRequests { get; set; }
        public long SuccessfulRequests { get; set; }
        public long FailedRequests { get; set; }
        public long RetryAttempts { get; set; }
        public long CircuitBreakerTrips { get; set; }
        public double SuccessRate { get; set; }
        public double AverageLatencyMs { get; set; }
        public double P95LatencyMs { get; set; }
        public double P99LatencyMs { get; set; }
        public List<OperationMetric> SlowestOperations { get; set; }
        public List<ErrorMetric> TopErrors { get; set; }
    }

    /// <summary>
    /// مقياس العملية
    /// </summary>
    public class OperationMetric
    {
        public string Name { get; set; }
        public double LatencyMs { get; set; }
    }

    /// <summary>
    /// مقياس الخطأ
    /// </summary>
    public class ErrorMetric
    {
        public string ErrorType { get; set; }
        public long Count { get; set; }
    }

    /// <summary>
    /// نتيجة فحص الصحة
    /// </summary>
    public class HealthCheckResult
    {
        public DateTime Timestamp { get; set; }
        public HealthStatus Status { get; set; }
        public List<HealthCheck> Checks { get; set; }
    }

    /// <summary>
    /// فحص صحي واحد
    /// </summary>
    public class HealthCheck
    {
        public string Name { get; set; }
        public HealthStatus Status { get; set; }
        public string Message { get; set; }
        public double? ResponseTimeMs { get; set; }
    }

    /// <summary>
    /// حالة الصحة
    /// </summary>
    public enum HealthStatus
    {
        Healthy,
        Degraded,
        Unhealthy,
        Unknown
    }

    /// <summary>
    /// مستوى التنبيه
    /// </summary>
    public enum AlertLevel
    {
        Info,
        Warning,
        Error,
        Critical
    }

    /// <summary>
    /// استثناء عدم توفر الخدمة
    /// </summary>
    public class ServiceUnavailableException : Exception
    {
        public ServiceUnavailableException(string message) : base(message) { }
        public ServiceUnavailableException(string message, Exception innerException) 
            : base(message, innerException) { }
    }

    #endregion
}
