using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Redis.Configuration;
using YemenBooking.Core.Entities;
using System.Diagnostics;

namespace YemenBooking.IndexingTests
{
    /// <summary>
    /// اختبارات شاملة لنظام الفهرسة والبحث
    /// يغطي جميع الحالات المتوقعة وغير المتوقعة
    /// </summary>
    public class ComprehensiveIndexingTests : IClassFixture<TestFixture>
    {
        private readonly TestFixture _fixture;
        private readonly ITestOutputHelper _output;
        private readonly IIndexingService _indexingService;
        private readonly ILogger<ComprehensiveIndexingTests> _logger;

        public ComprehensiveIndexingTests(TestFixture fixture, ITestOutputHelper output)
        {
            _fixture = fixture;
            _output = output;
            _indexingService = _fixture.ServiceProvider.GetRequiredService<IIndexingService>();
            _logger = _fixture.ServiceProvider.GetRequiredService<ILogger<ComprehensiveIndexingTests>>();
        }

        #region اختبارات الاتصال الأساسية

        /// <summary>
        /// اختبار الاتصال بـ Redis
        /// </summary>
        [Fact]
        public async Task Test_001_RedisConnection()
        {
            _output.WriteLine("🔍 اختبار الاتصال بـ Redis...");
            
            var request = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 1
            };

            var result = await _indexingService.SearchAsync(request);
            
            Assert.NotNull(result);
            _output.WriteLine($"✅ Redis متصل - العدد الكلي: {result.TotalCount}");
        }

        #endregion

        #region اختبارات البحث الأساسي

        /// <summary>
        /// اختبار البحث بدون فلاتر
        /// </summary>
        [Fact]
        public async Task Test_002_SearchWithoutFilters()
        {
            _output.WriteLine("🔍 اختبار البحث بدون فلاتر...");
            
            var request = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 20
            };

            var result = await _indexingService.SearchAsync(request);
            
            Assert.NotNull(result);
            Assert.NotNull(result.Properties);
            Assert.True(result.TotalCount >= 0);
            
            _output.WriteLine($"✅ النتائج: {result.Properties.Count} من {result.TotalCount}");
        }

        /// <summary>
        /// اختبار البحث النصي
        /// </summary>
        [Theory]
        [InlineData("فندق")]
        [InlineData("شقق")]
        [InlineData("منتجع")]
        public async Task Test_003_TextSearch(string searchText)
        {
            _output.WriteLine($"🔍 اختبار البحث النصي: '{searchText}'");
            
            var request = new PropertySearchRequest
            {
                SearchText = searchText,
                PageNumber = 1,
                PageSize = 20
            };

            var result = await _indexingService.SearchAsync(request);
            
            Assert.NotNull(result);
            _output.WriteLine($"✅ تم العثور على {result.TotalCount} نتيجة للبحث '{searchText}'");
        }

        #endregion

        #region اختبارات فلترة الموقع

        /// <summary>
        /// اختبار البحث بالمدينة
        /// </summary>
        [Theory]
        [InlineData("صنعاء")]
        [InlineData("عدن")]
        public async Task Test_004_SearchByCity(string city)
        {
            _output.WriteLine($"🏙️ اختبار البحث في المدينة: {city}");
            
            var request = new PropertySearchRequest
            {
                City = city,
                PageNumber = 1,
                PageSize = 20
            };

            var result = await _indexingService.SearchAsync(request);
            
            Assert.NotNull(result);
            
            if (result.Properties?.Any() == true)
            {
                Assert.All(result.Properties, p => 
                    Assert.Equal(city, p.City, StringComparer.OrdinalIgnoreCase));
            }
            
            _output.WriteLine($"✅ تم العثور على {result.TotalCount} عقار في {city}");
        }

        #endregion

        #region اختبارات الفلاتر المركبة

        /// <summary>
        /// اختبار فلاتر متعددة معاً
        /// </summary>
        [Fact]
        public async Task Test_019_CombinedFilters()
        {
            _output.WriteLine("🔄 اختبار الفلاتر المركبة...");
            
            var request = new PropertySearchRequest
            {
                City = "صنعاء",
                MinPrice = 100,
                MaxPrice = 1000,
                MinRating = 3,
                GuestsCount = 2,
                PageNumber = 1,
                PageSize = 20
            };

            var result = await _indexingService.SearchAsync(request);
            
            Assert.NotNull(result);
            _output.WriteLine($"✅ تم العثور على {result.TotalCount} عقار مع جميع الفلاتر");
        }

        #endregion

        #region اختبارات الأداء

        /// <summary>
        /// اختبار سرعة البحث البسيط
        /// </summary>
        [Fact]
        public async Task Test_025_SimpleSearchPerformance()
        {
            _output.WriteLine("⚡ اختبار أداء البحث البسيط...");
            
            var request = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 20
            };

            var stopwatch = Stopwatch.StartNew();
            var result = await _indexingService.SearchAsync(request);
            stopwatch.Stop();
            
            Assert.NotNull(result);
            Assert.True(stopwatch.ElapsedMilliseconds < 1000, 
                $"البحث استغرق {stopwatch.ElapsedMilliseconds}ms (يجب أن يكون < 1000ms)");
            
            _output.WriteLine($"✅ البحث تم في {stopwatch.ElapsedMilliseconds}ms");
        }

        #endregion
    }
}
