using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.IndexingTests.Tests.Availability
{
    /// <summary>
    /// اختبارات الإتاحة والتواريخ الشاملة
    /// تغطي جميع سيناريوهات البحث بالتواريخ والتحقق من الإتاحة
    /// </summary>
    public class AvailabilityDateTests : TestBase
    {
        public AvailabilityDateTests(TestDatabaseFixture fixture, ITestOutputHelper output)
            : base(fixture, output)
        {
        }

        #region اختبارات التواريخ الأساسية

        /// <summary>
        /// اختبار البحث بتواريخ صحيحة
        /// </summary>
        [Fact]
        public async Task Test_ValidDateRange_ReturnsAvailableProperties()
        {
            _output.WriteLine("📅 اختبار البحث بتواريخ صحيحة...");

            // الإعداد
            await CreateTestPropertyAsync("فندق متاح", "صنعاء");
            await CreateTestPropertyAsync("شقة متاحة", "عدن");
            await _indexingService.RebuildIndexAsync();

            // البحث
            var checkIn = DateTime.UtcNow.AddDays(7);
            var checkOut = DateTime.UtcNow.AddDays(10);

            var searchRequest = new PropertySearchRequest
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.True(result.TotalCount > 0);

            _output.WriteLine($"✅ البحث بالتواريخ أرجع {result.TotalCount} عقار متاح");
        }

        /// <summary>
        /// اختبار البحث بتواريخ معكوسة
        /// </summary>
        [Fact]
        public async Task Test_ReversedDates_HandledGracefully()
        {
            _output.WriteLine("📅 اختبار البحث بتواريخ معكوسة...");

            // الإعداد
            await CreateTestPropertyAsync("فندق", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث - تاريخ الخروج قبل الدخول
            var checkIn = DateTime.UtcNow.AddDays(10);
            var checkOut = DateTime.UtcNow.AddDays(7);

            var searchRequest = new PropertySearchRequest
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                PageNumber = 1,
                PageSize = 10
            };

            // يجب ألا يفشل
            var exception = await Record.ExceptionAsync(async () =>
            {
                await _indexingService.SearchAsync(searchRequest);
            });

            Assert.Null(exception);
            _output.WriteLine("✅ تم التعامل مع التواريخ المعكوسة بنجاح");
        }

        /// <summary>
        /// اختبار البحث بتاريخ واحد فقط
        /// </summary>
        [Theory]
        [InlineData(true, false)]  // CheckIn فقط
        [InlineData(false, true)]   // CheckOut فقط
        public async Task Test_SingleDate_HandledProperly(bool hasCheckIn, bool hasCheckOut)
        {
            _output.WriteLine($"📅 اختبار البحث بتاريخ واحد: CheckIn={hasCheckIn}, CheckOut={hasCheckOut}");

            // الإعداد
            await CreateTestPropertyAsync("فندق", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                CheckIn = hasCheckIn ? DateTime.UtcNow.AddDays(7) : null,
                CheckOut = hasCheckOut ? DateTime.UtcNow.AddDays(10) : null,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            
            _output.WriteLine($"✅ البحث بتاريخ واحد أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار البحث بتواريخ في الماضي
        /// </summary>
        [Fact]
        public async Task Test_PastDates_ReturnsEmpty()
        {
            _output.WriteLine("📅 اختبار البحث بتواريخ في الماضي...");

            // الإعداد
            await CreateTestPropertyAsync("فندق", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث بتواريخ ماضية
            var checkIn = DateTime.UtcNow.AddDays(-10);
            var checkOut = DateTime.UtcNow.AddDays(-7);

            var searchRequest = new PropertySearchRequest
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.Equal(0, result.TotalCount);

            _output.WriteLine("✅ البحث بتواريخ ماضية أرجع 0 نتيجة");
        }

        /// <summary>
        /// اختبار البحث بمدة إقامة طويلة
        /// </summary>
        [Theory]
        [InlineData(30)]   // شهر
        [InlineData(90)]   // 3 أشهر
        [InlineData(365)]  // سنة
        public async Task Test_LongStayDuration(int days)
        {
            _output.WriteLine($"📅 اختبار البحث بمدة إقامة {days} يوم...");

            // الإعداد
            await CreateTestPropertyAsync("فندق للإقامة الطويلة", "صنعاء");
            await _indexingService.RebuildIndexAsync();

            // البحث
            var checkIn = DateTime.UtcNow.AddDays(7);
            var checkOut = checkIn.AddDays(days);

            var searchRequest = new PropertySearchRequest
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            
            _output.WriteLine($"✅ البحث لمدة {days} يوم أرجع {result.TotalCount} نتيجة");
        }

        #endregion

        #region اختبارات الإتاحة مع الحجوزات

        /// <summary>
        /// اختبار عقار محجوز بالكامل
        /// </summary>
        [Fact]
        public async Task Test_FullyBookedProperty_NotReturned()
        {
            _output.WriteLine("📅 اختبار عقار محجوز بالكامل...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق محجوز", "صنعاء");
            var unit = _dbContext.Units.First(u => u.PropertyId == property.Id);

            // إضافة حجز يغطي الفترة المطلوبة
            var checkIn = DateTime.UtcNow.AddDays(7);
            var checkOut = DateTime.UtcNow.AddDays(10);

            var booking = new Booking
            {
                Id = Guid.NewGuid(),
                UserId = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                UnitId = unit.Id,
                CheckIn = checkIn.AddDays(-1),
                CheckOut = checkOut.AddDays(1),
                Status = YemenBooking.Core.Enums.BookingStatus.Confirmed,
                TotalPrice = new Money(500, "YER"),
                BookedAt = DateTime.UtcNow,
                GuestsCount = 2
            };

            _dbContext.Bookings.Add(booking);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.DoesNotContain(result.Properties, p => p.Name == "فندق محجوز");

            _output.WriteLine("✅ العقار المحجوز لا يظهر في النتائج");
        }

        /// <summary>
        /// اختبار عقار متاح جزئياً
        /// </summary>
        [Fact]
        public async Task Test_PartiallyAvailableProperty()
        {
            _output.WriteLine("📅 اختبار عقار متاح جزئياً...");

            // الإعداد - عقار بوحدتين
            var property = await CreateTestPropertyAsync("فندق بوحدتين", "صنعاء");
            
            // إضافة وحدة ثانية
            var unit2 = new Unit
            {
                Id = Guid.NewGuid(),
                PropertyId = property.Id,
                Name = "وحدة 2",
                UnitTypeId = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                MaxCapacity = 2,
                IsAvailable = true,
                IsActive = true,
                BasePrice = new Money(100, "YER")
            };
            _dbContext.Units.Add(unit2);

            // حجز الوحدة الأولى فقط
            var unit1 = _dbContext.Units.First(u => u.PropertyId == property.Id);
            var checkIn = DateTime.UtcNow.AddDays(7);
            var checkOut = DateTime.UtcNow.AddDays(10);

            var booking = new Booking
            {
                Id = Guid.NewGuid(),
                UserId = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                UnitId = unit1.Id,
                CheckIn = checkIn,
                CheckOut = checkOut,
                Status = YemenBooking.Core.Enums.BookingStatus.Confirmed,
                TotalPrice = new Money(300, "YER"),
                BookedAt = DateTime.UtcNow,
                GuestsCount = 2
            };

            _dbContext.Bookings.Add(booking);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق - العقار يجب أن يظهر لأن له وحدة متاحة
            Assert.NotNull(result);
            Assert.Contains(result.Properties, p => p.Name == "فندق بوحدتين");

            _output.WriteLine("✅ العقار المتاح جزئياً يظهر في النتائج");
        }

        /// <summary>
        /// اختبار التحقق من الإتاحة مع حجوزات متعددة
        /// </summary>
        [Fact]
        public async Task Test_AvailabilityWithMultipleBookings()
        {
            _output.WriteLine("📅 اختبار الإتاحة مع حجوزات متعددة...");
            
            // الإعداد
            var property = await CreateTestPropertyAsync("فندق مع حجوزات", "صنعاء");
            var unit = _dbContext.Units.First(u => u.PropertyId == property.Id);

            // إضافة حجوزات متعددة
            var bookings = new List<Booking>
            {
                // حجز من 1-5
                new Booking
                {
                    Id = Guid.NewGuid(),
                    UserId = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                    UnitId = unit.Id,
                    CheckIn = DateTime.UtcNow.AddDays(1),
                    CheckOut = DateTime.UtcNow.AddDays(5),
                    Status = YemenBooking.Core.Enums.BookingStatus.Confirmed,
                    TotalPrice = new Money(400, "YER"),
                    BookedAt = DateTime.UtcNow
                },
                // حجز من 10-15
                new Booking
                {
                    Id = Guid.NewGuid(),
                    UserId = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                    UnitId = unit.Id,
                    CheckIn = DateTime.UtcNow.AddDays(10),
                    CheckOut = DateTime.UtcNow.AddDays(15),
                    Status = YemenBooking.Core.Enums.BookingStatus.Confirmed,
                    TotalPrice = new Money(500, "YER"),
                    BookedAt = DateTime.UtcNow
                }
            };

            _dbContext.Bookings.AddRange(bookings);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث في فترة متاحة (6-9)
            var availableRequest = new PropertySearchRequest
            {
                CheckIn = DateTime.UtcNow.AddDays(6),
                CheckOut = DateTime.UtcNow.AddDays(9),
                PageNumber = 1,
                PageSize = 10
            };

            var availableResult = await _indexingService.SearchAsync(availableRequest);

            // البحث في فترة محجوزة (2-4)
            var bookedRequest = new PropertySearchRequest
            {
                CheckIn = DateTime.UtcNow.AddDays(2),
                CheckOut = DateTime.UtcNow.AddDays(4),
                PageNumber = 1,
                PageSize = 10
            };

            var bookedResult = await _indexingService.SearchAsync(bookedRequest);

            // التحقق
            Assert.NotNull(availableResult);
            Assert.NotNull(bookedResult);

            Assert.Contains(availableResult.Properties, p => p.Name == "فندق مع حجوزات");
            Assert.DoesNotContain(bookedResult.Properties, p => p.Name == "فندق مع حجوزات");

            _output.WriteLine("✅ التحقق من الإتاحة مع حجوزات متعددة يعمل بشكل صحيح");
        }

        #endregion

        #region اختبارات الإتاحة مع قيود الوحدات

        /// <summary>
        /// اختبار وحدة غير متاحة
        /// </summary>
        [Fact]
        public async Task Test_UnavailableUnit_NotIncluded()
        {
            _output.WriteLine("📅 اختبار وحدة غير متاحة...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق بوحدة غير متاحة", "صنعاء");
            var unit = _dbContext.Units.First(u => u.PropertyId == property.Id);
            
            // جعل الوحدة غير متاحة
            unit.IsAvailable = false;
            _dbContext.Units.Update(unit);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                CheckIn = DateTime.UtcNow.AddDays(7),
                CheckOut = DateTime.UtcNow.AddDays(10),
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.DoesNotContain(result.Properties, p => p.Name == "فندق بوحدة غير متاحة");

            _output.WriteLine("✅ العقار بوحدات غير متاحة لا يظهر في النتائج");
        }

        /// <summary>
        /// اختبار وحدة غير نشطة
        /// </summary>
        [Fact]
        public async Task Test_InactiveUnit_NotIncluded()
        {
            _output.WriteLine("📅 اختبار وحدة غير نشطة...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق بوحدة غير نشطة", "صنعاء");
            var unit = _dbContext.Units.First(u => u.PropertyId == property.Id);
            
            // جعل الوحدة غير نشطة
            unit.IsActive = false;
            _dbContext.Units.Update(unit);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                CheckIn = DateTime.UtcNow.AddDays(7),
                CheckOut = DateTime.UtcNow.AddDays(10),
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.DoesNotContain(result.Properties, p => p.Name == "فندق بوحدة غير نشطة");

            _output.WriteLine("✅ العقار بوحدات غير نشطة لا يظهر في النتائج");
        }

        #endregion

        #region اختبارات الإتاحة المخصصة

        /// <summary>
        /// اختبار فترات إتاحة مخصصة
        /// </summary>
        [Fact]
        public async Task Test_CustomAvailabilityPeriods()
        {
            _output.WriteLine("📅 اختبار فترات إتاحة مخصصة...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق بإتاحة مخصصة", "صنعاء");
            var unit = _dbContext.Units.First(u => u.PropertyId == property.Id);

            // إضافة فترات إتاحة مخصصة
            var availabilities = new List<UnitAvailability>
            {
                // متاح من 1-10
                new UnitAvailability
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    StartDate = DateTime.UtcNow.AddDays(1),
                    EndDate = DateTime.UtcNow.AddDays(10),
                    Status = "available",
                    CreatedAt = DateTime.UtcNow
                },
                // غير متاح من 11-20
                new UnitAvailability
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    StartDate = DateTime.UtcNow.AddDays(11),
                    EndDate = DateTime.UtcNow.AddDays(20),
                    Status = "blocked",
                    CreatedAt = DateTime.UtcNow
                }
            };

            _dbContext.Set<UnitAvailability>().AddRange(availabilities);
            await _dbContext.SaveChangesAsync();
            await _indexingService.RebuildIndexAsync();

            // البحث في فترة متاحة
            var availableRequest = new PropertySearchRequest
            {
                CheckIn = DateTime.UtcNow.AddDays(5),
                CheckOut = DateTime.UtcNow.AddDays(8),
                PageNumber = 1,
                PageSize = 10
            };

            var availableResult = await _indexingService.SearchAsync(availableRequest);

            // البحث في فترة محجوبة
            var blockedRequest = new PropertySearchRequest
            {
                CheckIn = DateTime.UtcNow.AddDays(12),
                CheckOut = DateTime.UtcNow.AddDays(15),
                PageNumber = 1,
                PageSize = 10
            };

            var blockedResult = await _indexingService.SearchAsync(blockedRequest);

            // التحقق
            Assert.NotNull(availableResult);
            Assert.NotNull(blockedResult);

            Assert.Contains(availableResult.Properties, p => p.Name == "فندق بإتاحة مخصصة");
            Assert.DoesNotContain(blockedResult.Properties, p => p.Name == "فندق بإتاحة مخصصة");

            _output.WriteLine("✅ فترات الإتاحة المخصصة تعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار الإتاحة في أيام محددة من الأسبوع
        /// </summary>
        [Fact]
        public async Task Test_WeekdayAvailability()
        {
            _output.WriteLine("📅 اختبار الإتاحة في أيام محددة من الأسبوع...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق نهاية الأسبوع", "صنعاء");
            
            // البحث - إيجاد أول جمعة وسبت قادمين
            var today = DateTime.UtcNow;
            var friday = today.AddDays((5 - (int)today.DayOfWeek + 7) % 7);
            if (friday <= today) friday = friday.AddDays(7);
            var sunday = friday.AddDays(2);

            var searchRequest = new PropertySearchRequest
            {
                CheckIn = friday,
                CheckOut = sunday,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            
            _output.WriteLine($"✅ البحث لنهاية الأسبوع ({friday:yyyy-MM-dd} - {sunday:yyyy-MM-dd}) أرجع {result.TotalCount} نتيجة");
        }

        #endregion

        #region اختبارات الفلترة المركبة مع التواريخ

        /// <summary>
        /// اختبار التواريخ مع فلتر المدينة
        /// </summary>
        [Fact]
        public async Task Test_DatesWithCityFilter()
        {
            _output.WriteLine("🔄 اختبار التواريخ مع فلتر المدينة...");

            // الإعداد
            await CreateTestPropertyAsync("فندق صنعاء", "صنعاء");
            await CreateTestPropertyAsync("فندق عدن", "عدن");
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                City = "صنعاء",
                CheckIn = DateTime.Now.AddDays(7),
                CheckOut = DateTime.Now.AddDays(10),
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.All(result.Properties, p => Assert.Equal("صنعاء", p.City));

            _output.WriteLine($"✅ فلتر التواريخ والمدينة أرجع {result.TotalCount} نتيجة");
        }

        /// <summary>
        /// اختبار التواريخ مع فلتر السعر
        /// </summary>
        [Fact]
        public async Task Test_DatesWithPriceFilter()
        {
            _output.WriteLine("🔄 اختبار التواريخ مع فلتر السعر...");

            // الإعداد
            await CreateTestPropertyAsync("فندق رخيص", "صنعاء", minPrice: 100);
            await CreateTestPropertyAsync("فندق غالي", "صنعاء", minPrice: 500);
            await _indexingService.RebuildIndexAsync();

            // البحث
            var searchRequest = new PropertySearchRequest
            {
                CheckIn = DateTime.Now.AddDays(7),
                CheckOut = DateTime.Now.AddDays(10),
                MaxPrice = 200,
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);

            // التحقق
            Assert.NotNull(result);
            Assert.All(result.Properties, p => Assert.True(p.MinPrice <= 200));

            _output.WriteLine($"✅ فلتر التواريخ والسعر أرجع {result.TotalCount} نتيجة");
        }

        #endregion
    }
}
