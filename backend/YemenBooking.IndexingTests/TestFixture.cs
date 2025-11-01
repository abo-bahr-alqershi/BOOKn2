using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis.Configuration;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Repositories;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Pricing.Services;

namespace YemenBooking.IndexingTests
{
    /// <summary>
    /// إعداد بيئة الاختبار
    /// </summary>
    public class TestFixture : IDisposable
    {
        public IServiceProvider ServiceProvider { get; private set; }
        public IConfiguration Configuration { get; private set; }

        public TestFixture()
        {
            // بناء التكوين
            var builder = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.test.json", optional: true)
                .AddJsonFile("appsettings.Development.json", optional: true)
                .AddEnvironmentVariables();

            Configuration = builder.Build();

            // بناء حاوي الخدمات
            var services = new ServiceCollection();

            // إضافة خدمات التسجيل
            services.AddLogging(logging =>
            {
                logging.AddConsole();
                logging.SetMinimumLevel(LogLevel.Debug);
            });

            // إضافة كاش الذاكرة
            services.AddMemoryCache();
            
            // إضافة HttpContextAccessor
            services.AddSingleton<Microsoft.AspNetCore.Http.IHttpContextAccessor, Microsoft.AspNetCore.Http.HttpContextAccessor>();

            // إضافة قاعدة البيانات
            services.AddDbContext<YemenBookingDbContext>(options =>
                options.UseNpgsql(Configuration.GetConnectionString("DefaultConnection")));

            // إضافة المستودعات
            services.AddScoped<IPropertyRepository, PropertyRepository>();
            services.AddScoped<IUnitRepository, UnitRepository>();
            services.AddScoped<IReviewRepository, ReviewRepository>();
            services.AddScoped<ICurrencyExchangeRepository, CurrencyExchangeRepository>();
            services.AddScoped<IBookingRepository, BookingRepository>();
            services.AddScoped<IUserRepository, UserRepository>();
            services.AddScoped<IAmenityRepository, AmenityRepository>();
            services.AddScoped<IPropertyTypeRepository, PropertyTypeRepository>();

            // إضافة الخدمات الأساسية (وهمية للاختبار)
            services.AddScoped<IAvailabilityService, MockAvailabilityService>();
            services.AddScoped<IPricingService, MockPricingService>();

            // إضافة نظام Redis للفهرسة
            services.AddRedisIndexingSystem(Configuration);

            // بناء موفر الخدمات
            ServiceProvider = services.BuildServiceProvider();

            // تهيئة البيانات الاختبارية
            InitializeTestData().Wait();
        }

        /// <summary>
        /// تهيئة البيانات الاختبارية
        /// </summary>
        private async Task InitializeTestData()
        {
            using var scope = ServiceProvider.CreateScope();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            try
            {
                // إعادة بناء الفهرس
                await indexingService.RebuildIndexAsync();
                Console.WriteLine("✅ تمت إعادة بناء الفهرس بنجاح");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ خطأ في إعادة بناء الفهرس: {ex.Message}");
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
