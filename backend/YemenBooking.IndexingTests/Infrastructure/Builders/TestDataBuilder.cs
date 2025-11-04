using System;
using System.Collections.Generic;
using System.Linq;
using Bogus;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Entities;

namespace YemenBooking.IndexingTests.Infrastructure.Builders
{
    /// <summary>
    /// بناء البيانات الاختبارية باستخدام Object Mother Pattern
    /// كل بيانات فريدة ومعزولة - بدون static state
    /// </summary>
    public static class TestDataBuilder
    {
        /// <summary>
        /// الحصول على معرف فريد باستخدام Guid
        /// </summary>
        private static string GetUniqueId()
        {
            return Guid.NewGuid().ToString("N").Substring(0, 8);
        }
        
        #region Property Builders
        
        /// <summary>
        /// إنشاء عقار بسيط
        /// </summary>
        public static Property SimpleProperty(string testId = null)
        {
            var uniqueId = GetUniqueId();
            testId ??= Guid.NewGuid().ToString("N");
            
            var faker = new Faker<Property>("ar")
                .RuleFor(p => p.Id, f => Guid.NewGuid())
                .RuleFor(p => p.Name, f => $"TEST_PROP_{uniqueId}_{testId}")
                .RuleFor(p => p.Description, f => f.Lorem.Paragraph())
                .RuleFor(p => p.City, f => f.PickRandom("صنعاء", "عدن", "تعز", "الحديدة", "إب"))
                .RuleFor(p => p.Address, f => f.Address.FullAddress())
                .RuleFor(p => p.TypeId, f => GetRandomPropertyTypeId())
                .RuleFor(p => p.OwnerId, f => Guid.NewGuid())
                .RuleFor(p => p.IsActive, f => true)
                .RuleFor(p => p.IsApproved, f => true)
                .RuleFor(p => p.AverageRating, f => f.Random.Decimal(3, 5))
                .RuleFor(p => p.Latitude, f => f.Address.Latitude())
                .RuleFor(p => p.Longitude, f => f.Address.Longitude())
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
                    ImageUrl = $"https://test.com/image_{i}.jpg",
                    IsPrimary = i == 0,
                    DisplayOrder = i,
                    CreatedAt = DateTime.UtcNow
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
            var uniqueId = GetUniqueId();
            testId ??= Guid.NewGuid().ToString("N");
            
            var faker = new Faker<YemenBooking.Core.Entities.Unit>("ar")
                .RuleFor(u => u.Id, f => Guid.NewGuid())
                .RuleFor(u => u.Name, f => $"TEST_UNIT_{uniqueId}_{testId}")
                .RuleFor(u => u.UnitTypeId, f => GetRandomUnitTypeId())
                .RuleFor(u => u.AdultsCapacity, f => f.Random.Int(1, 4))
                .RuleFor(u => u.ChildrenCapacity, f => f.Random.Int(0, 2))
                .RuleFor(u => u.MaxCapacity, f => f.Random.Int(1, 6))
                .RuleFor(u => u.BasePrice, f => new Money(f.Random.Decimal(50, 1000), "YER"))
                .RuleFor(u => u.IsAvailable, f => true)
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
        
        #region Helper Methods
        
        private static Guid GetRandomPropertyTypeId()
        {
            var types = new[]
            {
                Guid.Parse("30000000-0000-0000-0000-000000000001"), // منتجع
                Guid.Parse("30000000-0000-0000-0000-000000000002"), // شقق مفروشة
                Guid.Parse("30000000-0000-0000-0000-000000000003"), // فندق
                Guid.Parse("30000000-0000-0000-0000-000000000004"), // فيلا
                Guid.Parse("30000000-0000-0000-0000-000000000005"), // شاليه
            };
            
            return types[Random.Shared.Next(types.Length)];
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
            
            return types[Random.Shared.Next(types.Length)];
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
            
            return amenities[Random.Shared.Next(amenities.Length)];
        }
        
        #endregion
        
        #region Batch Builders
        
        /// <summary>
        /// إنشاء مجموعة عقارات
        /// </summary>
        public static List<Property> BatchProperties(int count, string testId = null)
        {
            testId ??= Guid.NewGuid().ToString("N");
            
            return Enumerable.Range(0, count)
                .Select(i => SimpleProperty($"{testId}_{i}"))
                .ToList();
        }
        
        /// <summary>
        /// إنشاء مجموعة وحدات
        /// </summary>
        public static List<YemenBooking.Core.Entities.Unit> BatchUnits(Guid propertyId, int count, string testId = null)
        {
            testId ??= Guid.NewGuid().ToString("N");
            
            return Enumerable.Range(0, count)
                .Select(i => UnitForProperty(propertyId, $"{testId}_{i}"))
                .ToList();
        }
        
        #endregion
    }
}
