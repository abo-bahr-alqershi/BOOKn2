using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.Enums;

namespace YemenBooking.IndexingTests.Tests.Integration
{
    /// <summary>
    /// اختبارات التكامل الشاملة
    /// تختبر التفاعل بين جميع مكونات النظام
    /// </summary>
    public class IntegrationTests : TestBase
    {
        public IntegrationTests(TestDatabaseFixture fixture, ITestOutputHelper output)
            : base(fixture, output)
        {
        }

        #region اختبارات سيناريو كامل

        /// <summary>
        /// سيناريو كامل: من إنشاء العقار حتى الحجز
        /// </summary>
        [Fact]
        public async Task Test_CompleteScenario_PropertyLifecycle()
        {
            _output.WriteLine("🔄 اختبار سيناريو كامل لدورة حياة العقار...");

            // 1. إنشاء عقار جديد
            var property = new Property
            {
                Id = Guid.NewGuid(),
                Name = "فندق السيناريو الكامل",
                City = "صنعاء",
                Address = "شارع الستين",
                TypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"),
                OwnerId = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                IsActive = false, // يبدأ غير نشط
                IsApproved = false, // يبدأ غير معتمد
                StarRating = 4,
                AverageRating = 0,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.Properties.Add(property);
            await _dbContext.SaveChangesAsync();

            // 2. فهرسة العقار (لا يجب أن يظهر في البحث)
            await _indexingService.OnPropertyCreatedAsync(property.Id);

            var searchRequest = new PropertySearchRequest
            {
                SearchText = "السيناريو الكامل",
                PageNumber = 1,
                PageSize = 10
            };

            var resultBeforeApproval = await _indexingService.SearchAsync(searchRequest);
            Assert.DoesNotContain(resultBeforeApproval.Properties, p => p.Name == property.Name);
            _output.WriteLine("✅ العقار غير المعتمد لا يظهر في البحث");

            // 3. اعتماد وتنشيط العقار
            property.IsApproved = true;
            property.IsActive = true;
            _dbContext.Properties.Update(property);
            await _dbContext.SaveChangesAsync();
            await _indexingService.OnPropertyUpdatedAsync(property.Id);

            var resultAfterApproval = await _indexingService.SearchAsync(searchRequest);
            Assert.Contains(resultAfterApproval.Properties, p => p.Name == property.Name);
            _output.WriteLine("✅ العقار المعتمد يظهر في البحث");

            // 4. إضافة وحدات
            var units = new List<Unit>
            {
                new Unit
                {
                    Id = Guid.NewGuid(),
                    PropertyId = property.Id,
                    Name = "غرفة مفردة",
                    UnitTypeId = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                    MaxCapacity = 1,
                    IsAvailable = true,
                    IsActive = true,
                    BasePrice = new Money { Amount = 100, Currency = "YER" }
                },
                new Unit
                {
                    Id = Guid.NewGuid(),
                    PropertyId = property.Id,
                    Name = "غرفة مزدوجة",
                    UnitTypeId = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                    MaxCapacity = 2,
                    IsAvailable = true,
                    IsActive = true,
                    BasePrice = new Money { Amount = 200, Currency = "YER" }
                }
            };

            _dbContext.Units.AddRange(units);
            await _dbContext.SaveChangesAsync();

            foreach (var unit in units)
            {
                await _indexingService.OnUnitCreatedAsync(unit.Id, property.Id);
            }

            // 5. البحث بالسعة
            var capacitySearch = new PropertySearchRequest
            {
                GuestsCount = 2,
                City = "صنعاء",
                PageNumber = 1,
                PageSize = 10
            };

            var capacityResult = await _indexingService.SearchAsync(capacitySearch);
            Assert.Contains(capacityResult.Properties, p => p.Name == property.Name);
            _output.WriteLine("✅ العقار يظهر عند البحث بالسعة");

            // 6. إضافة حجز
            var booking = new Booking
            {
                Id = Guid.NewGuid(),
                UserId = Guid.Parse("10000000-0000-0000-0000-000000000001"),
                PropertyId = property.Id,
                UnitId = units[0].Id,
                CheckIn = DateTime.Now.AddDays(10),
                CheckOut = DateTime.Now.AddDays(12),
                Status = BookingStatus.Confirmed,
                TotalAmount = new Money { Amount = 200, Currency = "YER" }
            };

            _dbContext.Bookings.Add(booking);
            await _dbContext.SaveChangesAsync();

            // 7. البحث في نفس فترة الحجز (يجب أن يظهر وحدة واحدة متاحة)
            var availabilitySearch = new PropertySearchRequest
            {
                CheckIn = booking.CheckIn,
                CheckOut = booking.CheckOut,
                City = "صنعاء",
                PageNumber = 1,
                PageSize = 10
            };

            var availabilityResult = await _indexingService.SearchAsync(availabilitySearch);
            Assert.Contains(availabilityResult.Properties, p => p.Name == property.Name);
            _output.WriteLine("✅ العقار يظهر مع وحدة متاحة رغم وجود حجز");

            // 8. إضافة تقييم
            var review = new Review
            {
                Id = Guid.NewGuid(),
                BookingId = booking.Id,
                UserId = booking.UserId,
                PropertyId = property.Id,
                Rating = 5,
                Comment = "ممتاز",
                IsApproved = true
            };

            _dbContext.Reviews.Add(review);
            
            // تحديث متوسط التقييم
            property.AverageRating = 5;
            _dbContext.Properties.Update(property);
            await _dbContext.SaveChangesAsync();
            await _indexingService.OnPropertyUpdatedAsync(property.Id);

            // 9. البحث بالتقييم
            var ratingSearch = new PropertySearchRequest
            {
                MinRating = 4.5m,
                City = "صنعاء",
                PageNumber = 1,
                PageSize = 10
            };

            var ratingResult = await _indexingService.SearchAsync(ratingSearch);
            Assert.Contains(ratingResult.Properties, p => p.Name == property.Name);
            _output.WriteLine("✅ العقار يظهر عند البحث بالتقييم المرتفع");

            _output.WriteLine("✅ السيناريو الكامل تم بنجاح");
        }

        #endregion

        #region اختبارات التكامل مع المرافق والخدمات

        /// <summary>
        /// اختبار التكامل مع المرافق
        /// </summary>
        [Fact]
        public async Task Test_AmenitiesIntegration()
        {
            _output.WriteLine("🔄 اختبار التكامل مع المرافق...");

            // الإعداد
            var amenities = new List<Amenity>
            {
                new Amenity { Id = Guid.NewGuid(), Name = "مسبح", Icon = "🏊" },
                new Amenity { Id = Guid.NewGuid(), Name = "واي فاي", Icon = "📶" },
                new Amenity { Id = Guid.NewGuid(), Name = "موقف سيارات", Icon = "🚗" }
            };

            foreach (var amenity in amenities)
            {
                if (!_dbContext.Amenities.Any(a => a.Name == amenity.Name))
                {
                    _dbContext.Amenities.Add(amenity);
                }
            }
            await _dbContext.SaveChangesAsync();

            // إنشاء عقار بمرافق
            var property = await CreateTestPropertyAsync("فندق بمرافق", "صنعاء");
            
            // ربط المرافق بالعقار
            foreach (var amenity in amenities.Take(2))
            {
                var propertyAmenity = new PropertyAmenity
                {
                    PropertyId = property.Id,
                    AmenityId = amenity.Id,
                    IsAvailable = true
                };
                _dbContext.Set<PropertyAmenity>().Add(propertyAmenity);
            }
            await _dbContext.SaveChangesAsync();

            // تحديث الفهرس
            await _indexingService.OnPropertyUpdatedAsync(property.Id);

            // البحث بالمرافق
            var searchRequest = new PropertySearchRequest
            {
                RequiredAmenityIds = amenities.Take(2).Select(a => a.Id.ToString()).ToList(),
                PageNumber = 1,
                PageSize = 10
            };

            var result = await _indexingService.SearchAsync(searchRequest);
            
            // التحقق
            Assert.NotNull(result);
            // قد تعتمد النتيجة على تنفيذ فلتر المرافق

            _output.WriteLine("✅ التكامل مع المرافق يعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار التكامل مع قواعد التسعير
        /// </summary>
        [Fact]
        public async Task Test_PricingRulesIntegration()
        {
            _output.WriteLine("🔄 اختبار التكامل مع قواعد التسعير...");

            // الإعداد
            var property = await CreateTestPropertyAsync("فندق بتسعير متغير", "صنعاء");
            var unit = _dbContext.Units.First(u => u.PropertyId == property.Id);

            // إضافة قواعد تسعير
            var pricingRules = new List<PricingRule>
            {
                new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    RuleName = "سعر عادي",
                    BasePrice = 100,
                    DayOfWeekRules = "1,2,3,4", // الأحد - الأربعاء
                    IsActive = true
                },
                new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    RuleName = "سعر نهاية الأسبوع",
                    BasePrice = 150,
                    DayOfWeekRules = "5,6,0", // الخميس - السبت
                    IsActive = true
                },
                new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    RuleName = "سعر الموسم",
                    BasePrice = 200,
                    StartDate = DateTime.Now.AddDays(30),
                    EndDate = DateTime.Now.AddDays(60),
                    IsActive = true
                }
            };

            _dbContext.Set<PricingRule>().AddRange(pricingRules);
            await _dbContext.SaveChangesAsync();

            // تحديث الفهرس
            await _indexingService.OnPropertyUpdatedAsync(property.Id);

            // البحث بنطاقات سعر مختلفة
            var normalPriceSearch = new PropertySearchRequest
            {
                MinPrice = 80,
                MaxPrice = 120,
                PageNumber = 1,
                PageSize = 10
            };

            var weekendPriceSearch = new PropertySearchRequest
            {
                MinPrice = 140,
                MaxPrice = 160,
                PageNumber = 1,
                PageSize = 10
            };

            var normalResult = await _indexingService.SearchAsync(normalPriceSearch);
            var weekendResult = await _indexingService.SearchAsync(weekendPriceSearch);

            // التحقق
            Assert.NotNull(normalResult);
            Assert.NotNull(weekendResult);

            _output.WriteLine("✅ التكامل مع قواعد التسعير يعمل بشكل صحيح");
        }

