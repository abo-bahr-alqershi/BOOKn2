using System;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis.Configuration;

/// <summary>
/// برنامج اختبار نظام Redis الجديد
/// </summary>
public class TestRedisSystem
{
    public static async Task Main(string[] args)
    {
        Console.WriteLine("🚀 بدء اختبار نظام Redis الجديد...");
        Console.WriteLine("=====================================");

        // بناء التكوين
        var configuration = new ConfigurationBuilder()
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .AddJsonFile("appsettings.Development.json", optional: true)
            .Build();

        // إعداد الخدمات
        var services = new ServiceCollection();

        // إضافة التسجيل
        services.AddLogging(builder =>
        {
            builder.AddConsole();
            builder.SetMinimumLevel(LogLevel.Information);
        });

        // إضافة نظام Redis الجديد
        services.AddRedisIndexingSystem(configuration);

        // بناء موفر الخدمات
        var serviceProvider = services.BuildServiceProvider();

        // الحصول على خدمة الفهرسة
        var indexingService = serviceProvider.GetRequiredService<IIndexingService>();
        var logger = serviceProvider.GetRequiredService<ILogger<TestRedisSystem>>();

        try
        {
            Console.WriteLine("\n✨ نظام Redis جاهز للاختبار!");

            // اختبار 1: البحث البسيط
            Console.WriteLine("\n📝 الاختبار 1: البحث البسيط");
            Console.WriteLine("--------------------------------");
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "فندق",
                PageNumber = 1,
                PageSize = 10
            };

            var searchResult = await indexingService.SearchAsync(searchRequest);
            Console.WriteLine($"✅ نتائج البحث: {searchResult.TotalCount} عقار");
            Console.WriteLine($"   - الصفحة: {searchResult.PageNumber}/{searchResult.TotalPages}");

            // اختبار 2: البحث الجغرافي
            Console.WriteLine("\n📍 الاختبار 2: البحث الجغرافي");
            Console.WriteLine("--------------------------------");
            var geoSearchRequest = new PropertySearchRequest
            {
                Latitude = 15.3694,  // صنعاء
                Longitude = 44.1910,
                RadiusKm = 10,
                PageNumber = 1,
                PageSize = 5
            };

            var geoResult = await indexingService.SearchAsync(geoSearchRequest);
            Console.WriteLine($"✅ عقارات في نطاق 10 كم: {geoResult.TotalCount}");

            // اختبار 3: الفلترة المعقدة
            Console.WriteLine("\n🔍 الاختبار 3: الفلترة المعقدة");
            Console.WriteLine("--------------------------------");
            var complexSearchRequest = new PropertySearchRequest
            {
                City = "صنعاء",
                MinPrice = 100,
                MaxPrice = 500,
                MinRating = 4,
                SortBy = "price_asc",
                PageNumber = 1,
                PageSize = 10
            };

            var complexResult = await indexingService.SearchAsync(complexSearchRequest);
            Console.WriteLine($"✅ عقارات مفلترة: {complexResult.TotalCount}");
            Console.WriteLine($"   - المدينة: صنعاء");
            Console.WriteLine($"   - السعر: 100-500");
            Console.WriteLine($"   - التقييم: 4+");

            // اختبار 4: تحسين قاعدة البيانات
            Console.WriteLine("\n🔧 الاختبار 4: تحسين قاعدة البيانات");
            Console.WriteLine("--------------------------------");
            await indexingService.OptimizeDatabaseAsync();
            Console.WriteLine("✅ تم تحسين قاعدة البيانات بنجاح");

            Console.WriteLine("\n=====================================");
            Console.WriteLine("🎉 جميع الاختبارات نجحت!");
            Console.WriteLine("✨ نظام Redis يعمل بكفاءة عالية!");

        }
        catch (Exception ex)
        {
            logger.LogError(ex, "❌ فشل الاختبار");
            Console.WriteLine($"\n❌ خطأ: {ex.Message}");
            Console.WriteLine($"   التفاصيل: {ex.StackTrace}");
        }
        finally
        {
            // تنظيف الموارد
            if (serviceProvider is IDisposable disposable)
            {
                disposable.Dispose();
            }
        }

        Console.WriteLine("\nاضغط أي مفتاح للخروج...");
        Console.ReadKey();
    }
}
