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
    /// اختبارات فلترة السعر والتقييم والسعة
    /// </summary>
    public class PriceRatingFilterTests : TestBase
    {
        public PriceRatingFilterTests(TestDatabaseFixture fixture, ITestOutputHelper output)
            : base(fixture, output)
        {
        }

        #region اختبارات فلترة السعر

        /// <summary>
        /// اختبار فلتر السعر الأدنى
        /// </summary>
        [Theory]
        [InlineData(100)]
        [InlineData(200)]
        [InlineData(500)]
        public async Task Test_MinPriceFilter_Success(decimal minPrice)
        {
            _output.WriteLine($"💰 اختبار فلتر السعر الأدنى: {minPrice} YER");

            // الإعداد
            await CreateTestPropertyAsync("عقار رخيص", "صنعاء", minPrice: 50);
            await CreateTestPropertyAsync("عقار متوسط", "صنعاء", minPrice: 150);
            await CreateTestPropertyAsync("عقار غالي", "صنعاء", minPrice: 300);
            await CreateTestPropertyAsync("عقار فاخر", "صنعاء", minPrice: 600);

            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                MinPrice = minPrice,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.All(result.Properties, p => 
                Assert.True(p.MinPrice >= minPrice, 
                    $"العقار {p.Name} سعره {p.MinPrice} أقل من {minPrice}"));

            _output.WriteLine($"✅ فلتر السعر الأدنى أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار فلتر السعر الأقصى
        /// </summary>
        [Theory]
        [InlineData(100)]
        [InlineData(300)]
        [InlineData(500)]
        public async Task Test_MaxPriceFilter_Success(decimal maxPrice)
        {
            _output.WriteLine($"💰 اختبار فلتر السعر الأقصى: {maxPrice} YER");

            // الإعداد
            await CreateTestPropertyAsync("عقار رخيص", "صنعاء", minPrice: 50);
            await CreateTestPropertyAsync("عقار متوسط", "صنعاء", minPrice: 200);
            await CreateTestPropertyAsync("عقار غالي", "صنعاء", minPrice: 400);
            await CreateTestPropertyAsync("عقار فاخر", "صنعاء", minPrice: 800);

            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                MaxPrice = maxPrice,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.All(result.Properties, p => 
                Assert.True(p.MinPrice <= maxPrice,
                    $"العقار {p.Name} سعره {p.MinPrice} أكثر من {maxPrice}"));

            _output.WriteLine($"✅ فلتر السعر الأقصى أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار فلتر نطاق السعر
        /// </summary>
        [Theory]
        [InlineData(100, 300)]
        [InlineData(200, 500)]
        [InlineData(0, 1000)]
        public async Task Test_PriceRangeFilter_Success(decimal minPrice, decimal maxPrice)
        {
            _output.WriteLine($"💰 اختبار نطاق السعر: {minPrice} - {maxPrice} YER");

            // الإعداد
            await CreateTestPropertyAsync("عقار 1", "صنعاء", minPrice: 50);
            await CreateTestPropertyAsync("عقار 2", "صنعاء", minPrice: 150);
            await CreateTestPropertyAsync("عقار 3", "صنعاء", minPrice: 250);
            await CreateTestPropertyAsync("عقار 4", "صنعاء", minPrice: 350);
            await CreateTestPropertyAsync("عقار 5", "صنعاء", minPrice: 600);

            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                MinPrice = minPrice,
                MaxPrice = maxPrice,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.All(result.Properties, p =>
            {
                Assert.True(p.MinPrice >= minPrice, 
                    $"العقار {p.Name} سعره {p.MinPrice} أقل من الحد الأدنى {minPrice}");
                Assert.True(p.MinPrice <= maxPrice,
                    $"العقار {p.Name} سعره {p.MinPrice} أكثر من الحد الأقصى {maxPrice}");
            });

            _output.WriteLine($"✅ فلتر نطاق السعر أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار فلتر سعر غير منطقي
        /// </summary>
        [Fact]
        public async Task Test_InvalidPriceRange_ReturnsEmpty()
        {
            _output.WriteLine("💰 اختبار نطاق سعر غير منطقي...");

            // الإعداد
            await CreateTestPropertyAsync("عقار", "صنعاء", minPrice: 200);
            await _indexingService.RebuildIndexAsync();

            // البحث - الحد الأدنى أكبر من الأقصى
            var searchRequest = new PropertySearchRequest
            {
                MinPrice = 500,
                MaxPrice = 100,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(0, result.TotalCount);

            _output.WriteLine("✅ نطاق السعر غير المنطقي أرجع 0 نتيجة");
        }

        /// <summary>
        /// اختبار فلتر سعر صفر
        /// </summary>
        [Fact]
        public async Task Test_ZeroPriceFilter_IncludesFreeProperties()
        {
            _output.WriteLine("💰 اختبار فلتر سعر صفر...");

            // الإعداد
            await CreateTestPropertyAsync("عقار مجاني", "صنعاء", minPrice: 0);
            await CreateTestPropertyAsync("عقار مدفوع", "صنعاء", minPrice: 100);

            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                MaxPrice = 0,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(1, result.TotalCount);
            Assert.Equal("عقار مجاني", result.Properties.First().Name);

            _output.WriteLine("✅ فلتر السعر صفر أرجع العقارات المجانية فقط");
        }

        /// <summary>
        /// اختبار فلتر سعر سالب
        /// </summary>
        [Theory]
        [InlineData(-100)]
        [InlineData(-1)]
        public async Task Test_NegativePriceFilter_HandledGracefully(decimal negativePrice)
        {
            _output.WriteLine($"💰 اختبار فلتر سعر سالب: {negativePrice}");

            // الإعداد
            await CreateTestPropertyAsync("عقار", "صنعاء", minPrice: 100);
            await _indexingService.RebuildIndexAsync();

            // البحث - يجب ألا يفشل
            var exception = await Record.ExceptionAsync(async () =>
            {
                var searchRequest = new PropertySearchRequest
                {
                    MinPrice = negativePrice,
                    PageNumber = 1,
                    PageSize = 10
                };

                await _indexingService.SearchAsync(searchRequest);
            });

            Assert.Null(exception);
            _output.WriteLine("✅ تم التعامل مع السعر السالب بنجاح");
        }

        #endregion

        #region اختبارات فلتر التقييم

        /// <summary>
        /// اختبار فلتر التقييم الأدنى
        /// </summary>
        [Theory]
        [InlineData(3.0)]
        [InlineData(3.5)]
        [InlineData(4.0)]
        [InlineData(4.5)]
        public async Task Test_MinRatingFilter_Success(decimal minRating)
        {
            _output.WriteLine($"⭐ اختبار فلتر التقييم الأدنى: {minRating}");

            // الإعداد
            var properties = new List<Property>();
            for (int i = 1; i <= 5; i++)
            {
                var prop = await CreateTestPropertyAsync($"عقار {i} نجوم", "صنعاء");
                prop.AverageRating = i;
                _dbContext.Properties.Update(prop);
                properties.Add(prop);
            }
            await _dbContext.SaveChangesAsync();

            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                MinRating = minRating,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.All(result.Properties, p =>
                Assert.True(p.AverageRating >= minRating,
                    $"العقار {p.Name} تقييمه {p.AverageRating} أقل من {minRating}"));

            _output.WriteLine($"✅ فلتر التقييم أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار فلتر تقييم مرتفع جداً
        /// </summary>
        [Fact]
        public async Task Test_VeryHighRating_ReturnsOnlyBest()
        {
            _output.WriteLine("⭐ اختبار فلتر تقييم مرتفع جداً...");

            // الإعداد
            for (int i = 1; i <= 5; i++)
            {
                var prop = await CreateTestPropertyAsync($"عقار {i} نجوم", "صنعاء");
                prop.AverageRating = i;
                _dbContext.Properties.Update(prop);
            }
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                MinRating = 4.8m,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.True(result.TotalCount <= 1, "يجب أن يكون هناك عقار واحد فقط بتقييم 5");

            _output.WriteLine($"✅ فلتر التقييم المرتفع أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار فلتر تقييم صفر
        /// </summary>
        [Fact]
        public async Task Test_ZeroRating_IncludesUnratedProperties()
        {
            _output.WriteLine("⭐ اختبار فلتر تقييم صفر...");

            // الإعداد - استخدام مدينة فريدة لعزل الاختبار
            var uniqueCity = $"TestCity_{Guid.NewGuid():N}";
            
            var unratedProp = await CreateTestPropertyAsync("عقار بدون تقييم", uniqueCity);
            unratedProp.AverageRating = 0;

            var ratedProp = await CreateTestPropertyAsync("عقار بتقييم", uniqueCity);
            ratedProp.AverageRating = 4;

            _dbContext.Properties.UpdateRange(unratedProp, ratedProp);
            await _dbContext.SaveChangesAsync();
            
            // فهرسة العقارين فقط
            await _indexingService.OnPropertyUpdatedAsync(unratedProp.Id);
            await _indexingService.OnPropertyUpdatedAsync(ratedProp.Id);

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                City = uniqueCity, // فلتر بالمدينة الفريدة
                MinRating = 0,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(2, result.TotalCount);

            _output.WriteLine("✅ فلتر التقييم صفر يعرض جميع العقارات");
        }

        /// <summary>
        /// اختبار فلتر تقييم خارج النطاق
        /// </summary>
        [Theory]
        [InlineData(6)]
        [InlineData(10)]
        [InlineData(100)]
        public async Task Test_OutOfRangeRating_ReturnsEmpty(decimal rating)
        {
            _output.WriteLine($"⭐ اختبار فلتر تقييم خارج النطاق: {rating}");

            // الإعداد
            var prop = await CreateTestPropertyAsync("عقار", "صنعاء");
            prop.AverageRating = 5; // أقصى تقييم
            _dbContext.Properties.Update(prop);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                MinRating = rating,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(0, result.TotalCount);

            _output.WriteLine("✅ فلتر التقييم خارج النطاق أرجع 0 نتيجة");
        }

        #endregion

        #region اختبارات فلتر السعة

        /// <summary>
        /// اختبار فلتر عدد الضيوف
        /// </summary>
        [Theory]
        [InlineData(2)]
        [InlineData(4)]
        [InlineData(6)]
        [InlineData(8)]
        public async Task Test_GuestsCountFilter_Success(int guestsCount)
        {
            _output.WriteLine($"👥 اختبار فلتر عدد الضيوف: {guestsCount}");

            // الإعداد
            for (int capacity = 2; capacity <= 10; capacity += 2)
            {
                var prop = await CreateTestPropertyAsync($"عقار سعة {capacity}", "صنعاء");
                var unit = _dbContext.Units.First(u => u.PropertyId == prop.Id);
                unit.MaxCapacity = capacity;
                _dbContext.Units.Update(unit);
            }
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                GuestsCount = guestsCount,
                PageNumber = 1,
                PageSize = 20
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.All(result.Properties, p =>
                Assert.True(p.MaxCapacity >= guestsCount,
                    $"العقار {p.Name} سعته {p.MaxCapacity} أقل من {guestsCount}"));

            _output.WriteLine($"✅ فلتر عدد الضيوف أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار فلتر عدد ضيوف كبير جداً
        /// </summary>
        [Fact]
        public async Task Test_VeryLargeGuestsCount_ReturnsEmpty()
        {
            _output.WriteLine("👥 اختبار فلتر عدد ضيوف كبير جداً...");

            // الإعداد
            await CreateTestPropertyAsync("عقار صغير", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                GuestsCount = 100, // عدد كبير جداً
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(0, result.TotalCount);

            _output.WriteLine("✅ فلتر العدد الكبير أرجع 0 نتيجة");
        }

        /// <summary>
        /// اختبار فلتر سعة صفر أو سالبة
        /// </summary>
        [Theory]
        [InlineData(0)]
        [InlineData(-1)]
        public async Task Test_InvalidGuestsCount_HandledGracefully(int guestsCount)
        {
            _output.WriteLine($"👥 اختبار فلتر عدد ضيوف غير صحيح: {guestsCount}");

            // الإعداد
            await CreateTestPropertyAsync("عقار", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث - يجب ألا يفشل
            var exception = await Record.ExceptionAsync(async () =>
            {
                var searchRequest = new PropertySearchRequest
                {
                    GuestsCount = guestsCount,
                    PageNumber = 1,
                    PageSize = 10
                };

                await _indexingService.SearchAsync(searchRequest);
            });

            Assert.Null(exception);
            _output.WriteLine("✅ تم التعامل مع العدد غير الصحيح بنجاح");
        }

        #endregion

        #region اختبارات الفلاتر المركبة

        /// <summary>
        /// اختبار دمج فلتر السعر والتقييم
        /// </summary>
        [Fact]
        public async Task Test_PriceAndRatingCombined()
        {
            _output.WriteLine("🔄 اختبار دمج فلتر السعر والتقييم...");

            // الإعداد
            var prop1 = await CreateTestPropertyAsync("عقار رخيص وضعيف", "صنعاء", minPrice: 100);
            prop1.AverageRating = 2;

            var prop2 = await CreateTestPropertyAsync("عقار رخيص وجيد", "صنعاء", minPrice: 100);
            prop2.AverageRating = 4;

            var prop3 = await CreateTestPropertyAsync("عقار غالي وضعيف", "صنعاء", minPrice: 500);
            prop3.AverageRating = 2;

            var prop4 = await CreateTestPropertyAsync("عقار غالي وممتاز", "صنعاء", minPrice: 500);
            prop4.AverageRating = 5;

            _dbContext.Properties.UpdateRange(prop1, prop2, prop3, prop4);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث - رخيص وجيد
            var searchRequest = new PropertySearchRequest
            {
                MaxPrice = 200,
                MinRating = 3.5m,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(1, result.TotalCount);
            Assert.Equal("عقار رخيص وجيد", result.Properties.First().Name);

            _output.WriteLine("✅ دمج فلتر السعر والتقييم أرجع النتيجة الصحيحة");
        }

        /// <summary>
        /// اختبار دمج فلتر السعر والسعة
        /// </summary>
        [Fact]
        public async Task Test_PriceAndCapacityCombined()
        {
            _output.WriteLine("🔄 اختبار دمج فلتر السعر والسعة...");

            // الإعداد
            var prop1 = await CreateTestPropertyAsync("عقار صغير رخيص", "صنعاء", minPrice: 100);
            var unit1 = _dbContext.Units.First(u => u.PropertyId == prop1.Id);
            unit1.MaxCapacity = 2;

            var prop2 = await CreateTestPropertyAsync("عقار كبير رخيص", "صنعاء", minPrice: 150);
            var unit2 = _dbContext.Units.First(u => u.PropertyId == prop2.Id);
            unit2.MaxCapacity = 8;

            var prop3 = await CreateTestPropertyAsync("عقار كبير غالي", "صنعاء", minPrice: 500);
            var unit3 = _dbContext.Units.First(u => u.PropertyId == prop3.Id);
            unit3.MaxCapacity = 8;

            _dbContext.Units.UpdateRange(unit1, unit2, unit3);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث - سعة كبيرة وسعر منخفض
            var searchRequest = new PropertySearchRequest
            {
                GuestsCount = 6,
                MaxPrice = 200,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(1, result.TotalCount);
            Assert.Equal("عقار كبير رخيص", result.Properties.First().Name);

            _output.WriteLine("✅ دمج فلتر السعر والسعة أرجع النتيجة الصحيحة");
        }

        /// <summary>
        /// اختبار دمج السعر والتقييم والسعة
        /// </summary>
        [Fact]
        public async Task Test_AllThreeFiltersCombined()
        {
            _output.WriteLine("🔥 اختبار دمج السعر والتقييم والسعة...");

            // الإعداد
            var targetProp = await CreateTestPropertyAsync("العقار المثالي", "صنعاء", minPrice: 150);
            targetProp.AverageRating = 4.5m;
            var targetUnit = _dbContext.Units.First(u => u.PropertyId == targetProp.Id);
            targetUnit.MaxCapacity = 4;

            var otherProp = await CreateTestPropertyAsync("عقار آخر", "صنعاء", minPrice: 100);
            otherProp.AverageRating = 3;
            var otherUnit = _dbContext.Units.First(u => u.PropertyId == otherProp.Id);
            otherUnit.MaxCapacity = 2;

            _dbContext.Properties.UpdateRange(targetProp, otherProp);
            _dbContext.Units.UpdateRange(targetUnit, otherUnit);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                MinPrice = 100,
                MaxPrice = 200,
                MinRating = 4,
                GuestsCount = 4,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(1, result.TotalCount);
            Assert.Equal("العقار المثالي", result.Properties.First().Name);

            _output.WriteLine("✅ دمج الفلاتر الثلاثة أرجع النتيجة الصحيحة");
        }

        #endregion
    }
}