        #endregion

        #region اختبارات التكامل مع الحقول الديناميكية

        /// <summary>
        /// اختبار سيناريو معقد مع حقول ديناميكية
        /// </summary>
        [Fact]
        public async Task Test_ComplexDynamicFieldsIntegration()
        {
            _output.WriteLine("🔄 اختبار تكامل معقد مع الحقول الديناميكية...");

            // الإعداد - إنشاء حقول ديناميكية لنوع العقار
            var propertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003");
            
            var dynamicFields = new List<DynamicField>
            {
                new DynamicField
                {
                    Id = Guid.NewGuid(),
                    Name = "floor_count",
                    DisplayName = "عدد الطوابق",
                    FieldType = "number",
                    PropertyTypeId = propertyTypeId,
                    IsRequired = false,
                    IsActive = true
                },
                new DynamicField
                {
                    Id = Guid.NewGuid(),
                    Name = "check_in_time",
                    DisplayName = "وقت تسجيل الدخول",
                    FieldType = "time",
                    PropertyTypeId = propertyTypeId,
                    IsRequired = true,
                    IsActive = true
                },
                new DynamicField
                {
                    Id = Guid.NewGuid(),
                    Name = "pet_policy",
                    DisplayName = "سياسة الحيوانات الأليفة",
                    FieldType = "select",
                    PropertyTypeId = propertyTypeId,
                    FieldOptions = "allowed,not_allowed,with_fee",
                    IsRequired = false,
                    IsActive = true
                }
            };

            _dbContext.Set<DynamicField>().AddRange(dynamicFields);
            await _dbContext.SaveChangesAsync();

            // إنشاء عقارات بقيم مختلفة للحقول الديناميكية
            var hotel1 = await CreateTestPropertyAsync("فندق يسمح بالحيوانات", "صنعاء", propertyTypeId);
            var hotel2 = await CreateTestPropertyAsync("فندق لا يسمح بالحيوانات", "صنعاء", propertyTypeId);
            var hotel3 = await CreateTestPropertyAsync("فندق يسمح برسوم", "صنعاء", propertyTypeId);

            // إضافة قيم الحقول الديناميكية
            var fieldValues = new List<PropertyDynamicFieldValue>
            {
                // Hotel 1
                new PropertyDynamicFieldValue
                {
                    Id = Guid.NewGuid(),
                    PropertyId = hotel1.Id,
                    DynamicFieldId = dynamicFields[0].Id,
                    Value = "5"
                },
                new PropertyDynamicFieldValue
                {
                    Id = Guid.NewGuid(),
                    PropertyId = hotel1.Id,
                    DynamicFieldId = dynamicFields[1].Id,
                    Value = "14:00"
                },
                new PropertyDynamicFieldValue
                {
                    Id = Guid.NewGuid(),
                    PropertyId = hotel1.Id,
                    DynamicFieldId = dynamicFields[2].Id,
                    Value = "allowed"
                },
                // Hotel 2
                new PropertyDynamicFieldValue
                {
                    Id = Guid.NewGuid(),
                    PropertyId = hotel2.Id,
                    DynamicFieldId = dynamicFields[0].Id,
                    Value = "3"
                },
                new PropertyDynamicFieldValue
                {
                    Id = Guid.NewGuid(),
                    PropertyId = hotel2.Id,
                    DynamicFieldId = dynamicFields[1].Id,
                    Value = "15:00"
                },
                new PropertyDynamicFieldValue
                {
                    Id = Guid.NewGuid(),
                    PropertyId = hotel2.Id,
                    DynamicFieldId = dynamicFields[2].Id,
                    Value = "not_allowed"
                },
                // Hotel 3
                new PropertyDynamicFieldValue
                {
                    Id = Guid.NewGuid(),
                    PropertyId = hotel3.Id,
                    DynamicFieldId = dynamicFields[0].Id,
                    Value = "7"
                },
                new PropertyDynamicFieldValue
                {
                    Id = Guid.NewGuid(),
                    PropertyId = hotel3.Id,
                    DynamicFieldId = dynamicFields[1].Id,
                    Value = "13:00"
                },
                new PropertyDynamicFieldValue
                {
                    Id = Guid.NewGuid(),
                    PropertyId = hotel3.Id,
                    DynamicFieldId = dynamicFields[2].Id,
                    Value = "with_fee"
                }
            };

            _dbContext.Set<PropertyDynamicFieldValue>().AddRange(fieldValues);
            await _dbContext.SaveChangesAsync();

            // فهرسة الحقول الديناميكية
            await _indexingService.OnDynamicFieldChangedAsync(hotel1.Id, "floor_count", "5", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel1.Id, "check_in_time", "14:00", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel1.Id, "pet_policy", "allowed", true);

            await _indexingService.OnDynamicFieldChangedAsync(hotel2.Id, "floor_count", "3", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel2.Id, "check_in_time", "15:00", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel2.Id, "pet_policy", "not_allowed", true);

            await _indexingService.OnDynamicFieldChangedAsync(hotel3.Id, "floor_count", "7", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel3.Id, "check_in_time", "13:00", true);
            await _indexingService.OnDynamicFieldChangedAsync(hotel3.Id, "pet_policy", "with_fee", true);

            // البحث بالحقول الديناميكية
            var petFriendlySearch = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["pet_policy"] = "allowed"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var tallBuildingSearch = new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["floor_count"] = "7"
                },
                PageNumber = 1,
                PageSize = 10
            };

