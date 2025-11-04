using System;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Redis.Cache;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Infrastructure.Redis.Monitoring;
using YemenBooking.Infrastructure.Redis.HealthChecks;

namespace YemenBooking.Infrastructure.Redis.Configuration
{
    /// <summary>
    /// تكوين خدمات Redis
    /// </summary>
    public static class RedisServiceConfiguration
    {
        /// <summary>
        /// إضافة خدمات Redis
        /// </summary>
        public static IServiceCollection AddRedisServices(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            // التحقق من التكوين
            var redisConnectionString = configuration.GetConnectionString("Redis");
            if (string.IsNullOrWhiteSpace(redisConnectionString))
            {
                throw new InvalidOperationException("Redis connection string is not configured");
            }

            // تسجيل الخدمات الأساسية
            services.AddSingleton<IRedisConnectionManager, RedisConnectionManager>();
            services.AddSingleton<IRedisCache, RedisCache>();
            services.AddSingleton<IHealthCheckService, Monitoring.HealthCheckService>();
            
            // تسجيل خدمة الفهرسة
            services.AddScoped<IIndexingService, IndexingService>();
            
            // إضافة Health Checks
            services.AddHealthChecks()
                .AddCheck<IndexingHealthCheck>(
                    "indexing",
                    failureStatus: Microsoft.Extensions.Diagnostics.HealthChecks.HealthStatus.Unhealthy,
                    tags: new[] { "redis", "indexing" })
                ;

            // تكوين خيارات Redis
            services.Configure<RedisOptions>(configuration.GetSection("Redis"));

            return services;
        }

        /// <summary>
        /// تهيئة خدمات Redis
        /// </summary>
        public static IServiceProvider InitializeRedisServices(this IServiceProvider serviceProvider)
        {
            // التحقق من الاتصال بـ Redis
            var redisManager = serviceProvider.GetRequiredService<IRedisConnectionManager>();
            var isConnected = redisManager.IsConnectedAsync().GetAwaiter().GetResult();
            
            if (!isConnected)
            {
                throw new InvalidOperationException("Failed to connect to Redis");
            }

            return serviceProvider;
        }
    }

    /// <summary>
    /// خيارات Redis
    /// </summary>
    public class RedisOptions
    {
        public string ConnectionString { get; set; }
        public int DatabaseNumber { get; set; } = 0;
        public int ConnectTimeout { get; set; } = 5000;
        public int SyncTimeout { get; set; } = 5000;
        public int AsyncTimeout { get; set; } = 5000;
        public int KeepAlive { get; set; } = 60;
        public int ConnectRetry { get; set; } = 3;
        public bool AbortOnConnectFail { get; set; } = false;
        public bool AllowAdmin { get; set; } = false;
        public string Password { get; set; }
        public bool Ssl { get; set; } = false;
        public string SslHost { get; set; }
        public int DefaultExpiryMinutes { get; set; } = 60;
        public bool EnableLogging { get; set; } = true;
        public bool EnableMetrics { get; set; } = true;
    }
}
