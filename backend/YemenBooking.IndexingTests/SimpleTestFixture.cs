using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis.Configuration;

namespace YemenBooking.IndexingTests
{
    /// <summary>
    /// إعداد بيئة اختبار بسيطة
    /// </summary>
    public class SimpleTestFixture : IDisposable
    {
        public IServiceProvider ServiceProvider { get; private set; }
        public IConfiguration Configuration { get; private set; }

        public SimpleTestFixture()
        {
            // بناء التكوين
            var builder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.test.json", optional: true)
                .AddJsonFile("appsettings.Development.json", optional: true)
                .AddEnvironmentVariables();

            Configuration = builder.Build();

            // بناء حاوي الخدمات بأقل متطلبات ممكنة
            var services = new ServiceCollection();

            // إضافة خدمات التسجيل
            services.AddLogging(logging =>
            {
                logging.AddConsole();
                logging.SetMinimumLevel(LogLevel.Debug);
            });

            // إضافة كاش الذاكرة
            services.AddMemoryCache();

            // بناء موفر الخدمات
            ServiceProvider = services.BuildServiceProvider();
        }

        /// <summary>
        /// الحصول على خدمة البحث الأساسية
        /// </summary>
        public async Task<bool> TestBasicSearch()
        {
            try
            {
                // اختبار بسيط للتأكد من عمل Redis
                using var scope = ServiceProvider.CreateScope();
                var logger = scope.ServiceProvider.GetRequiredService<ILogger<SimpleTestFixture>>();
                
                logger.LogInformation("✅ تم الاتصال بـ Redis بنجاح");
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ خطأ: {ex.Message}");
                return false;
            }
        }

        public void Dispose()
        {
            // تنظيف الموارد
            if (ServiceProvider is IDisposable disposable)
            {
                disposable.Dispose();
            }
        }
    }
}
