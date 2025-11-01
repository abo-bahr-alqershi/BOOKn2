using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.IndexingTests.Tests.Search
{
    /// <summary>
    /// اختبارات البحث النصي الشاملة
    /// </summary>
    public class TextSearchTests : TestBase
    {
        public TextSearchTests(TestDatabaseFixture fixture, ITestOutputHelper output)
            : base(fixture, output)
        {
        }

        /// <summary>
        /// اختبار البحث النصي البسيط
        /// </summary>
        [Theory]
        [InlineData("فندق")]
        [InlineData("شقة")]
        [InlineData("منتجع")]
        [InlineData("الملكي")]
        [InlineData("صنعاء")]
        public async Task Test_TextSearch_FindsMatchingProperties(string searchText)
        {
            _output.WriteLine($"🔍 اختبار البحث النصي: '{searchText}'");

            // الإعداد
            var properties = new List<Property>
            {
                await CreateTestPropertyAsync("فندق الملكي", "صنعاء"),
                await CreateTestPropertyAsync("شقة مفروشة فاخرة", "عدن"),
                await CreateTestPropertyAsync("منتجع البحر الأحمر", "الحديدة"),
                await CreateTestPropertyAsync("فندق النخيل", "تعز"),
                await CreateTestPropertyAsync("شقق الياسمين", "صنعاء")
            };

            foreach (var prop in properties)
            {
                await _indexingService.OnPropertyCreatedAsync(prop.Id);
            }

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                SearchText = searchText,
                PageNumber = 1,
                PageSize = 20
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.True(result.TotalCount > 0, $"لم يتم العثور على نتائج للبحث '{searchText}'");

            foreach (var property in result.Properties)
            {
                var hasMatch = property.Name.Contains(searchText, StringComparison.OrdinalIgnoreCase) ||
                              property.City.Contains(searchText, StringComparison.OrdinalIgnoreCase);
                Assert.True(hasMatch, $"العقار '{property.Name}' لا يحتوي على '{searchText}'");
            }

            _output.WriteLine($"✅ تم العثور على {result.TotalCount} نتيجة للبحث '{searchText}'");
        }

        /// <summary>
        /// اختبار البحث بكلمات متعددة
        /// </summary>
        [Fact]
        public async Task Test_MultiWordSearch_FindsRelevantResults()
        {
            _output.WriteLine("🔍 اختبار البحث بكلمات متعددة...");

            // الإعداد
            await CreateTestPropertyAsync("فندق البحر الأزرق", "عدن");
            await CreateTestPropertyAsync("منتجع الجبل الأخضر", "إب");
            await CreateTestPropertyAsync("فندق النجوم الذهبية", "صنعاء");

            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "فندق البحر",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.True(result.TotalCount > 0);

            _output.WriteLine($"✅ البحث بكلمات متعددة أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار البحث بنص فارغ
        /// </summary>
        [Fact]
        public async Task Test_EmptySearch_ReturnsAllProperties()
        {
            _output.WriteLine("🔍 اختبار البحث بنص فارغ...");

            // الإعداد
            var properties = await CreateComprehensiveTestDataAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "",
                PageNumber = 1,
                PageSize = 100
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.True(result.TotalCount >= properties.Count(p => p.IsActive && p.IsApproved));

            _output.WriteLine($"✅ البحث الفارغ أرجع جميع العقارات: {result.TotalCount}");
        }

        /// <summary>
        /// اختبار البحث بأحرف خاصة
        /// </summary>
        [Theory]
        [InlineData("فندق@#$")]
        [InlineData("123456")]
        [InlineData("!!!")]
        [InlineData("' OR 1=1 --")]  // SQL Injection test
        public async Task Test_SpecialCharacterSearch_HandledSafely(string searchText)
        {
            _output.WriteLine($"🔍 اختبار البحث بأحرف خاصة: '{searchText}'");

            // الإعداد
            await CreateTestPropertyAsync("فندق عادي", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث - يجب ألا يفشل
            var exception = await Record.ExceptionAsync(async () =>
            {
                var searchRequest = new PropertySearchRequest
                {
                    SearchText = searchText,
                    PageNumber = 1,
                    PageSize = 10
                };

                await _indexingService.SearchAsync(searchRequest);
            });

            Assert.Null(exception);

            _output.WriteLine($"✅ تم التعامل مع البحث بأحرف خاصة بأمان");
        }

        /// <summary>
        /// اختبار البحث بحالات أحرف مختلفة
        /// </summary>
        [Theory]
        [InlineData("فندق", "فندق")]
        [InlineData("فندق", "فندق")]
        [InlineData("فنـدق", "فندق")]
        public async Task Test_CaseInsensitiveSearch(string searchTerm, string expectedMatch)
        {
            _output.WriteLine($"🔍 اختبار البحث غير الحساس لحالة الأحرف: '{searchTerm}'");

            // الإعداد
            await CreateTestPropertyAsync(expectedMatch, "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                SearchText = searchTerm,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.True(result.TotalCount > 0);

            _output.WriteLine($"✅ البحث بـ '{searchTerm}' وجد '{expectedMatch}'");
        }

        /// <summary>
        /// اختبار البحث بنص طويل جداً
        /// </summary>
        [Fact]
        public async Task Test_VeryLongSearchText_HandledProperly()
        {
            _output.WriteLine("🔍 اختبار البحث بنص طويل جداً...");

            // إنشاء نص طويل جداً
            var longText = string.Concat(Enumerable.Repeat("فندق ", 1000));

            // البحث - يجب ألا يفشل
            var exception = await Record.ExceptionAsync(async () =>
            {
                var searchRequest = new PropertySearchRequest
                {
                    SearchText = longText,
                    PageNumber = 1,
                    PageSize = 10
                };

                await _indexingService.SearchAsync(searchRequest);
            });

            Assert.Null(exception);

            _output.WriteLine("✅ تم التعامل مع النص الطويل بنجاح");
        }
    }
}
