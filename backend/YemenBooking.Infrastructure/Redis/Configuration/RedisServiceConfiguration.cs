using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using YemenBooking.Infrastructure.Redis;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Infrastructure.Redis.Search;
using YemenBooking.Infrastructure.Redis.Cache;
using YemenBooking.Infrastructure.Redis.Availability;
using YemenBooking.Infrastructure.Redis.Monitoring;
using YemenBooking.Infrastructure.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.Entities;

namespace YemenBooking.Infrastructure.Redis.Configuration
{
    /// <summary>
    /// تكوين خدمات Redis للنظام الجديد
    /// يقوم بتسجيل جميع الخدمات المطلوبة في حاوي الحقن
    /// </summary>
    public static class RedisServiceConfiguration
    {
        /// <summary>
        /// إضافة خدمات نظام الفهرسة والبحث المحسن
        /// </summary>
        public static IServiceCollection AddRedisIndexingSystem(
            this IServiceCollection services,
            IConfiguration configuration)
        {
            // التحقق من تفعيل النظام
            var redisEnabled = configuration.GetValue<bool>("Redis:Enabled", true);
            if (!redisEnabled)
            {
                // إضافة تطبيقات وهمية إذا كان Redis غير مفعل
                services.AddSingleton<IIndexingService, NoOpIndexingService>();
                return services;
            }

            // 1. تسجيل مدير اتصال Redis (Singleton)
            services.AddSingleton<IRedisConnectionManager>(provider =>
            {
                var logger = provider.GetRequiredService<ILogger<RedisConnectionManager>>();
                return new RedisConnectionManager(configuration, logger);
            });

            // 2. تسجيل طبقة الفهرسة الذكية
            services.AddScoped<SmartIndexingLayer>(provider =>
            {
                var redisManager = provider.GetRequiredService<IRedisConnectionManager>();
                var propertyRepo = provider.GetRequiredService<IPropertyRepository>();
                var logger = provider.GetRequiredService<ILogger<SmartIndexingLayer>>();
                
                return new SmartIndexingLayer(redisManager, propertyRepo, logger);
            });

            // 3. تسجيل نظام الكاش متعدد المستويات
            services.AddSingleton<MultiLevelCache>(provider =>
            {
                var memoryCache = provider.GetRequiredService<Microsoft.Extensions.Caching.Memory.IMemoryCache>();
                var redisManager = provider.GetRequiredService<IRedisConnectionManager>();
                var logger = provider.GetRequiredService<ILogger<MultiLevelCache>>();
                
                return new MultiLevelCache(memoryCache, redisManager, logger);
            });
            
            // تسجيل الواجهة IMultiLevelCache
            services.AddSingleton<IMultiLevelCache>(provider => provider.GetRequiredService<MultiLevelCache>());

            // 4. تسجيل محرك البحث المحسن
            services.AddScoped<OptimizedSearchEngine>(provider =>
            {
                var redisManager = provider.GetRequiredService<IRedisConnectionManager>();
                var propertyRepository = provider.GetRequiredService<IPropertyRepository>();
                var cacheManager = provider.GetRequiredService<MultiLevelCache>();
                var availabilityProcessor = provider.GetRequiredService<AvailabilityProcessor>();
                var logger = provider.GetRequiredService<ILogger<OptimizedSearchEngine>>();
                var memoryCache = provider.GetRequiredService<Microsoft.Extensions.Caching.Memory.IMemoryCache>();
                
                return new OptimizedSearchEngine(redisManager, propertyRepository, cacheManager, availabilityProcessor, logger, memoryCache);
            });

            // 5. تسجيل معالج الإتاحة
            services.AddScoped<AvailabilityProcessor>(provider =>
            {
                var redisManager = provider.GetRequiredService<IRedisConnectionManager>();
                var availabilityService = provider.GetRequiredService<IAvailabilityService>();
                var pricingService = provider.GetRequiredService<IPricingService>();
                var logger = provider.GetRequiredService<ILogger<AvailabilityProcessor>>();
                
                return new AvailabilityProcessor(redisManager, availabilityService, pricingService, logger);
            });

            // 6. تسجيل نظام معالجة الأخطاء والمراقبة
            services.AddSingleton<ErrorHandlingAndMonitoring>(provider =>
            {
                var redisManager = provider.GetRequiredService<IRedisConnectionManager>();
                var logger = provider.GetRequiredService<ILogger<ErrorHandlingAndMonitoring>>();
                
                return new ErrorHandlingAndMonitoring(redisManager, logger);
            });

            // 7. تسجيل النظام الرئيسي
            services.AddScoped<RedisIndexingSystem>(provider =>
            {
                var indexingLayer = provider.GetRequiredService<SmartIndexingLayer>();
                var searchEngine = provider.GetRequiredService<OptimizedSearchEngine>();
                var cacheManager = provider.GetRequiredService<MultiLevelCache>();
                var availabilityProcessor = provider.GetRequiredService<AvailabilityProcessor>();
                var errorHandler = provider.GetRequiredService<ErrorHandlingAndMonitoring>();
                var redisManager = provider.GetRequiredService<IRedisConnectionManager>();
                var propertyRepository = provider.GetRequiredService<IPropertyRepository>();
                var unitRepository = provider.GetRequiredService<IUnitRepository>();
                var logger = provider.GetRequiredService<ILogger<RedisIndexingSystem>>();
                
                return new RedisIndexingSystem(
                    indexingLayer,
                    searchEngine,
                    cacheManager,
                    availabilityProcessor,
                    errorHandler,
                    redisManager,
                    propertyRepository,
                    unitRepository,
                    logger,
                    configuration);
            });
            
            // تسجيل كـ IIndexingService أيضاً
            services.AddScoped<IIndexingService>(provider => provider.GetRequiredService<RedisIndexingSystem>());

            // 8. إضافة خدمات الصيانة المجدولة (اختياري)
            if (configuration.GetValue<bool>("Redis:EnableScheduledMaintenance", false))
            {
                services.AddHostedService<RedisMaintenanceBackgroundService>();
            }

            // 9. إضافة Health Checks
            services.AddHealthChecks()
                .AddCheck<RedisHealthCheck>("redis", tags: new[] { "redis", "database" });

            return services;
        }

