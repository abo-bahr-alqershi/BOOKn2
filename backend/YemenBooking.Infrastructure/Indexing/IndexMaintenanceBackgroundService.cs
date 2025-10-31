// using Microsoft.Extensions.DependencyInjection;
// using Microsoft.Extensions.Hosting;
// using Microsoft.Extensions.Logging;
// using System;
// using System.Threading;
// using System.Threading.Tasks;
// using YemenBooking.Infrastructure.Indexing.Services;

// namespace YemenBooking.Infrastructure.BackgroundServices
// {
//     /// <summary>
//     /// خدمة خلفية لصيانة الفهرس
//     /// </summary>
//     public class IndexMaintenanceBackgroundService : BackgroundService
//     {
//         private readonly IServiceProvider _serviceProvider;
//         private readonly ILogger<IndexMaintenanceBackgroundService> _logger;
//         private Timer? _maintenanceTimer;

//         public IndexMaintenanceBackgroundService(
//             IServiceProvider serviceProvider,
//             ILogger<IndexMaintenanceBackgroundService> logger)
//         {
//             _serviceProvider = serviceProvider;
//             _logger = logger;
//         }

//         protected override Task ExecuteAsync(CancellationToken stoppingToken)
//         {
//             // جدولة الصيانة كل 6 ساعات
//             _maintenanceTimer = new Timer(
//                 DoMaintenance,
//                 null,
//                 TimeSpan.FromMinutes(10), // تأخير البداية
//                 TimeSpan.FromHours(6));   // التكرار

//             return Task.CompletedTask;
//         }

//         private async void DoMaintenance(object? state)
//         {
//             try
//             {
//                 _logger.LogInformation("بدء صيانة الفهرس");

//                 using var scope = _serviceProvider.CreateScope();
//                 var indexService = scope.ServiceProvider.GetRequiredService<LiteDbIndexingService>();

//                 // تنظيف وضغط قاعدة البيانات
//                 await indexService.OptimizeDatabaseAsync();

//                 _logger.LogInformation("اكتملت صيانة الفهرس بنجاح");
//             }
//             catch (Exception ex)
//             {
//                 _logger.LogError(ex, "خطأ في صيانة الفهرس");
//             }
//         }

//         public override void Dispose()
//         {
//             _maintenanceTimer?.Dispose();
//             base.Dispose();
//         }
//     }
// }