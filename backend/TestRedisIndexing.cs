using System;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Redis.Configuration;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Persistence;
using YemenBooking.Infrastructure.Repositories;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using Microsoft.EntityFrameworkCore;

namespace YemenBooking.Tests
{
    /// <summary>
    /// برنامج اختبار شامل لنظام الفهرسة والبحث في Redis
    /// </summary>
    public class TestRedisIndexing
    {
        public static async Task Main(string[] args)
        {
            Console.WriteLine("🔍 بدء اختبار نظام الفهرسة والبحث في Redis...\n");
            
            // إعداد التكوين
            var configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetCurrentDirectory())
                .AddJsonFile("appsettings.json", optional: true)
                .AddJsonFile("appsettings.Development.json", optional: true)
                .Build();

            // إعداد الخدمات
            var services = new ServiceCollection();
            
            // إضافة خدمات التسجيل
            services.AddLogging(builder =>
            {
                builder.AddConsole();
                builder.SetMinimumLevel(LogLevel.Debug);
            });
            
            // إضافة كاش الذاكرة
            services.AddMemoryCache();
            
            // إضافة قاعدة البيانات
            services.AddDbContext<YemenBookingContext>(options =>
                options.UseNpgsql(configuration.GetConnectionString("DefaultConnection")));
            
            // إضافة المستودعات
            services.AddScoped<IPropertyRepository, PropertyRepository>();
            services.AddScoped<IUnitRepository, UnitRepository>();
            services.AddScoped<IReviewRepository, ReviewRepository>();
            services.AddScoped<ICurrencyExchangeRepository, CurrencyExchangeRepository>();
            services.AddScoped<IBookingRepository, BookingRepository>();
            
            // إضافة الخدمات
            services.AddScoped<IAvailabilityService, AvailabilityService>();
            services.AddScoped<IPricingService, PricingService>();
            
            // إضافة نظام Redis
            services.AddRedisIndexingSystem(configuration);
            
            try
            {
                var serviceProvider = services.BuildServiceProvider();
                var indexingService = serviceProvider.GetService<IIndexingService>();
                
                if (indexingService == null)
                {
                    Console.WriteLine("❌ خطأ: لم يتم تسجيل خدمة الفهرسة!");
                    return;
                }
                
                Console.WriteLine("✅ تم إنشاء خدمة الفهرسة بنجاح\n");
                
                // اختبار البحث البسيط
                Console.WriteLine("📋 اختبار البحث البسيط...");
                var searchRequest = new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 10,
                    City = "صنعاء"
                };
                
                try
                {
                    var searchResult = await indexingService.SearchAsync(searchRequest);
                    Console.WriteLine($"✅ البحث نجح! تم العثور على {searchResult.TotalCount} نتيجة");
                    
                    if (searchResult.Properties != null)
                    {
                        foreach (var property in searchResult.Properties.Take(3))
                        {
                            Console.WriteLine($"  - {property.Name} في {property.City}");
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"❌ خطأ في البحث: {ex.Message}");
                    Console.WriteLine($"   تفاصيل: {ex.StackTrace}");
                }
                
                // اختبار البحث مع فلتر النوع
                Console.WriteLine("\n📋 اختبار البحث مع فلتر نوع العقار...");
                searchRequest.PropertyType = "فندق";
                
                try
                {
                    var searchResult = await indexingService.SearchAsync(searchRequest);
                    Console.WriteLine($"✅ البحث مع الفلتر نجح! تم العثور على {searchResult.TotalCount} فندق");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"❌ خطأ في البحث مع الفلتر: {ex.Message}");
                }
                
                // اختبار البحث مع فلاتر متعددة
                Console.WriteLine("\n📋 اختبار البحث مع فلاتر متعددة...");
                searchRequest.MinPrice = 100;
                searchRequest.MaxPrice = 500;
                searchRequest.MinRating = 3;
                
                try
                {
                    var searchResult = await indexingService.SearchAsync(searchRequest);
                    Console.WriteLine($"✅ البحث مع الفلاتر المتعددة نجح! تم العثور على {searchResult.TotalCount} نتيجة");
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"❌ خطأ في البحث مع الفلاتر المتعددة: {ex.Message}");
                }
                
                Console.WriteLine("\n✅ اختبار النظام مكتمل!");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"❌ خطأ عام في النظام: {ex.Message}");
                Console.WriteLine($"   النوع: {ex.GetType().Name}");
                Console.WriteLine($"   التفاصيل: {ex.StackTrace}");
            }
        }
    }
}
