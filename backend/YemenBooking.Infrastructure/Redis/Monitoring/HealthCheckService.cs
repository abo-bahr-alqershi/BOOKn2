using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Redis.Monitoring
{
    /// <summary>
    /// خدمة فحص الصحة والمراقبة
    /// </summary>
    public class HealthCheckService : IHealthCheckService
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<HealthCheckService> _logger;
        
        // تخزين المقاييس
        private readonly ConcurrentDictionary<string, OperationMetric> _operationMetrics;
        private readonly ConcurrentQueue<OperationRecord> _operationHistory;
        private readonly SemaphoreSlim _metricLock;
        private DateTime _lastResetTime;

        public HealthCheckService(
            IRedisConnectionManager redisManager,
            IServiceProvider serviceProvider,
            ILogger<HealthCheckService> logger)
        {
            _redisManager = redisManager ?? throw new ArgumentNullException(nameof(redisManager));
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            
            _operationMetrics = new ConcurrentDictionary<string, OperationMetric>();
            _operationHistory = new ConcurrentQueue<OperationRecord>();
            _metricLock = new SemaphoreSlim(1, 1);
            _lastResetTime = DateTime.UtcNow;
        }

        /// <summary>
        /// فحص صحة النظام
        /// </summary>
        public async Task<Core.Interfaces.HealthCheckResult> CheckHealthAsync(CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            var components = new Dictionary<string, Core.Interfaces.ComponentHealthResult>();

            try
            {
                // فحص Redis
                components["Redis"] = await CheckRedisHealthAsync(cancellationToken);
                
                // فحص قاعدة البيانات
                components["Database"] = await CheckDatabaseHealthAsync(cancellationToken);
                
                // تحديد الحالة الإجمالية
                var overallStatus = DetermineOverallStatus(components.Values);
                
                stopwatch.Stop();

                return new Core.Interfaces.HealthCheckResult
                {
                    Status = overallStatus,
                    Description = GenerateHealthDescription(overallStatus, components),
                    Components = components,
                    ResponseTime = stopwatch.Elapsed,
                    CheckTime = DateTime.UtcNow
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Health check failed");
                
                return new Core.Interfaces.HealthCheckResult
                {
                    Status = Core.Interfaces.HealthStatus.Unhealthy,
                    Description = $"Health check failed: {ex.Message}",
                    Components = components,
                    ResponseTime = stopwatch.Elapsed,
                    CheckTime = DateTime.UtcNow
                };
            }
        }

        /// <summary>
        /// فحص صحة Redis
        /// </summary>
        public async Task<Core.Interfaces.ComponentHealthResult> CheckRedisHealthAsync(CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();

            try
            {
                // التحقق من الاتصال
                var isConnected = await _redisManager.IsConnectedAsync();
                if (!isConnected)
                {
                    return CreateUnhealthyResult("Redis", "Connection failed", stopwatch.Elapsed);
                }

                // اختبار القراءة والكتابة
                var db = _redisManager.GetDatabase();
                var testKey = $"health:test:{Guid.NewGuid():N}";
                var testValue = DateTime.UtcNow.Ticks.ToString();
                
                await db.StringSetAsync(testKey, testValue, TimeSpan.FromSeconds(10));
                var retrievedValue = await db.StringGetAsync(testKey);
                await db.KeyDeleteAsync(testKey);

                if (retrievedValue != testValue)
                {
                    return CreateDegradedResult("Redis", "Read/write test failed", stopwatch.Elapsed);
                }

                // جمع معلومات إضافية
                var connectionInfo = _redisManager.GetConnectionInfo();
                var metadata = new Dictionary<string, object>
                {
                    ["IsConnected"] = connectionInfo.IsConnected,
                    ["Endpoint"] = connectionInfo.Endpoint,
                    ["TotalConnections"] = connectionInfo.TotalConnections,
                    ["FailedConnections"] = connectionInfo.FailedConnections
                };

                stopwatch.Stop();

                // تقييم الصحة
                if (connectionInfo.FailedConnections > connectionInfo.TotalConnections * 0.1)
                {
                    return CreateDegradedResult("Redis", "High failure rate", stopwatch.Elapsed, metadata);
                }

                return CreateHealthyResult("Redis", "Redis is healthy", stopwatch.Elapsed, metadata);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Redis health check failed");
                return CreateUnhealthyResult("Redis", ex.Message, stopwatch.Elapsed);
            }
        }

        /// <summary>
        /// فحص صحة قاعدة البيانات
        /// </summary>
        public async Task<Core.Interfaces.ComponentHealthResult> CheckDatabaseHealthAsync(CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();

            try
            {
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();

                // اختبار الاتصال
                var canConnect = await dbContext.Database.CanConnectAsync(cancellationToken);
                if (!canConnect)
                {
                    return CreateUnhealthyResult("Database", "Cannot connect to database", stopwatch.Elapsed);
                }

                // اختبار استعلام بسيط
                var propertyCount = await dbContext.Properties
                    .AsNoTracking()
                    .CountAsync(cancellationToken);

                stopwatch.Stop();

                var metadata = new Dictionary<string, object>
                {
                    ["PropertyCount"] = propertyCount,
                    ["Provider"] = dbContext.Database.ProviderName,
                    ["ResponseTime"] = stopwatch.ElapsedMilliseconds
                };

                // تقييم الصحة بناءً على وقت الاستجابة
                if (stopwatch.ElapsedMilliseconds > 5000)
                {
                    return CreateDegradedResult("Database", "Slow response time", stopwatch.Elapsed, metadata);
                }

                return CreateHealthyResult("Database", "Database is healthy", stopwatch.Elapsed, metadata);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Database health check failed");
                return CreateUnhealthyResult("Database", ex.Message, stopwatch.Elapsed);
            }
        }

        /// <summary>
        /// الحصول على مقاييس الأداء
        /// </summary>
        public async Task<Core.Interfaces.PerformanceMetrics> GetPerformanceMetricsAsync(CancellationToken cancellationToken = default)
        {
            await _metricLock.WaitAsync(cancellationToken);
            try
            {
                // تنظيف السجلات القديمة
                CleanOldRecords();

                // حساب المقاييس
                var now = DateTime.UtcNow;
                var recentOperations = _operationHistory
                    .Where(op => op.Timestamp > now.AddMinutes(-5))
                    .ToList();

                if (!recentOperations.Any())
                {
                    return new Core.Interfaces.PerformanceMetrics
                    {
                        IndexingRate = 0,
                        SearchRate = 0,
                        ErrorRate = 0,
                        AverageResponseTime = 0,
                        TotalOperations = 0,
                        FailedOperations = 0,
                        MeasurementTime = now
                    };
                }

                var totalOperations = recentOperations.Count;
                var failedOperations = recentOperations.Count(op => !op.Success);
                var indexingOperations = recentOperations.Where(op => op.OperationType.StartsWith("Index")).ToList();
                var searchOperations = recentOperations.Where(op => op.OperationType == "Search").ToList();

                var timeWindow = (now - recentOperations.Min(op => op.Timestamp)).TotalSeconds;
                
                var metrics = new Core.Interfaces.PerformanceMetrics
                {
                    IndexingRate = indexingOperations.Count / Math.Max(1, timeWindow),
                    SearchRate = searchOperations.Count / Math.Max(1, timeWindow),
                    ErrorRate = totalOperations > 0 ? (double)failedOperations / totalOperations : 0,
                    AverageResponseTime = recentOperations.Any() ? recentOperations.Average(op => op.Duration) : 0,
                    TotalOperations = totalOperations,
                    FailedOperations = failedOperations,
                    MeasurementTime = now
                };

                // حساب مدة كل نوع من العمليات
                var operationGroups = recentOperations.GroupBy(op => op.OperationType);
                foreach (var group in operationGroups)
                {
                    metrics.OperationDurations[group.Key] = group.Average(op => op.Duration);
                }

                return metrics;
            }
            finally
            {
                _metricLock.Release();
            }
        }

        /// <summary>
        /// تسجيل عملية
        /// </summary>
        public void RecordOperation(string operationType, bool success, double duration)
        {
            var record = new OperationRecord
            {
                OperationType = operationType,
                Success = success,
                Duration = duration,
                Timestamp = DateTime.UtcNow
            };

            _operationHistory.Enqueue(record);

            // تحديث المقاييس التراكمية
            _operationMetrics.AddOrUpdate(operationType,
                new OperationMetric { Count = 1, TotalDuration = duration, Failures = success ? 0 : 1 },
                (key, existing) =>
                {
                    existing.Count++;
                    existing.TotalDuration += duration;
                    if (!success) existing.Failures++;
                    return existing;
                });

            // تنظيف السجلات القديمة إذا تجاوزت الحد
            if (_operationHistory.Count > 10000)
            {
                CleanOldRecords();
            }
        }

        #region Helper Methods

        /// <summary>
        /// تحديد الحالة الإجمالية
        /// </summary>
        private Core.Interfaces.HealthStatus DetermineOverallStatus(IEnumerable<Core.Interfaces.ComponentHealthResult> components)
        {
            var statuses = components.Select(c => c.Status).ToList();
            
            if (statuses.Any(s => s == Core.Interfaces.HealthStatus.Unhealthy))
                return Core.Interfaces.HealthStatus.Unhealthy;
            
            if (statuses.Any(s => s == Core.Interfaces.HealthStatus.Degraded))
                return Core.Interfaces.HealthStatus.Degraded;
            
            return Core.Interfaces.HealthStatus.Healthy;
        }

        /// <summary>
        /// إنشاء وصف الصحة
        /// </summary>
        private string GenerateHealthDescription(Core.Interfaces.HealthStatus status, Dictionary<string, Core.Interfaces.ComponentHealthResult> components)
        {
            var unhealthyComponents = components
                .Where(c => c.Value.Status == Core.Interfaces.HealthStatus.Unhealthy)
                .Select(c => c.Key)
                .ToList();

            var degradedComponents = components
                .Where(c => c.Value.Status == Core.Interfaces.HealthStatus.Degraded)
                .Select(c => c.Key)
                .ToList();

            if (unhealthyComponents.Any())
            {
                return $"Unhealthy components: {string.Join(", ", unhealthyComponents)}";
            }

            if (degradedComponents.Any())
            {
                return $"Degraded components: {string.Join(", ", degradedComponents)}";
            }

            return "All components are healthy";
        }

        /// <summary>
        /// إنشاء نتيجة صحية
        /// </summary>
        private Core.Interfaces.ComponentHealthResult CreateHealthyResult(string componentName, string message, TimeSpan responseTime, Dictionary<string, object> metadata = null)
        {
            return new Core.Interfaces.ComponentHealthResult
            {
                ComponentName = componentName,
                Status = Core.Interfaces.HealthStatus.Healthy,
                Message = message,
                ResponseTime = responseTime,
                Metadata = metadata ?? new Dictionary<string, object>()
            };
        }

        /// <summary>
        /// إنشاء نتيجة متدهورة
        /// </summary>
        private Core.Interfaces.ComponentHealthResult CreateDegradedResult(string componentName, string message, TimeSpan responseTime, Dictionary<string, object> metadata = null)
        {
            return new Core.Interfaces.ComponentHealthResult
            {
                ComponentName = componentName,
                Status = Core.Interfaces.HealthStatus.Degraded,
                Message = message,
                ResponseTime = responseTime,
                Metadata = metadata ?? new Dictionary<string, object>()
            };
        }

        /// <summary>
        /// إنشاء نتيجة غير صحية
        /// </summary>
        private Core.Interfaces.ComponentHealthResult CreateUnhealthyResult(string componentName, string message, TimeSpan responseTime, Dictionary<string, object> metadata = null)
        {
            return new Core.Interfaces.ComponentHealthResult
            {
                ComponentName = componentName,
                Status = Core.Interfaces.HealthStatus.Unhealthy,
                Message = message,
                ResponseTime = responseTime,
                Metadata = metadata ?? new Dictionary<string, object>()
            };
        }

        /// <summary>
        /// تنظيف السجلات القديمة
        /// </summary>
        private void CleanOldRecords()
        {
            var cutoffTime = DateTime.UtcNow.AddMinutes(-10);
            
            while (_operationHistory.TryPeek(out var record) && record.Timestamp < cutoffTime)
            {
                _operationHistory.TryDequeue(out _);
            }

            // إعادة تعيين المقاييس إذا مر وقت طويل
            if (DateTime.UtcNow - _lastResetTime > TimeSpan.FromHours(1))
            {
                _operationMetrics.Clear();
                _lastResetTime = DateTime.UtcNow;
            }
        }

        #endregion

        #region Internal Classes

        /// <summary>
        /// سجل عملية
        /// </summary>
        private class OperationRecord
        {
            public string OperationType { get; set; }
            public bool Success { get; set; }
            public double Duration { get; set; }
            public DateTime Timestamp { get; set; }
        }

        /// <summary>
        /// مقياس عملية
        /// </summary>
        private class OperationMetric
        {
            public long Count { get; set; }
            public double TotalDuration { get; set; }
            public long Failures { get; set; }
            public double AverageDuration => Count > 0 ? TotalDuration / Count : 0;
            public double FailureRate => Count > 0 ? (double)Failures / Count : 0;
        }

        #endregion
    }
}