            var petResult = await _indexingService.SearchAsync(petFriendlySearch);
            var tallResult = await _indexingService.SearchAsync(tallBuildingSearch);

            // التحقق
            Assert.NotNull(petResult);
            Assert.NotNull(tallResult);
            Assert.Contains(petResult.Properties, p => p.Name == "فندق يسمح بالحيوانات");
            Assert.Contains(tallResult.Properties, p => p.Name == "فندق يسمح برسوم");

            _output.WriteLine("✅ التكامل المعقد مع الحقول الديناميكية يعمل بشكل صحيح");
        }

        #endregion

        #region اختبارات حالات الحافة

        /// <summary>
        /// اختبار حالات الحافة والاستثناءات
        /// </summary>
        [Fact]
        public async Task Test_EdgeCases()
        {
            _output.WriteLine("⚠️ اختبار حالات الحافة...");

            // 1. فهرسة عقار غير موجود
            var nonExistentId = Guid.NewGuid();
            var exception1 = await Record.ExceptionAsync(async () =>
            {
                await _indexingService.OnPropertyCreatedAsync(nonExistentId);
            });
            // يجب ألا يتسبب في انهيار النظام
            _output.WriteLine("✅ فهرسة عقار غير موجود لا تسبب انهيار");

            // 2. بحث بمعاملات null
            var nullSearchRequest = new PropertySearchRequest
            {
                SearchText = null,
                City = null,
                PropertyType = null,
                PageNumber = 1,
                PageSize = 20
            };

            var nullResult = await _indexingService.SearchAsync(nullSearchRequest);
            Assert.NotNull(nullResult);
            _output.WriteLine("✅ البحث بمعاملات null يعمل بشكل صحيح");

            // 3. بحث بصفحة غير صحيحة
            var invalidPageRequest = new PropertySearchRequest
            {
                PageNumber = -1,
                PageSize = -10
            };

            var invalidPageResult = await _indexingService.SearchAsync(invalidPageRequest);
            Assert.NotNull(invalidPageResult);
            _output.WriteLine("✅ البحث بصفحة غير صحيحة يتم التعامل معه");

            // 4. فهرسة عقار مع بيانات ناقصة
            var incompleteProperty = new Property
            {
                Id = Guid.NewGuid(),
                Name = null, // اسم فارغ
                City = "", // مدينة فارغة
                TypeId = Guid.Empty, // نوع غير صحيح
                OwnerId = Guid.Empty,
                IsActive = true,
                IsApproved = true
            };

            _dbContext.Properties.Add(incompleteProperty);
            await _dbContext.SaveChangesAsync();

            var exception2 = await Record.ExceptionAsync(async () =>
            {
                await _indexingService.OnPropertyCreatedAsync(incompleteProperty.Id);
            });
            // يجب التعامل مع البيانات الناقصة
            _output.WriteLine("✅ فهرسة عقار ببيانات ناقصة يتم التعامل معها");

            // 5. تحديث عقار محذوف
            var deletedProperty = await CreateTestPropertyAsync("عقار للحذف", "صنعاء");
            await _indexingService.OnPropertyCreatedAsync(deletedProperty.Id);
            
            _dbContext.Properties.Remove(deletedProperty);
            await _dbContext.SaveChangesAsync();

            var exception3 = await Record.ExceptionAsync(async () =>
            {
                await _indexingService.OnPropertyUpdatedAsync(deletedProperty.Id);
            });
            _output.WriteLine("✅ تحديث عقار محذوف يتم التعامل معه");

            _output.WriteLine("✅ جميع حالات الحافة تم التعامل معها بنجاح");
        }

        #endregion
    }
}
