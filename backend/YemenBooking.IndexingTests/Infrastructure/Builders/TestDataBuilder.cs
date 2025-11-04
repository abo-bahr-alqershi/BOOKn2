using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using Bogus;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.IndexingTests.Infrastructure.Builders
{
    /// <summary>
    /// بناء البيانات الاختبارية باستخدام Object Mother Pattern
    /// كل بيانات فريدة ومعزولة تماماً - بدون أي static state
    /// يطبق مبدأ العزل الكامل - كل بيانات لها GUID فريد
    /// </summary>
    public static class TestDataBuilder
    {
        // بدون static counter - استخدام GUIDs فقط للعزل الكامل
        
        /// <summary>
        /// الحصول على معرف فريد باستخدام GUID كامل
        /// </summary>
        private static string GetUniqueId(string prefix = "")
        {
            // استخدام GUID كامل لضمان الفرادة المطلقة
            var uniqueGuid = Guid.NewGuid().ToString("N");
            return string.IsNullOrEmpty(prefix) ? uniqueGuid : $"{prefix}_{uniqueGuid}";
        }
        
        /// <summary>
        /// الحصول على Random آمن للخيط الحالي
        /// </summary>
        private static Random GetThreadSafeRandom()
        {
            // إنشاء Random جديد لكل استخدام بناءً على GUID
            return new Random(Guid.NewGuid().GetHashCode());
        }
        
        #region Property Builders
        
        /// <summary>
        /// إنشاء عقار بسيط
        /// </summary>
        public static Property SimpleProperty(string testId = null)
        {
            // استخدام GUID كامل لكل عقار
            var propertyGuid = Guid.NewGuid();
            var uniqueName = GetUniqueId("PROP");
            testId ??= Guid.NewGuid().ToString("N");
            
            var faker = new Faker<Property>("ar")
                .RuleFor(p => p.Id, f => propertyGuid)
                .RuleFor(p => p.Name, f => $"TEST_PROP_{uniqueName}_{testId}")
                .RuleFor(p => p.Description, f => f.Lorem.Paragraph())
                .RuleFor(p => p.City, f => f.PickRandom("صنعاء", "عدن", "تعز", "الحديدة", "إب"))
                .RuleFor(p => p.Address, f => f.Address.FullAddress())
                .RuleFor(p => p.TypeId, f => GetRandomPropertyTypeId())
                .RuleFor(p => p.OwnerId, f => Guid.Parse("50000000-0000-0000-0000-000000000001")) // Test User ID
                .RuleFor(p => p.IsActive, f => true)
                .RuleFor(p => p.IsApproved, f => true)
                .RuleFor(p => p.AverageRating, (f, p) => f.Random.Decimal(3, 5))
                .RuleFor(p => p.Latitude, f => f.Random.Decimal(12.0m, 17.0m))
                .RuleFor(p => p.Longitude, f => f.Random.Decimal(42.0m, 45.0m))
                .RuleFor(p => p.Currency, f => "YER")
                .RuleFor(p => p.CreatedAt, f => DateTime.UtcNow)
                .RuleFor(p => p.UpdatedAt, f => DateTime.UtcNow);
            
            return faker.Generate();
        }
        
        /// <summary>
        /// إنشاء عقار مع وحدات
        /// </summary>
        public static Property PropertyWithUnits(int unitCount = 3, string testId = null)
        {
            var property = SimpleProperty(testId);
            property.Units = Enumerable.Range(0, unitCount)
                .Select(_ => UnitForProperty(property.Id, testId))
                .ToList();
            
            return property;
        }
        
        /// <summary>
        /// إنشاء عقار مع مرافق
        /// </summary>
        public static Property PropertyWithAmenities(int amenityCount = 5, string testId = null)
        {
            var property = SimpleProperty(testId);
            
            property.Amenities = Enumerable.Range(0, amenityCount)
                .Select(i => new PropertyAmenity
                {
                    Id = Guid.NewGuid(),
                    PropertyId = property.Id,
                    PtaId = GetRandomAmenityId(),
                    IsAvailable = true,
                    CreatedAt = DateTime.UtcNow
                })
                .ToList();
            
            return property;
        }
        
        /// <summary>
        /// إنشاء عقار كامل
        /// </summary>
        public static Property CompleteProperty(string testId = null)
        {
            var property = PropertyWithUnits(3, testId);
            
            // إضافة المرافق
            property.Amenities = Enumerable.Range(0, 5)
                .Select(i => new PropertyAmenity
                {
                    Id = Guid.NewGuid(),
                    PropertyId = property.Id,
                    PtaId = GetRandomAmenityId(),
                    IsAvailable = true,
                    CreatedAt = DateTime.UtcNow
                })
                .ToList();
            
            // إضافة الصور
            property.Images = Enumerable.Range(0, 3)
                .Select(i => new PropertyImage
                {
                    Id = Guid.NewGuid(),
                    PropertyId = property.Id,
                    TempKey = null,
                    UnitId = null,
                    SectionId = null,
                    PropertyInSectionId = null,
                    UnitInSectionId = null,
                    Name = $"test_image_{i}.jpg",
                    Url = $"https://test.com/image_{i}.jpg",
                    SizeBytes = 1024 * 100,
                    Type = "image/jpeg",
                    Category = ImageCategory.Exterior,
                    Caption = $"Image {i}",
                    AltText = $"Property Image {i}",
                    Tags = "[]",
                    Sizes = "{}",
                    IsMain = i == 0,
                    IsMainImage = i == 0,
                    SortOrder = i,
                    DisplayOrder = i,
                    Status = ImageStatus.Approved,
                    MediaType = "image",
                    Views = 0,
                    Downloads = 0,
                    UploadedAt = DateTime.UtcNow,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                })
                .ToList();
            
            return property;
        }
        
        #endregion
        
        #region Unit Builders
        
        /// <summary>
        /// إنشاء وحدة بسيطة
        /// </summary>
        public static YemenBooking.Core.Entities.Unit SimpleUnit(string testId = null)
        {
            // استخدام GUID كامل لكل وحدة
            var unitGuid = Guid.NewGuid();
            var uniqueName = GetUniqueId("UNIT");
            testId ??= Guid.NewGuid().ToString("N");
            
            var faker = new Faker<YemenBooking.Core.Entities.Unit>("ar")
                .RuleFor(u => u.Id, f => unitGuid)
                .RuleFor(u => u.Name, f => $"TEST_UNIT_{uniqueName}_{testId}")
                .RuleFor(u => u.UnitTypeId, f => GetRandomUnitTypeId())
                .RuleFor(u => u.AdultsCapacity, f => f.Random.Int(1, 4))
                .RuleFor(u => u.ChildrenCapacity, f => f.Random.Int(0, 2))
                .RuleFor(u => u.MaxCapacity, f => f.Random.Int(1, 6))
                .RuleFor(u => u.BasePrice, f => new Money(f.Random.Decimal(50, 1000), "YER"))
                .RuleFor(u => u.IsAvailable, f => true)
                .RuleFor(u => u.IsActive, f => true)
                .RuleFor(u => u.CreatedAt, f => DateTime.UtcNow)
                .RuleFor(u => u.UpdatedAt, f => DateTime.UtcNow);
            
            return faker.Generate();
        }
        
        /// <summary>
        /// إنشاء وحدة لعقار محدد
        /// </summary>
        public static YemenBooking.Core.Entities.Unit UnitForProperty(Guid propertyId, string testId = null)
        {
            var unit = SimpleUnit(testId);
            unit.PropertyId = propertyId;
            return unit;
        }
        
        /// <summary>
        /// إنشاء وحدة مع إتاحة
        /// </summary>
        public static YemenBooking.Core.Entities.Unit UnitWithAvailability(Guid propertyId, DateTime from, DateTime to, string testId = null)
        {
            var unit = UnitForProperty(propertyId, testId);
            
            unit.UnitAvailabilities = new List<UnitAvailability>
            {
                new UnitAvailability
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    StartDate = from,
                    EndDate = to,
                    CreatedAt = DateTime.UtcNow
                }
            };
            
            return unit;
        }
        
        #endregion
        
        #region Search Request Builders
        
        /// <summary>
        /// إنشاء طلب بحث بسيط
        /// </summary>
        public static Core.Indexing.Models.PropertySearchRequest SimpleSearchRequest()
        {
            return new Core.Indexing.Models.PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 20
            };
        }
        
        /// <summary>
        /// إنشاء طلب بحث بنص
        /// </summary>
        public static Core.Indexing.Models.PropertySearchRequest TextSearchRequest(string searchText)
        {
            return new Core.Indexing.Models.PropertySearchRequest
            {
                SearchText = searchText,
                PageNumber = 1,
                PageSize = 20
            };
        }
        
        /// <summary>
        /// إنشاء طلب بحث بفلاتر
        /// </summary>
        public static Core.Indexing.Models.PropertySearchRequest FilteredSearchRequest(
            string city = null,
            string propertyType = null,
            decimal? minPrice = null,
            decimal? maxPrice = null,
            int? guestsCount = null)
        {
            return new Core.Indexing.Models.PropertySearchRequest
            {
                City = city,
                PropertyType = propertyType,
                MinPrice = minPrice,
                MaxPrice = maxPrice,
                GuestsCount = guestsCount,
                PageNumber = 1,
                PageSize = 20
            };
        }
        
        /// <summary>
        /// إنشاء طلب بحث معقد
        /// </summary>
        public static Core.Indexing.Models.PropertySearchRequest ComplexSearchRequest()
        {
            var faker = new Faker();
            
            return new Core.Indexing.Models.PropertySearchRequest
            {
                SearchText = faker.Lorem.Word(),
                City = faker.PickRandom("صنعاء", "عدن", "تعز", null),
                PropertyType = faker.PickRandom(GetRandomPropertyTypeId().ToString(), null),
                MinPrice = faker.Random.Decimal(50, 200),
                MaxPrice = faker.Random.Decimal(500, 1000),
                MinRating = faker.Random.Decimal(3, 4),
                GuestsCount = faker.Random.Int(1, 4),
                CheckIn = DateTime.Today.AddDays(faker.Random.Int(1, 30)),
                CheckOut = DateTime.Today.AddDays(faker.Random.Int(31, 60)),
                RequiredAmenityIds = faker.Random.Bool() ? 
                    new List<string> { GetRandomAmenityId().ToString() } : null,
                SortBy = faker.PickRandom("price_asc", "price_desc", "rating", "newest", null),
                PageNumber = 1,
                PageSize = 20
            };
        }
        
        #endregion
        
        private static Guid GetRandomPropertyTypeId()
        {
            var typeIds = new[]
            {
                Guid.Parse("30000000-0000-0000-0000-000000000001"), // منتجع
                Guid.Parse("30000000-0000-0000-0000-000000000002"), // شقق مفروشة
                Guid.Parse("30000000-0000-0000-0000-000000000003"), // فندق
                Guid.Parse("30000000-0000-0000-0000-000000000004"), // فيلا
                Guid.Parse("30000000-0000-0000-0000-000000000005")  // شاليه
            };
            return typeIds[Random.Shared.Next(typeIds.Length)];
        }
        
        private static Guid GetRandomUnitTypeId()
        {
            var types = new[]
            {
                Guid.Parse("20000000-0000-0000-0000-000000000001"), // غرفة مفردة
                Guid.Parse("20000000-0000-0000-0000-000000000002"), // غرفة مزدوجة
                Guid.Parse("20000000-0000-0000-0000-000000000003"), // جناح
                Guid.Parse("20000000-0000-0000-0000-000000000004"), // شقة
            };
            
            var random = GetThreadSafeRandom();
            return types[random.Next(types.Length)];
        }
        
        private static Guid GetRandomAmenityId()
        {
            var amenities = new[]
            {
                Guid.Parse("10000000-0000-0000-0000-000000000001"), // WiFi
                Guid.Parse("10000000-0000-0000-0000-000000000002"), // موقف سيارات
                Guid.Parse("10000000-0000-0000-0000-000000000003"), // مسبح
                Guid.Parse("10000000-0000-0000-0000-000000000004"), // مطعم
                Guid.Parse("10000000-0000-0000-0000-000000000005"), // صالة رياضية
            };
            
            var random = GetThreadSafeRandom();
            return amenities[random.Next(amenities.Length)];
        }
        
        #region Batch Builders
        
        /// <summary>
        /// إنشاء مجموعة عقارات
        /// </summary>
        public static List<Property> BatchProperties(int count, string testId = null)
        {
            testId ??= Guid.NewGuid().ToString("N");
            
            return Enumerable.Range(0, count)
                .Select(i => 
                {
                    // كل عقار له GUID فريد
                    var uniqueTestId = $"{testId}_{Guid.NewGuid():N}";
                    return SimpleProperty(uniqueTestId);
                })
                .ToList();
        }
        
        /// <summary>
        /// إنشاء مجموعة وحدات
        /// </summary>
        public static List<YemenBooking.Core.Entities.Unit> BatchUnits(Guid propertyId, int count, string testId = null)
        {
            testId ??= Guid.NewGuid().ToString("N");
            
            return Enumerable.Range(0, count)
                .Select(i =>
                {
                    // كل وحدة لها GUID فريد
                    var uniqueTestId = $"{testId}_{Guid.NewGuid():N}";
                    return UnitForProperty(propertyId, uniqueTestId);
                })
                .ToList();
        }
        
        #endregion
    }
}
