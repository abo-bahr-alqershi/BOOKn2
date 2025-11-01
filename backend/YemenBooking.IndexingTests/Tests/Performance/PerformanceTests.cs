using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.IndexingTests.Tests.Performance
{
    /// <summary>
    /// اختبارات الأداء الشاملة
    /// تقيس سرعة وكفاءة العمليات المختلفة
    /// </summary>
    public class PerformanceTests : TestBase
    {
        public PerformanceTests(TestDatabaseFixture fixture, ITestOutputHelper output)
            : base(fixture, output)
        {
        }

        #region اختبارات أداء الفهرسة

        /// <summary>
        /// اختبار سرعة فهرسة عقار واحد
        /// </summary>
        [Fact]
        public async Task Test_SinglePropertyIndexingPerformance()
        {
            _output.WriteLine("⚡ اختبار أداء فهرسة عقار واحد...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق للاختبار", "صنعاء");

            // قياس الأداء
            var stopwatch = Stopwatch.StartNew();
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            stopwatch.Stop();

            // التحقق
            Assert.True(stopwatch.ElapsedMilliseconds < 100, 
                $"فهرسة عقار واحد استغرقت {stopwatch.ElapsedMilliseconds}ms (يجب أن تكون < 100ms)");

            _output.WriteLine($"✅ فهرسة عقار واحد تمت في {stopwatch.ElapsedMilliseconds}ms");
        }

        /// <summary>
        /// اختبار سرعة فهرسة عقارات متعددة
        /// </summary>
        [Theory]
        [InlineData(10)]
        [InlineData(50)]
        [InlineData(100)]
        public async Task Test_BulkIndexingPerformance(int count)
        {
            _output.WriteLine($"⚡ اختبار أداء فهرسة {count} عقار...");

            // الإعداد
            var properties = new List<Property>();
            for (int i = 0; i < count; i++)
            {
                properties.Add(await CreateTestPropertyAsync($"عقار {i}", "صنعاء"));
            }

            // قياس الأداء
            var stopwatch = Stopwatch.StartNew();
            foreach (var property in properties)
            {
                await _indexingService.OnPropertyCreatedAsync(property.Id);
            }
            stopwatch.Stop();

            var avgTimePerProperty = stopwatch.ElapsedMilliseconds / (double)count;
            var maxAcceptableTime = count * 50; // 50ms لكل عقار

            // التحقق
            Assert.True(stopwatch.ElapsedMilliseconds < maxAcceptableTime, 
                $"فهرسة {count} عقار استغرقت {stopwatch.ElapsedMilliseconds}ms (يجب أن تكون < {maxAcceptableTime}ms)");

            _output.WriteLine($"✅ فهرسة {count} عقار تمت في {stopwatch.ElapsedMilliseconds}ms");
            _output.WriteLine($"   متوسط الوقت لكل عقار: {avgTimePerProperty:F2}ms");
        }

        /// <summary>
        /// اختبار أداء إعادة بناء الفهرس
        /// </summary>
        [Theory]
        [InlineData(100)]
        [InlineData(500)]
        public async Task Test_RebuildIndexPerformance(int propertyCount)
        {
            _output.WriteLine($"⚡ اختبار أداء إعادة بناء الفهرس لـ {propertyCount} عقار...");

            // الإعداد - إنشاء عقارات
            for (int i = 0; i < propertyCount; i++)
            {
                await CreateTestPropertyAsync($"عقار {i}", i % 2 == 0 ? "صنعاء" : "عدن");
            }

            // قياس الأداء
            var stopwatch = Stopwatch.StartNew();
            await _indexingService.RebuildIndexAsync();
            stopwatch.Stop();

            var maxAcceptableTime = propertyCount * 20; // 20ms لكل عقار

            // التحقق
            Assert.True(stopwatch.ElapsedMilliseconds < maxAcceptableTime, 
                $"إعادة بناء الفهرس لـ {propertyCount} عقار استغرقت {stopwatch.ElapsedMilliseconds}ms");

            _output.WriteLine($"✅ إعادة بناء الفهرس تمت في {stopwatch.ElapsedMilliseconds}ms");
            _output.WriteLine($"   معدل المعالجة: {propertyCount / (stopwatch.ElapsedMilliseconds / 1000.0):F0} عقار/ثانية");
        }

        #endregion

        #region اختبارات أداء البحث

        /// <summary>
        /// اختبار أداء البحث البسيط
        /// </summary>
        [Fact]
        public async Task Test_SimpleSearchPerformance()
        {
            _output.WriteLine("⚡ اختبار أداء البحث البسيط...");

            // الإعداد
            await CreateComprehensiveTestDataAsync();

            // قياس الأداء - 100 عملية بحث
            var searches = 100;
            var stopwatch = Stopwatch.StartNew();
            
            for (int i = 0; i < searches; i++)
            {
                var searchRequest = new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 20
                };

                await _indexingService.SearchAsync(searchRequest);
            }
            
            stopwatch.Stop();

            var avgSearchTime = stopwatch.ElapsedMilliseconds / (double)searches;

            // التحقق
            Assert.True(avgSearchTime < 50, 
                $"متوسط وقت البحث البسيط {avgSearchTime:F2}ms (يجب أن يكون < 50ms)");

            _output.WriteLine($"✅ {searches} عملية بحث تمت في {stopwatch.ElapsedMilliseconds}ms");
            _output.WriteLine($"   متوسط الوقت لكل بحث: {avgSearchTime:F2}ms");
        }

        /// <summary>
        /// اختبار أداء البحث المعقد
        /// </summary>
        [Fact]
        public async Task Test_ComplexSearchPerformance()
        {
            _output.WriteLine("⚡ اختبار أداء البحث المعقد...");

            // الإعداد
            await CreateComprehensiveTestDataAsync();

            // البحث المعقد بفلاتر متعددة
            var searchRequest = new PropertySearchRequest
            {
                SearchText = "فندق",
                City = "صنعاء",
                PropertyType = "30000000-0000-0000-0000-000000000003",
                MinPrice = 100,
                MaxPrice = 1000,
                MinRating = 3,
                GuestsCount = 4,
                CheckIn = DateTime.Now.AddDays(30),
                CheckOut = DateTime.Now.AddDays(35),
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["has_pool"] = "true",
                    ["has_gym"] = "true"
                },
                PageNumber = 1,
                PageSize = 20
            };

            // قياس الأداء
            var searches = 50;
            var stopwatch = Stopwatch.StartNew();
            
            for (int i = 0; i < searches; i++)
            {
                await _indexingService.SearchAsync(searchRequest);
            }
            
            stopwatch.Stop();

            var avgSearchTime = stopwatch.ElapsedMilliseconds / (double)searches;

            // التحقق
            Assert.True(avgSearchTime < 100, 
                $"متوسط وقت البحث المعقد {avgSearchTime:F2}ms (يجب أن يكون < 100ms)");

            _output.WriteLine($"✅ {searches} عملية بحث معقدة تمت في {stopwatch.ElapsedMilliseconds}ms");
            _output.WriteLine($"   متوسط الوقت لكل بحث: {avgSearchTime:F2}ms");
        }

        /// <summary>
        /// اختبار أداء البحث مع عدد كبير من النتائج
        /// </summary>
        [Theory]
        [InlineData(100)]
        [InlineData(500)]
        [InlineData(1000)]
        public async Task Test_LargeResultSetPerformance(int pageSize)
        {
            _output.WriteLine($"⚡ اختبار أداء البحث مع {pageSize} نتيجة...");

            // الإعداد - إنشاء عقارات كافية
            for (int i = 0; i < pageSize + 10; i++)
            {
                await CreateTestPropertyAsync($"عقار {i}", "صنعاء");
            }
            await _indexingService.RebuildIndexAsync();

            // قياس الأداء
            var searchRequest = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = pageSize
            };

            var stopwatch = Stopwatch.StartNew();
            var result = await _indexingService.SearchAsync(searchRequest);
            stopwatch.Stop();

            // التحقق
            Assert.NotNull(result);
            Assert.True(stopwatch.ElapsedMilliseconds < pageSize * 2, 
                $"البحث بـ {pageSize} نتيجة استغرق {stopwatch.ElapsedMilliseconds}ms");

            _output.WriteLine($"✅ البحث بـ {pageSize} نتيجة تم في {stopwatch.ElapsedMilliseconds}ms");
        }

        #endregion

        #region اختبارات أداء التحديث والحذف

        /// <summary>
        /// اختبار أداء تحديث عقار
        /// </summary>
        [Fact]
        public async Task Test_UpdatePerformance()
        {
            _output.WriteLine("⚡ اختبار أداء تحديث العقارات...");

            // الإعداد
            var properties = new List<Property>();
            for (int i = 0; i < 100; i++)
            {
                var property = await CreateTestPropertyAsync($"عقار {i}", "صنعاء");
                await _indexingService.OnPropertyCreatedAsync(property.Id);
                properties.Add(property);
            }

            // قياس أداء التحديث
            var stopwatch = Stopwatch.StartNew();
            
            foreach (var property in properties)
            {
                property.Name = $"عقار محدث {property.Id}";
                property.City = "عدن";
                _dbContext.Properties.Update(property);
                await _indexingService.OnPropertyUpdatedAsync(property.Id);
            }
            
            stopwatch.Stop();

            var avgUpdateTime = stopwatch.ElapsedMilliseconds / (double)properties.Count;

            // التحقق
            Assert.True(avgUpdateTime < 50, 
                $"متوسط وقت التحديث {avgUpdateTime:F2}ms (يجب أن يكون < 50ms)");

            _output.WriteLine($"✅ تحديث {properties.Count} عقار تم في {stopwatch.ElapsedMilliseconds}ms");
            _output.WriteLine($"   متوسط الوقت لكل تحديث: {avgUpdateTime:F2}ms");
        }

        /// <summary>
        /// اختبار أداء الحذف
        /// </summary>
        [Fact]
        public async Task Test_DeletePerformance()
        {
            _output.WriteLine("⚡ اختبار أداء حذف العقارات...");

            // الإعداد
            var propertyIds = new List<Guid>();
            for (int i = 0; i < 100; i++)
            {
                var property = await CreateTestPropertyAsync($"عقار للحذف {i}", "صنعاء");
                await _indexingService.OnPropertyCreatedAsync(property.Id);
                propertyIds.Add(property.Id);
            }

            // قياس أداء الحذف
            var stopwatch = Stopwatch.StartNew();
            
            foreach (var propertyId in propertyIds)
            {
                await _indexingService.OnPropertyDeletedAsync(propertyId);
            }
            
            stopwatch.Stop();

            var avgDeleteTime = stopwatch.ElapsedMilliseconds / (double)propertyIds.Count;

            // التحقق
            Assert.True(avgDeleteTime < 30, 
                $"متوسط وقت الحذف {avgDeleteTime:F2}ms (يجب أن يكون < 30ms)");

            _output.WriteLine($"✅ حذف {propertyIds.Count} عقار تم في {stopwatch.ElapsedMilliseconds}ms");
            _output.WriteLine($"   متوسط الوقت لكل حذف: {avgDeleteTime:F2}ms");
        }

        #endregion

        #region اختبارات الذاكرة والموارد

        /// <summary>
        /// اختبار استهلاك الذاكرة
        /// </summary>
        [Fact]
        public async Task Test_MemoryUsage()
        {
            _output.WriteLine("💾 اختبار استهلاك الذاكرة...");

            // قياس الذاكرة قبل العملية
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            
            var memoryBefore = GC.GetTotalMemory(false);
            _output.WriteLine($"   الذاكرة قبل العملية: {memoryBefore / 1024 / 1024}MB");

            // إنشاء وفهرسة 1000 عقار
            for (int i = 0; i < 1000; i++)
            {
                var property = await CreateTestPropertyAsync($"عقار {i}", "صنعاء");
                await _indexingService.OnPropertyCreatedAsync(property.Id);
            }

            // قياس الذاكرة بعد العملية
            var memoryAfter = GC.GetTotalMemory(false);
            _output.WriteLine($"   الذاكرة بعد العملية: {memoryAfter / 1024 / 1024}MB");

            var memoryIncrease = (memoryAfter - memoryBefore) / 1024 / 1024; // بالميجابايت

            // التحقق
            Assert.True(memoryIncrease < 500, 
                $"استهلاك الذاكرة زاد بمقدار {memoryIncrease}MB (يجب أن يكون < 500MB)");

            // تنظيف
            GC.Collect();
            GC.WaitForPendingFinalizers();
            GC.Collect();
            
            var memoryAfterCleanup = GC.GetTotalMemory(false);
            _output.WriteLine($"   الذاكرة بعد التنظيف: {memoryAfterCleanup / 1024 / 1024}MB");

            _output.WriteLine($"✅ استهلاك الذاكرة ضمن الحدود المقبولة");
        }

        #endregion

        #region اختبارات التزامن والضغط

        /// <summary>
        /// اختبار البحث المتزامن
        /// </summary>
        [Fact]
        public async Task Test_ConcurrentSearchPerformance()
        {
            _output.WriteLine("⚡ اختبار أداء البحث المتزامن...");

            // الإعداد
            await CreateComprehensiveTestDataAsync();

            // البحث المتزامن - 100 عملية بحث متزامنة
            var concurrentSearches = 100;
            var searchTasks = new List<Task<PropertySearchResult>>();

            var stopwatch = Stopwatch.StartNew();
            
            for (int i = 0; i < concurrentSearches; i++)
            {
                var searchRequest = new PropertySearchRequest
                {
                    City = i % 2 == 0 ? "صنعاء" : "عدن",
                    PageNumber = 1,
                    PageSize = 10
                };

                searchTasks.Add(Task.Run(async () => 
                    await _indexingService.SearchAsync(searchRequest)));
            }

            await Task.WhenAll(searchTasks);
            stopwatch.Stop();

            // التحقق
            Assert.All(searchTasks, t => Assert.NotNull(t.Result));
            Assert.True(stopwatch.ElapsedMilliseconds < 5000, 
                $"{concurrentSearches} عملية بحث متزامنة استغرقت {stopwatch.ElapsedMilliseconds}ms");

            _output.WriteLine($"✅ {concurrentSearches} عملية بحث متزامنة تمت في {stopwatch.ElapsedMilliseconds}ms");
            _output.WriteLine($"   معدل الإنجاز: {concurrentSearches / (stopwatch.ElapsedMilliseconds / 1000.0):F0} بحث/ثانية");
        }

        /// <summary>
        /// اختبار الفهرسة المتزامنة
        /// </summary>
        [Fact]
        public async Task Test_ConcurrentIndexingPerformance()
        {
            _output.WriteLine("⚡ اختبار أداء الفهرسة المتزامنة...");

            // الإعداد - إنشاء عقارات
            var properties = new List<Property>();
            for (int i = 0; i < 100; i++)
            {
                properties.Add(await CreateTestPropertyAsync($"عقار متزامن {i}", "صنعاء"));
            }

            // الفهرسة المتزامنة
            var stopwatch = Stopwatch.StartNew();
            
            var indexingTasks = properties.Select(p => 
                Task.Run(async () => await _indexingService.OnPropertyCreatedAsync(p.Id))
            ).ToArray();

            await Task.WhenAll(indexingTasks);
            stopwatch.Stop();

            // التحقق
            Assert.True(stopwatch.ElapsedMilliseconds < 5000, 
                $"فهرسة {properties.Count} عقار بشكل متزامن استغرقت {stopwatch.ElapsedMilliseconds}ms");

            _output.WriteLine($"✅ فهرسة {properties.Count} عقار بشكل متزامن تمت في {stopwatch.ElapsedMilliseconds}ms");
        }

        /// <summary>
        /// اختبار الأداء تحت الضغط
        /// </summary>
        [Fact]
        public async Task Test_StressTestPerformance()
        {
            _output.WriteLine("🔥 اختبار الأداء تحت الضغط...");

            // الإعداد
            await CreateComprehensiveTestDataAsync();

            // محاكاة الضغط - عمليات متنوعة متزامنة
            var tasks = new List<Task>();
            var stopwatch = Stopwatch.StartNew();

            // 50 عملية بحث
            for (int i = 0; i < 50; i++)
            {
                tasks.Add(Task.Run(async () =>
                {
                    var searchRequest = new PropertySearchRequest
                    {
                        City = i % 3 == 0 ? "صنعاء" : i % 3 == 1 ? "عدن" : "تعز",
                        PageNumber = 1,
                        PageSize = 10
                    };
                    await _indexingService.SearchAsync(searchRequest);
                }));
            }

            // 20 عملية فهرسة
            for (int i = 0; i < 20; i++)
            {
                var property = await CreateTestPropertyAsync($"عقار ضغط {i}", "صنعاء");
                tasks.Add(Task.Run(async () =>
                    await _indexingService.OnPropertyCreatedAsync(property.Id)));
            }

            // 10 عمليات تحديث
            var existingProperties = _dbContext.Properties.Take(10).ToList();
            foreach (var prop in existingProperties)
            {
                tasks.Add(Task.Run(async () =>
                    await _indexingService.OnPropertyUpdatedAsync(prop.Id)));
            }

            await Task.WhenAll(tasks);
            stopwatch.Stop();

            // التحقق
            Assert.True(stopwatch.ElapsedMilliseconds < 10000, 
                $"اختبار الضغط (80 عملية متزامنة) استغرق {stopwatch.ElapsedMilliseconds}ms");

            _output.WriteLine($"✅ اختبار الضغط تم بنجاح في {stopwatch.ElapsedMilliseconds}ms");
            _output.WriteLine($"   إجمالي العمليات: {tasks.Count}");
            _output.WriteLine($"   معدل الإنجاز: {tasks.Count / (stopwatch.ElapsedMilliseconds / 1000.0):F0} عملية/ثانية");
        }

        #endregion
    }
}
