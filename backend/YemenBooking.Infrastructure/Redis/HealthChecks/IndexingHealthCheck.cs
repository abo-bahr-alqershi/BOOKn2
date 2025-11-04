using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Logging;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;

namespace YemenBooking.Infrastructure.Redis.HealthChecks
{
    /// <summary>
    /// فحص صحة نظام الفهرسة
    /// </summary>
    public class IndexingHealthCheck : IHealthCheck
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IHealthCheckService _healthService;
        private readonly ILogger<IndexingHealthCheck> _logger;
        
        // عتبات الأداء
        private const double MAX_ERROR_RATE = 0.05; // 5%
        private const double MIN_INDEXING_RATE = 10; // 10 operations/sec
        private const double MAX_RESPONSE_TIME = 1000; // 1000ms

        public IndexingHealthCheck(
            IRedisConnectionManager redisManager,
            IHealthCheckService healthService,
            ILogger<IndexingHealthCheck> logger)
        {
            _redisManager = redisManager ?? throw new ArgumentNullException(nameof(redisManager));
            _healthService = healthService ?? throw new ArgumentNullException(nameof(healthService));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        }

        /// <summary>
        /// فحص صحة النظام
        /// </summary>
        public async Task<Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context,
            CancellationToken cancellationToken = default)
        {
            var stopwatch = Stopwatch.StartNew();
            var data = new Dictionary<string, object>();

            try
            {
                // فحص اتصال Redis
                var redisHealth = await CheckRedisHealthAsync(cancellationToken);
                data["redis"] = redisHealth;

                if (redisHealth.Status == Core.Interfaces.HealthStatus.Unhealthy)
                {
                    return Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Unhealthy(
                        "Redis is not accessible",
                        data: data);
                }

                // فحص معدلات الأداء
                var performanceMetrics = await _healthService.GetPerformanceMetricsAsync(cancellationToken);
                data["performance"] = new
                {
                    indexingRate = performanceMetrics.IndexingRate,
                    searchRate = performanceMetrics.SearchRate,
                    errorRate = performanceMetrics.ErrorRate,
                    avgResponseTime = performanceMetrics.AverageResponseTime
                };

                // تقييم الصحة بناءً على المعايير
                var healthStatus = EvaluateHealth(performanceMetrics);
                
                stopwatch.Stop();
                data["checkDuration"] = stopwatch.ElapsedMilliseconds;

                switch (healthStatus)
                {
                    case Core.Interfaces.HealthStatus.Healthy:
                        return Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy(
                            $"System is healthy. Indexing rate: {performanceMetrics.IndexingRate:F2}/sec",
                            data);
                    
                    case Core.Interfaces.HealthStatus.Degraded:
                        return Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Degraded(
                            $"System is degraded. Error rate: {performanceMetrics.ErrorRate:P}",
                            data: data);
                    
                    default:
                        return Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Unhealthy(
                            "System is unhealthy",
                            data: data);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Health check failed");
                
                return Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Unhealthy(
                    "Health check failed",
                    exception: ex,
                    data: data);
            }
        }

        /// <summary>
        /// فحص صحة Redis
        /// </summary>
        private async Task<Core.Interfaces.ComponentHealthResult> CheckRedisHealthAsync(CancellationToken cancellationToken)
        {
            try
            {
                var stopwatch = Stopwatch.StartNew();
                
                // التحقق من الاتصال
                var isConnected = await _redisManager.IsConnectedAsync();
                if (!isConnected)
                {
                    return new Core.Interfaces.ComponentHealthResult
                    {
                        ComponentName = "Redis",
                        Status = Core.Interfaces.HealthStatus.Unhealthy,
                        Message = "Redis connection failed",
                        ResponseTime = stopwatch.Elapsed
                    };
                }

                // اختبار عملية بسيطة
                var db = _redisManager.GetDatabase();
                var testKey = $"health:check:{Guid.NewGuid():N}";
                await db.StringSetAsync(testKey, "test", TimeSpan.FromSeconds(10));
                var value = await db.StringGetAsync(testKey);
                await db.KeyDeleteAsync(testKey);

                stopwatch.Stop();

                if (value != "test")
                {
                    return new Core.Interfaces.ComponentHealthResult
                    {
                        ComponentName = "Redis",
                        Status = Core.Interfaces.HealthStatus.Degraded,
                        Message = "Redis read/write test failed",
                        ResponseTime = stopwatch.Elapsed
                    };
                }

                // فحص معلومات الخادم
                var server = _redisManager.GetServer();
                var info = await server.InfoAsync();
                
                return new Core.Interfaces.ComponentHealthResult
                {
                    ComponentName = "Redis",
                    Status = Core.Interfaces.HealthStatus.Healthy,
                    Message = "Redis is healthy",
                    ResponseTime = stopwatch.Elapsed,
                    Metadata = new Dictionary<string, object>
                    {
                        ["connected_clients"] = GetInfoValue(info, "connected_clients"),
                        ["used_memory_human"] = GetInfoValue(info, "used_memory_human"),
                        ["uptime_in_seconds"] = GetInfoValue(info, "uptime_in_seconds")
                    }
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Redis health check failed");
                
                return new Core.Interfaces.ComponentHealthResult
                {
                    ComponentName = "Redis",
                    Status = Core.Interfaces.HealthStatus.Unhealthy,
                    Message = $"Redis health check failed: {ex.Message}",
                    ResponseTime = TimeSpan.Zero
                };
            }
        }

        /// <summary>
        /// تقييم الصحة بناءً على المعايير
        /// </summary>
        private Core.Interfaces.HealthStatus EvaluateHealth(Core.Interfaces.PerformanceMetrics metrics)
        {
            // معايير عدم الصحة
            if (metrics.ErrorRate > MAX_ERROR_RATE * 2) // 10% error rate
                return Core.Interfaces.HealthStatus.Unhealthy;
            
            if (metrics.IndexingRate < MIN_INDEXING_RATE / 2) // Less than 5 ops/sec
                return Core.Interfaces.HealthStatus.Unhealthy;
            
            if (metrics.AverageResponseTime > MAX_RESPONSE_TIME * 2) // > 2000ms
                return Core.Interfaces.HealthStatus.Unhealthy;

            // معايير التدهور
            if (metrics.ErrorRate > MAX_ERROR_RATE) // 5% error rate
                return Core.Interfaces.HealthStatus.Degraded;
            
            if (metrics.IndexingRate < MIN_INDEXING_RATE) // Less than 10 ops/sec
                return Core.Interfaces.HealthStatus.Degraded;
            
            if (metrics.AverageResponseTime > MAX_RESPONSE_TIME) // > 1000ms
                return Core.Interfaces.HealthStatus.Degraded;

            return Core.Interfaces.HealthStatus.Healthy;
        }

        /// <summary>
        /// استخراج قيمة من معلومات Redis
        /// </summary>
        private string GetInfoValue(IGrouping<string, KeyValuePair<string, string>>[] info, string key)
        {
            foreach (var group in info)
            {
                foreach (var kvp in group)
                {
                    if (kvp.Key == key)
                        return kvp.Value;
                }
            }
            return "N/A";
        }
    }
}
