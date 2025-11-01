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
using Microsoft.Extensions.Hosting;

namespace YemenBooking.IndexingTests
{
    /// <summary>
    /// إعداد بيئة الاختبار
    /// </summary>
    public class TestFixture : IDisposable
    {
        public IServiceProvider ServiceProvider { get; private set; }
        public IConfiguration Configuration { get; private set; }
        private readonly SemaphoreSlim _initializationLock = new SemaphoreSlim(1, 1);
        private bool _isInitialized = false;

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
            
            // إضافة بيئة اختبار لتجنب مشاكل التزامن
            // ليس هناك حاجة لـ IHostEnvironment في اختبارات الفهرسة

            // إضافة خدمات التسجيل
            services.AddLogging(logging =>
            {
                logging.AddConsole();
                logging.SetMinimumLevel(LogLevel.Warning); // تقليل مستوى التسجيل
            });

            // إضافة كاش الذاكرة
            services.AddMemoryCache();
            
            // إضافة HttpContextAccessor
            services.AddSingleton<Microsoft.AspNetCore.Http.IHttpContextAccessor, Microsoft.AspNetCore.Http.HttpContextAccessor>();

            // إضافة قاعدة البيانات مع timeout قصير
            services.AddDbContext<YemenBookingDbContext>(options =>
            {
                options.UseNpgsql(Configuration.GetConnectionString("DefaultConnection"),
                    npgsqlOptions => 
                    {
                        npgsqlOptions.CommandTimeout(10); // timeout 10 ثواني
                        npgsqlOptions.EnableRetryOnFailure(0); // تعطيل إعادة المحاولة
                    });
                options.EnableSensitiveDataLogging(false);
                options.EnableServiceProviderCaching(true); // تفعيل التخزين المؤقت
            }, ServiceLifetime.Scoped); // استخدام Scoped لإعادة استخدام نفس DbContext في نفس الـ scope

            // إضافة المستودعات - استخدام Scoped لتتماشى مع DbContext
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

            // إضافة نظام Redis للفهرسة مع تكوين محسن
            var redisConfig = Configuration.GetSection("Redis");
            if (string.IsNullOrEmpty(redisConfig["Connection"]))
            {
                // استخدام إعدادات افتراضية إذا لم تكن موجودة
                Configuration["Redis:Connection"] = "localhost:6379,connectTimeout=2000,syncTimeout=2000,abortConnect=false,connectRetry=1";
                Configuration["Redis:Database"] = "1";
            }
            
            // إضافة خدمات Redis بشكل آمن
            try
            {
                services.AddRedisIndexingSystem(Configuration);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"⚠️ خطأ في إضافة نظام Redis: {ex.Message}");
                // الاستمرار دون Redis للاختبارات الأخرى
            }

            // بناء موفر الخدمات
            ServiceProvider = services.BuildServiceProvider();

            // لا نقوم بأي تهيئة مسبقة للبيانات لتجنب التأخير
            Console.WriteLine("✅ TestFixture initialized without pre-loading data");
            _isInitialized = true;
        }

        /// <summary>
        /// تهيئة البيانات الاختبارية بشكل غير متزامن
        /// </summary>
        public async Task InitializeTestDataAsync()
        {
            // تجنب التهيئة المتعددة
            await _initializationLock.WaitAsync();
            try
            {
                if (!_isInitialized)
                {
                    Console.WriteLine("⚠️ TestFixture not properly initialized");
                    return;
                }
                
                // نتجاهل إعادة بناء الفهرس للاختبارات لتجنب مشاكل الاتصال بقاعدة البيانات
                Console.WriteLine("ℹ️ تجاهل إعادة بناء الفهرس للاختبارات - استخدام Redis فقط");
            }
            finally
            {
                _initializationLock.Release();
            }
        }

        public void Dispose()
        {
            // تنظيف الموارد
            _initializationLock?.Dispose();
            if (ServiceProvider is IDisposable disposable)
            {
                disposable.Dispose();
            }
        }
    }
}
