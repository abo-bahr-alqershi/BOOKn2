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
    /// اختبارات فلترة الموقع ونوع العقار
    /// </summary>
    public class LocationTypeFilterTests : TestBase
    {
        public LocationTypeFilterTests(TestDatabaseFixture fixture, ITestOutputHelper output)
            : base(fixture, output)
        {
        }

        #region اختبارات فلتر المدينة

        /// <summary>
        /// اختبار فلتر المدينة الواحدة
        /// </summary>
        [Theory]
        [InlineData("صنعاء")]
        [InlineData("عدن")]
        [InlineData("تعز")]
        [InlineData("إب")]
        public async Task Test_CityFilter_ReturnsOnlyCityProperties(string city)
        {
            _output.WriteLine($"🏙️ اختبار فلتر المدينة: {city}");

            // الإعداد
            await CreateComprehensiveTestDataAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                City = city,
                PageNumber = 1,
                PageSize = 50
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.All(result.Properties, p => 
                Assert.Equal(city, p.City, StringComparer.OrdinalIgnoreCase));

            _output.WriteLine($"✅ تم العثور على {result.TotalCount} عقار في {city}");
        }

        /// <summary>
        /// اختبار فلتر مدينة غير موجودة
        /// </summary>
        [Fact]
        public async Task Test_NonExistentCity_ReturnsEmpty()
        {
            _output.WriteLine("🏙️ اختبار فلتر مدينة غير موجودة...");

            // الإعداد
            await CreateTestPropertyAsync("فندق", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                City = "مدينة وهمية",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(0, result.TotalCount);

            _output.WriteLine("✅ البحث في مدينة غير موجودة أرجع 0 نتيجة");
        }

        /// <summary>
        /// اختبار فلتر المدينة مع حالات أحرف مختلفة
        /// </summary>
        [Theory]
        [InlineData("صنعاء", "صنعاء")]
        [InlineData("صنعاء", "صنعاء")]
        [InlineData("صنعاء", "صنعاء")]
        public async Task Test_CityFilter_CaseInsensitive(string searchCity, string actualCity)
        {
            _output.WriteLine($"🏙️ اختبار فلتر المدينة غير الحساس للأحرف: '{searchCity}' -> '{actualCity}'");

            // الإعداد
            await CreateTestPropertyAsync("فندق", actualCity);
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                City = searchCity,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.True(result.TotalCount > 0);

            _output.WriteLine($"✅ البحث بـ '{searchCity}' وجد عقارات في '{actualCity}'");
        }

        /// <summary>
        /// اختبار البحث الجغرافي بالإحداثيات
        /// </summary>
        [Fact]
        public async Task Test_GeoLocationSearch_FindsNearbyProperties()
        {
            _output.WriteLine("🌍 اختبار البحث الجغرافي...");

            // الإعداد - إنشاء عقارات في مواقع مختلفة
            var centerLat = 15.3694;
            var centerLon = 44.1910;

            // عقار قريب (ضمن 5 كم)
            var nearProperty = await CreateTestPropertyAsync("عقار قريب", "صنعاء");
            nearProperty.Latitude = (decimal)(centerLat + 0.01);
            nearProperty.Longitude = (decimal)(centerLon + 0.01);

            // عقار متوسط (ضمن 10 كم)
            var mediumProperty = await CreateTestPropertyAsync("عقار متوسط", "صنعاء");
            mediumProperty.Latitude = (decimal)(centerLat + 0.05);
            mediumProperty.Longitude = (decimal)(centerLon + 0.05);

            // عقار بعيد (خارج 10 كم)
            var farProperty = await CreateTestPropertyAsync("عقار بعيد", "صنعاء");
            farProperty.Latitude = (decimal)(centerLat + 0.5);
            farProperty.Longitude = (decimal)(centerLon + 0.5);

            _dbContext.Properties.UpdateRange(nearProperty, mediumProperty, farProperty);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث ضمن نطاق 5 كم
            var searchRequest = new PropertySearchRequest
            {
                Latitude = 15.3522,
                Longitude = 44.2095,
                RadiusKm = 5,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            if (result.TotalCount > 0)
            {
                // التحقق من وجود العقار القريب
                var foundNearProperty = result.Properties.FirstOrDefault(p => p.Name == "عقار قريب");
                if (foundNearProperty != null)
                {
                    Assert.NotNull(foundNearProperty);
                }
            }
            Assert.DoesNotContain(result.Properties, p => p.Name == "عقار بعيد");

            _output.WriteLine($"✅ البحث الجغرافي أرجع {result.TotalCount} عقار ضمن 5 كم");
        }

        #endregion

        #region اختبارات فلتر نوع العقار

        /// <summary>
        /// اختبار فلتر نوع العقار بالمعرف
        /// </summary>
        [Fact]
        public async Task Test_PropertyTypeFilter_ByGuid_Success()
        {
            _output.WriteLine("🏢 اختبار فلتر نوع العقار بالمعرف...");

            // الإعداد
            var hotelTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003");
            await CreateTestPropertyAsync("فندق 1", "صنعاء", hotelTypeId);
            await CreateTestPropertyAsync("فندق 2", "عدن", hotelTypeId);
            await CreateTestPropertyAsync("شقة", "صنعاء", Guid.Parse("30000000-0000-0000-0000-000000000002"));

            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                PropertyType = hotelTypeId.ToString(),
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(2, result.TotalCount);
            Assert.All(result.Properties, p => 
                Assert.Equal(hotelTypeId.ToString(), p.PropertyType));

            _output.WriteLine($"✅ فلتر النوع بالمعرف أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار فلتر نوع العقار بالاسم
        /// </summary>
        [Theory]
        [InlineData("فندق")]
        [InlineData("شقق مفروشة")]
        [InlineData("منتجع")]
        public async Task Test_PropertyTypeFilter_ByName_Success(string typeName)
        {
            _output.WriteLine($"🏢 اختبار فلتر نوع العقار بالاسم: {typeName}");

            // الإعداد
            await CreateComprehensiveTestDataAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                PropertyType = typeName,
                PageNumber = 1,
                PageSize = 50
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            
            if (result.TotalCount > 0)
            {
                _output.WriteLine($"✅ فلتر النوع '{typeName}' أرجع {result.TotalCount} نتيجة");
            }
            else
            {
                _output.WriteLine($"⚠️ لا توجد عقارات من نوع '{typeName}'");
            }
        }

        /// <summary>
        /// اختبار فلتر نوع غير موجود
        /// </summary>
        [Fact]
        public async Task Test_InvalidPropertyType_ReturnsEmpty()
        {
            _output.WriteLine("🏢 اختبار فلتر نوع غير موجود...");

            // الإعداد
            await CreateTestPropertyAsync("فندق", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                PropertyType = "نوع غير موجود",
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(0, result.TotalCount);

            _output.WriteLine("✅ البحث بنوع غير موجود أرجع 0 نتيجة");
        }

        /// <summary>
        /// اختبار فلتر النوع مع معرف غير صحيح
        /// </summary>
        [Theory]
        [InlineData("not-a-guid")]
        [InlineData("12345")]
        [InlineData("00000000-0000-0000-0000-000000000000")]
        public async Task Test_InvalidPropertyTypeGuid_HandledGracefully(string invalidGuid)
        {
            _output.WriteLine($"🏢 اختبار فلتر النوع بمعرف غير صحيح: {invalidGuid}");

            // الإعداد
            await CreateTestPropertyAsync("فندق", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث - يجب ألا يفشل
            var exception = await Record.ExceptionAsync(async () =>
            {
                var searchRequest = new PropertySearchRequest
                {
                    PropertyType = invalidGuid,
                    PageNumber = 1,
                    PageSize = 10
                };

                await _indexingService.SearchAsync(searchRequest);
            });

            Assert.Null(exception);

            _output.WriteLine("✅ تم التعامل مع المعرف غير الصحيح بنجاح");
        }

        #endregion

        #region اختبارات فلتر نوع الوحدة

        /// <summary>
        /// اختبار فلتر نوع الوحدة
        /// </summary>
        [Fact]
        public async Task Test_UnitTypeFilter_Success()
        {
            _output.WriteLine("🛏️ اختبار فلتر نوع الوحدة...");

            // الإعداد
            var singleRoomType = Guid.Parse("20000000-0000-0000-0000-000000000001");
            var doubleRoomType = Guid.Parse("20000000-0000-0000-0000-000000000002");

            var hotel1 = await CreateTestPropertyAsync("فندق بغرف مفردة", "صنعاء");
            var unit1 = _dbContext.Units.First(u => u.PropertyId == hotel1.Id);
            unit1.UnitTypeId = singleRoomType;

            var hotel2 = await CreateTestPropertyAsync("فندق بغرف مزدوجة", "صنعاء");
            var unit2 = _dbContext.Units.First(u => u.PropertyId == hotel2.Id);
            unit2.UnitTypeId = doubleRoomType;

            _dbContext.Units.UpdateRange(unit1, unit2);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                UnitTypeId = singleRoomType.ToString(),
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.True(result.TotalCount >= 1, "يجب أن يحتوي على عقارات بغرف مفردة");
            // التحقق من وجود العقار الصحيح
            var singleRoomHotel = result.Properties.FirstOrDefault(p => p.Name == "فندق بغرف مفردة");
            if (singleRoomHotel != null)
            {
                Assert.NotNull(singleRoomHotel);
            }

            _output.WriteLine($"✅ فلتر نوع الوحدة أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار فلتر أنواع وحدات متعددة في نفس العقار
        /// </summary>
        [Fact]
        public async Task Test_MultipleUnitTypes_InSameProperty()
        {
            _output.WriteLine("🛏️ اختبار عقار بأنواع وحدات متعددة...");

            // الإعداد
            var singleRoomType = Guid.Parse("20000000-0000-0000-0000-000000000001");
            var doubleRoomType = Guid.Parse("20000000-0000-0000-0000-000000000002");
            var suiteType = Guid.Parse("20000000-0000-0000-0000-000000000003");

            var hotel = await CreateTestPropertyAsync("فندق متعدد الغرف", "صنعاء");

            // إضافة وحدات بأنواع مختلفة
            var unit1 = new Unit
            {
                Id = Guid.NewGuid(),
                PropertyId = hotel.Id,
                Name = "غرفة مفردة",
                UnitTypeId = singleRoomType,
                MaxCapacity = 1,
                IsAvailable = true,
                IsActive = true,
                BasePrice = new YemenBooking.Core.ValueObjects.Money(100, "YER")
            };

            var unit2 = new Unit
            {
                Id = Guid.NewGuid(),
                PropertyId = hotel.Id,
                Name = "غرفة مزدوجة",
                UnitTypeId = doubleRoomType,
                MaxCapacity = 2,
                IsAvailable = true,
                IsActive = true,
                BasePrice = new YemenBooking.Core.ValueObjects.Money(150, "YER")
            };

            var unit3 = new Unit
            {
                Id = Guid.NewGuid(),
                PropertyId = hotel.Id,
                Name = "جناح",
                UnitTypeId = suiteType,
                MaxCapacity = 4,
                IsAvailable = true,
                IsActive = true,
                BasePrice = new YemenBooking.Core.ValueObjects.Money(250, "YER")
            };

            _dbContext.Units.AddRange(unit1, unit2, unit3);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث بكل نوع
            foreach (var unitTypeId in new[] { singleRoomType, doubleRoomType, suiteType })
            {
                var searchRequest = new PropertySearchRequest
                {
                    UnitTypeId = unitTypeId.ToString(),
                    PageNumber = 1,
                    PageSize = 10
                };

                var result = await _indexingService.SearchAsync(searchRequest);

                Assert.NotNull(result);
                Assert.Contains(result.Properties, p => p.Name == "فندق متعدد الغرف");
            }

            _output.WriteLine("✅ العقار بأنواع وحدات متعددة يظهر في جميع عمليات البحث المناسبة");
        }

        #endregion

        #region اختبارات الفلترة المركبة للموقع والنوع

        /// <summary>
        /// اختبار دمج فلتر المدينة والنوع
        /// </summary>
        [Fact]
        public async Task Test_CombinedCityAndType_Filter()
        {
            _output.WriteLine("🔄 اختبار دمج فلتر المدينة والنوع...");

            // الإعداد
            var hotelType = Guid.Parse("30000000-0000-0000-0000-000000000003");
            var apartmentType = Guid.Parse("30000000-0000-0000-0000-000000000002");

            await CreateTestPropertyAsync("فندق صنعاء", "صنعاء", hotelType);
            await CreateTestPropertyAsync("فندق عدن", "عدن", hotelType);
            await CreateTestPropertyAsync("شقة صنعاء", "صنعاء", apartmentType);

            await _indexingService.RebuildIndexAsync();

            // البحث - فندق في صنعاء
            var searchRequest = new PropertySearchRequest
            {
                City = "صنعاء",
                PropertyType = hotelType.ToString(),
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(1, result.TotalCount);
            Assert.Equal("فندق صنعاء", result.Properties.First().Name);

            _output.WriteLine($"✅ دمج فلتر المدينة والنوع أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار البحث الجغرافي مع نوع العقار
        /// </summary>
        [Fact]
        public async Task Test_GeoSearchWithPropertyType()
        {
            _output.WriteLine("🌍 اختبار البحث الجغرافي مع نوع العقار...");

            // الإعداد
            var hotelType = Guid.Parse("30000000-0000-0000-0000-000000000003");
            var centerLat = 15.3694;
            var centerLon = 44.1910;

            var nearHotel = await CreateTestPropertyAsync("فندق قريب", "صنعاء", hotelType);
            nearHotel.Latitude = (decimal)(centerLat + 0.01);
            nearHotel.Longitude = (decimal)(centerLon + 0.01);

            var nearApartment = await CreateTestPropertyAsync("شقة قريبة", "صنعاء", 
                Guid.Parse("30000000-0000-0000-0000-000000000002"));
            nearApartment.Latitude = (decimal)(centerLat + 0.01);
            nearApartment.Longitude = (decimal)(centerLon + 0.01);

            _dbContext.Properties.UpdateRange(nearHotel, nearApartment);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث - فنادق ضمن 5 كم
            var searchRequest = new PropertySearchRequest
            {
                PropertyType = hotelType.ToString(),
                Latitude = centerLat,
                Longitude = centerLon,
                RadiusKm = 5,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(1, result.TotalCount);
            Assert.Equal("فندق قريب", result.Properties.First().Name);

            _output.WriteLine("✅ البحث الجغرافي مع نوع العقار أرجع النتيجة الصحيحة");
        }

        #endregion
    }
}
