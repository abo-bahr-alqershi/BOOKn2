using System;
using System.Threading;
using System.Threading.Tasks;

namespace YemenBooking.Infrastructure.Redis.Core.Interfaces
{
    /// <summary>
    /// واجهة فحص صحة النظام
    /// </summary>
    public interface IHealthCheckService
    {
        /// <summary>
        /// فحص صحة النظام
        /// </summary>
        Task<HealthCheckResult> CheckHealthAsync(CancellationToken cancellationToken = default);

        /// <summary>
        /// فحص صحة Redis
        /// </summary>
        Task<ComponentHealthResult> CheckRedisHealthAsync(CancellationToken cancellationToken = default);

        /// <summary>
        /// فحص صحة قاعدة البيانات
        /// </summary>
        Task<ComponentHealthResult> CheckDatabaseHealthAsync(CancellationToken cancellationToken = default);

        /// <summary>
        /// فحص معدل الأداء
        /// </summary>
        Task<PerformanceMetrics> GetPerformanceMetricsAsync(CancellationToken cancellationToken = default);
    }

    /// <summary>
    /// نتيجة فحص الصحة
    /// </summary>
    public class HealthCheckResult
    {
        public HealthStatus Status { get; set; }
        public string Description { get; set; }
        public Dictionary<string, ComponentHealthResult> Components { get; set; } = new();
        public TimeSpan ResponseTime { get; set; }
        public DateTime CheckTime { get; set; }
    }

    /// <summary>
    /// حالة الصحة
    /// </summary>
    public enum HealthStatus
    {
        Healthy,
        Degraded,
        Unhealthy
    }

    /// <summary>
    /// نتيجة فحص مكون
    /// </summary>
    public class ComponentHealthResult
    {
        public string ComponentName { get; set; }
        public HealthStatus Status { get; set; }
        public string Message { get; set; }
        public TimeSpan ResponseTime { get; set; }
        public Dictionary<string, object> Metadata { get; set; } = new();
    }

    /// <summary>
    /// مقاييس الأداء
    /// </summary>
    public class PerformanceMetrics
    {
        public double IndexingRate { get; set; } // عمليات في الثانية
        public double SearchRate { get; set; } // بحث في الثانية
        public double ErrorRate { get; set; } // نسبة الأخطاء
        public double AverageResponseTime { get; set; } // بالميلي ثانية
        public long TotalOperations { get; set; }
        public long FailedOperations { get; set; }
        public Dictionary<string, double> OperationDurations { get; set; } = new();
        public DateTime MeasurementTime { get; set; }
    }
}