        /// <summary>
        /// إضافة إعدادات Redis الافتراضية
        /// </summary>
        public static IConfigurationBuilder AddRedisConfiguration(
            this IConfigurationBuilder builder,
            bool isDevelopment = false)
        {
            var defaultSettings = new Dictionary<string, string>
            {
                // إعدادات الاتصال
                ["Redis:Enabled"] = "true",
                ["Redis:EndPoint"] = isDevelopment ? "localhost:6379" : "redis-server:6379",
                ["Redis:Password"] = "",
                ["Redis:Database"] = "0",
                ["Redis:ConnectTimeout"] = "5000",
                ["Redis:SyncTimeout"] = "5000",
                ["Redis:AsyncTimeout"] = "5000",
                ["Redis:KeepAlive"] = "60",
                ["Redis:ConnectRetry"] = "3",
                ["Redis:AbortOnConnectFail"] = "false",
                ["Redis:AllowAdmin"] = isDevelopment ? "true" : "false",

                // إعدادات البحث
                ["Search:MaxResults"] = "1000",
                ["Search:DefaultPageSize"] = "20",
                ["Search:MaxPageSize"] = "100",
                ["Search:EnableRediSearch"] = "true",

                // إعدادات الكاش
                ["Cache:L1TTLSeconds"] = "30",
                ["Cache:L2TTLMinutes"] = "2",
                ["Cache:L3TTLMinutes"] = "10",
                ["Cache:EnableMultiLevel"] = "true",

                // إعدادات المراقبة
                ["Monitoring:EnableHealthChecks"] = "true",
                ["Monitoring:HealthCheckIntervalMinutes"] = "5",
                ["Monitoring:EnableMetrics"] = "true",
                ["Monitoring:EnableAlerting"] = "true",

                // إعدادات الصيانة
                ["Redis:EnableScheduledMaintenance"] = "true",
                ["Redis:MaintenanceIntervalHours"] = "24",
                ["Redis:CleanupOldDataDays"] = "90",
                ["Redis:ResetStatsOnStartup"] = isDevelopment ? "true" : "false",

                // إعدادات الأداء
                ["Performance:MaxConcurrentIndexing"] = "5",
                ["Performance:MaxConcurrentSearch"] = "50",
                ["Performance:BatchSize"] = "50",
                ["Performance:EnablePipelining"] = "true",

                // Circuit Breaker
                ["CircuitBreaker:FailureThreshold"] = "5",
                ["CircuitBreaker:BreakDurationSeconds"] = "30",
                ["CircuitBreaker:RetryCount"] = "3",

                // Lua Scripts
                ["LuaScripts:PreloadOnStartup"] = "true",
                ["LuaScripts:UseEvalSha"] = "true"
            };

            builder.AddInMemoryCollection(defaultSettings);
            return builder;
        }
    }

