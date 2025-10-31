// RedisMaintenanceService.cs
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using StackExchange.Redis;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Redis.Services
{
    public class RedisMaintenanceService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<RedisMaintenanceService> _logger;
        private readonly Timer _maintenanceTimer;
        private readonly Timer _healthCheckTimer;

        public RedisMaintenanceService(
            IServiceProvider serviceProvider,
            ILogger<RedisMaintenanceService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            // فحص صحة Redis كل دقيقة
            _ = Task.Run(async () =>
            {
                while (!stoppingToken.IsCancellationRequested)
                {
                    await HealthCheckAsync();
                    await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
                }
            }, stoppingToken);

            // صيانة دورية كل 6 ساعات
            _ = Task.Run(async () =>
            {
                await Task.Delay(TimeSpan.FromMinutes(10), stoppingToken); // تأخير البداية
                
                while (!stoppingToken.IsCancellationRequested)
                {
                    await MaintenanceAsync();
                    await Task.Delay(TimeSpan.FromHours(6), stoppingToken);
                }
            }, stoppingToken);

            // تنظيف المفاتيح المنتهية كل ساعة
            _ = Task.Run(async () =>
            {
                while (!stoppingToken.IsCancellationRequested)
                {
                    await CleanupExpiredKeysAsync();
                    await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
                }
            }, stoppingToken);

            await Task.CompletedTask;
        }

        private async Task HealthCheckAsync()
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
                
                if (!await redisManager.IsConnectedAsync())
                {
                    _logger.LogError("Redis غير متصل!");
                    // يمكن إرسال تنبيه هنا
                }
                else
                {
                    var server = redisManager.GetServer();
                    var info = await server.InfoAsync();
                    
                    // تحليل معلومات الخادم
                    var memorySection = info.FirstOrDefault(s => s.Key == "Memory");
                    if (memorySection.Any())
                    {
                        var usedMemory = memorySection
                            .FirstOrDefault(kv => kv.Key == "used_memory_human").Value;
                        var peakMemory = memorySection
                            .FirstOrDefault(kv => kv.Key == "used_memory_peak_human").Value;
                        
                        _logger.LogDebug(
                            "Redis Memory - Used: {Used}, Peak: {Peak}",
                            usedMemory, peakMemory);
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في فحص صحة Redis");
            }
        }

        private async Task MaintenanceAsync()
        {
            try
            {
                _logger.LogInformation("بدء صيانة Redis");
                
                using var scope = _serviceProvider.CreateScope();
                var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
                var db = redisManager.GetDatabase();
                var server = redisManager.GetServer();

                // 1. تحليل استخدام الذاكرة
                var memoryStats = await server.InfoAsync("memory");
                _logger.LogInformation("إحصائيات الذاكرة: {Stats}", memoryStats);

                // 2. تنظيف المفاتيح غير المستخدمة
                await CleanupUnusedKeysAsync(db, server);

                // 3. إعادة بناء الفهارس إذا لزم
                await RebuildIndexesIfNeededAsync(db);

                // 4. تحسين الأداء
                await OptimizePerformanceAsync(server);

                _logger.LogInformation("اكتملت صيانة Redis بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في صيانة Redis");
            }
        }

        private async Task CleanupExpiredKeysAsync()
        {
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
                var db = redisManager.GetDatabase();

                // Redis يحذف المفاتيح المنتهية تلقائياً، لكن يمكننا فرض التنظيف
                await db.ExecuteAsync("MEMORY", "DOCTOR");
                
                _logger.LogDebug("تم تنظيف المفاتيح المنتهية");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "خطأ في تنظيف المفاتيح المنتهية");
            }
        }

        private async Task CleanupUnusedKeysAsync(IDatabase db, IServer server)
        {
            // حذف مفاتيح الإتاحة القديمة (أكثر من 90 يوم)
            var cutoffDate = DateTime.UtcNow.AddDays(-90);
            var availabilityKeys = server.Keys(pattern: "availability:*");
            
            foreach (var key in availabilityKeys.Take(1000)) // معالجة دفعات صغيرة
            {
                var lastUpdate = await db.StringGetAsync($"{key}:updated");
                if (!lastUpdate.IsNullOrEmpty)
                {
                    var updateTime = new DateTime(long.Parse(lastUpdate));
                    if (updateTime < cutoffDate)
                    {
                        await db.KeyDeleteAsync(key);
                    }
                }
            }
        }

        private async Task RebuildIndexesIfNeededAsync(IDatabase db)
        {
            // فحص سلامة الفهارس
            var propertyCount = await db.SetLengthAsync("properties:all");
            var priceIndexCount = await db.SortedSetLengthAsync("properties:by_price");
            
            if (Math.Abs(propertyCount - priceIndexCount) > 10)
            {
                _logger.LogWarning(
                    "اكتشاف عدم تطابق في الفهارس: Properties={Props}, PriceIndex={Price}",
                    propertyCount, priceIndexCount);
                
                // يمكن جدولة إعادة بناء الفهارس هنا
            }
        }

        private async Task OptimizePerformanceAsync(IServer server)
        {
            // تشغيل أوامر التحسين
            await server.ExecuteAsync("BGREWRITEAOF");
            _logger.LogDebug("تم بدء إعادة كتابة AOF في الخلفية");
        }
    }
}