    /// <summary>
    /// خدمة فهرسة وهمية للاستخدام عند تعطيل Redis
    /// </summary>
    internal class NoOpIndexingService : IIndexingService
    {
        private readonly ILogger<NoOpIndexingService> _logger;

        public NoOpIndexingService(ILogger<NoOpIndexingService> logger)
        {
            _logger = logger;
        }

        public Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: OnPropertyCreatedAsync {PropertyId}", propertyId);
            return Task.CompletedTask;
        }

        public Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: OnPropertyUpdatedAsync {PropertyId}", propertyId);
            return Task.CompletedTask;
        }

        public Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: OnPropertyDeletedAsync {PropertyId}", propertyId);
            return Task.CompletedTask;
        }

        public Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: OnUnitCreatedAsync {UnitId}", unitId);
            return Task.CompletedTask;
        }

        public Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: OnUnitUpdatedAsync {UnitId}", unitId);
            return Task.CompletedTask;
        }

        public Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: OnUnitDeletedAsync {UnitId}", unitId);
            return Task.CompletedTask;
        }

        public Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId, List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: OnAvailabilityChangedAsync {UnitId}", unitId);
            return Task.CompletedTask;
        }

        public Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId, List<PricingRule> pricingRules, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: OnPricingRuleChangedAsync {UnitId}", unitId);
            return Task.CompletedTask;
        }

        public Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName, string fieldValue, bool isAdd, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: OnDynamicFieldChangedAsync {PropertyId}", propertyId);
            return Task.CompletedTask;
        }

        public Task<PropertySearchResult> SearchAsync(PropertySearchRequest request, CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: SearchAsync");
            return Task.FromResult(new PropertySearchResult
            {
                Properties = new List<PropertySearchItem>(),
                TotalCount = 0,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = 0
            });
        }

        public Task RebuildIndexAsync(CancellationToken cancellationToken = default)
        {
            _logger.LogDebug("NoOp: RebuildIndexAsync");
            return Task.CompletedTask;
        }

        public Task OptimizeDatabaseAsync()
        {
            _logger.LogDebug("NoOp: OptimizeDatabaseAsync");
            return Task.CompletedTask;
        }
    }

    /// <summary>
    /// خدمة الصيانة في الخلفية
    /// </summary>
    internal class RedisMaintenanceBackgroundService : Microsoft.Extensions.Hosting.BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<RedisMaintenanceBackgroundService> _logger;
        private readonly IConfiguration _configuration;

        public RedisMaintenanceBackgroundService(
            IServiceProvider serviceProvider,
            ILogger<RedisMaintenanceBackgroundService> logger,
            IConfiguration configuration)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            _configuration = configuration;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var intervalHours = _configuration.GetValue<int>("Redis:MaintenanceIntervalHours", 24);
            var interval = TimeSpan.FromHours(intervalHours);

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await Task.Delay(interval, stoppingToken);

                    using (var scope = _serviceProvider.CreateScope())
                    {
                        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        _logger.LogInformation("بدء الصيانة الدورية");
                        await indexingService.OptimizeDatabaseAsync();
                        _logger.LogInformation("اكتملت الصيانة الدورية");
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "خطأ في الصيانة الدورية");
                }
            }
        }
    }

    /// <summary>
    /// فحص صحة Redis
    /// </summary>
    internal class RedisHealthCheck : Microsoft.Extensions.Diagnostics.HealthChecks.IHealthCheck
    {
        private readonly IRedisConnectionManager _redisManager;

        public RedisHealthCheck(IRedisConnectionManager redisManager)
        {
            _redisManager = redisManager;
        }

        public async Task<Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult> CheckHealthAsync(
            Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckContext context,
            CancellationToken cancellationToken = default)
        {
            try
            {
                var isConnected = await _redisManager.IsConnectedAsync();
                
                if (isConnected)
                {
                    var db = _redisManager.GetDatabase();
                    var stopwatch = System.Diagnostics.Stopwatch.StartNew();
                    await db.PingAsync();
                    stopwatch.Stop();

                    if (stopwatch.ElapsedMilliseconds < 100)
                    {
                        return Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Healthy(
                            $"Redis is healthy. Ping: {stopwatch.ElapsedMilliseconds}ms");
                    }
                    else
                    {
                        return Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Degraded(
                            $"Redis is slow. Ping: {stopwatch.ElapsedMilliseconds}ms");
                    }
                }
                else
                {
                    return Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Unhealthy(
                        "Redis is not connected");
                }
            }
            catch (Exception ex)
            {
                return Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckResult.Unhealthy(
                    "Redis check failed", ex);
            }
        }
    }
}
