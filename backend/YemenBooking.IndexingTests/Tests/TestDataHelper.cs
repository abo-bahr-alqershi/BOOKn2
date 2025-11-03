using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.IndexingTests.Tests
{
    /// <summary>
    /// مساعد لإنشاء وإدارة البيانات الاختبارية
    /// يضمن وجود جميع البيانات المرجعية المطلوبة
    /// </summary>
    public static class TestDataHelper
    {
        private static readonly SemaphoreSlim _initLock = new SemaphoreSlim(1, 1);
        private static bool _isInitialized = false;
        private static readonly Dictionary<string, bool> _dbInitialized = new Dictionary<string, bool>();

        /// <summary>
        /// تهيئة جميع البيانات الأساسية المطلوبة
        /// </summary>
        public static async Task EnsureAllBaseDataAsync(YemenBookingDbContext dbContext)
        {
            // التحقق من التهيئة باستخدام معرف فريد للسياق
            var contextId = dbContext.ContextId.InstanceId.ToString();
            
            await _initLock.WaitAsync();
            try
            {
                // التحقق إذا كان هذا السياق قد تمت تهيئته
                if (_dbInitialized.ContainsKey(contextId) && _dbInitialized[contextId])
                    return;

                await InitializeAllAsync(dbContext);
                _dbInitialized[contextId] = true;
            }
            finally
            {
                _initLock.Release();
            }
        }

        private static async Task InitializeAllAsync(YemenBookingDbContext dbContext)
        {
            // هذه الدوال Idempotent وتتحقق قبل الإضافة
            // ✅ يتم تنفيذها بالترتيب لتجنب مشاكل Foreign Key
            await EnsureCitiesAsync(dbContext);
            await EnsureTestUsersAsync(dbContext);
            await EnsurePropertyTypesAsync(dbContext);
            await EnsureUnitTypesAsync(dbContext);
            await EnsureAmenitiesAsync(dbContext);
        }

        /// <summary>
        /// التأكد من وجود المدن الأساسية المستخدمة في الاختبارات
        /// </summary>
        private static async Task EnsureCitiesAsync(YemenBookingDbContext dbContext)
        {
            var existing = await dbContext.Cities
                .AsNoTracking()  // ✅ عدم تتبع الاستعلام
                .Select(c => c.Name)
                .ToListAsync();
            var needed = new[] { "صنعاء", "عدن", "تعز", "الحديدة", "إب", "ذمار", "المكلا" };
            var toAdd = needed.Where(n => !existing.Contains(n))
                .Select(n => new YemenBooking.Core.Entities.City { Name = n, Country = "اليمن" })
                .ToList();
            if (toAdd.Any())
            {
                dbContext.Cities.AddRange(toAdd);
                await dbContext.SaveChangesAsync();
                dbContext.ChangeTracker.Clear();  // ✅ تنظيف بعد الحفظ
            }
        }

        /// <summary>
        /// التأكد من وجود أنواع العقارات
        /// </summary>
        private static async Task EnsurePropertyTypesAsync(YemenBookingDbContext dbContext)
        {
            var existingTypes = await dbContext.PropertyTypes
                .AsNoTracking()  // ✅ عدم تتبع الاستعلام
                .Select(pt => pt.Id)
                .ToListAsync();

            var requiredTypes = new[]
            {
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000001"), 
                    Name = "منتجع",
                    Icon = "🏖️",
                    Description = "منتجع سياحي",
                    DefaultAmenities = "[]",
                    IsActive = true 
                },
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000002"), 
                    Name = "شقق مفروشة",
                    Icon = "🏢",
                    Description = "شقق مفروشة",
                    DefaultAmenities = "[]",
                    IsActive = true 
                },
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000003"), 
                    Name = "فندق",
                    Icon = "🏨",
                    Description = "فندق",
                    DefaultAmenities = "[]",
                    IsActive = true 
                },
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000004"), 
                    Name = "فيلا",
                    Icon = "🏡",
                    Description = "فيلا خاصة",
                    DefaultAmenities = "[]",
                    IsActive = true 
                },
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000005"), 
                    Name = "شاليه",
                    Icon = "🏠",
                    Description = "شاليه",
                    DefaultAmenities = "[]",
                    IsActive = true 
                }
            };

            var typesToAdd = requiredTypes
                .Where(rt => !existingTypes.Contains(rt.Id))
                .ToList();

            if (typesToAdd.Any())
            {
                dbContext.PropertyTypes.AddRange(typesToAdd);
                await dbContext.SaveChangesAsync();
                dbContext.ChangeTracker.Clear();  // ✅ تنظيف بعد الحفظ
            }
        }

        /// <summary>
        /// التأكد من وجود أنواع الوحدات
        /// </summary>
        private static async Task EnsureUnitTypesAsync(YemenBookingDbContext dbContext)
        {
            // التحقق أولاً من وجود PropertyType المطلوب
            var propertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"); // فندق
            var propertyTypeExists = await dbContext.PropertyTypes
                .AsNoTracking()  // ✅ عدم تتبع الاستعلام
                .AnyAsync(pt => pt.Id == propertyTypeId);
            if (!propertyTypeExists)
            {
                // PropertyTypes يجب أن تكون موجودة بالفعل من EnsurePropertyTypesAsync
                return; // الخروج إذا لم يكن PropertyType موجود
            }
            
            var existingTypes = await dbContext.UnitTypes
                .AsNoTracking()  // ✅ عدم تتبع الاستعلام
                .Select(ut => ut.Id)
                .ToListAsync();
            
            var requiredTypes = new[]
            {
                new UnitType
                {
                    Id = Guid.Parse("20000000-0000-0000-0000-000000000001"),
                    Name = "غرفة مفردة",
                    Description = "غرفة مفردة مريحة",
                    PropertyTypeId = propertyTypeId,
                    MaxCapacity = 1,
                    DefaultPricingRules = "[]",
                    IsActive = true
                },
                new UnitType
                {
                    Id = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                    Name = "غرفة مزدوجة",
                    Description = "غرفة مزدوجة واسعة",
                    PropertyTypeId = propertyTypeId,
                    MaxCapacity = 2,
                    DefaultPricingRules = "[]",
                    IsActive = true
                },
                new UnitType
                {
                    Id = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                    Name = "جناح",
                    Description = "جناح فاخر",
                    PropertyTypeId = propertyTypeId,
                    MaxCapacity = 4,
                    DefaultPricingRules = "[]",
                    IsActive = true
                },
                new UnitType
                {
                    Id = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                    Name = "شقة",
                    Description = "شقة كاملة مفروشة",
                    PropertyTypeId = propertyTypeId,
                    MaxCapacity = 6,
                    DefaultPricingRules = "[]",
                    IsActive = true
                }
            };

            var typesToAdd = requiredTypes
                .Where(rt => !existingTypes.Contains(rt.Id))
                .ToList();

            if (typesToAdd.Any())
            {
                dbContext.UnitTypes.AddRange(typesToAdd);
                await dbContext.SaveChangesAsync();
                dbContext.ChangeTracker.Clear();  // ✅ تنظيف بعد الحفظ
            }
        }

        /// <summary>
        /// التأكد من وجود المستخدمين الاختباريين
        /// </summary>
        private static async Task EnsureTestUsersAsync(YemenBookingDbContext dbContext)
        {
            var testUserId = Guid.Parse("10000000-0000-0000-0000-000000000001");
            
            var existingUser = await dbContext.Users
                .AsNoTracking()  // ✅ عدم تتبع الاستعلام
                .AnyAsync(u => u.Id == testUserId);

            if (!existingUser)
            {
                var testUser = new User
                {
                    Id = testUserId,
                    Email = "test@example.com",
                    Password = "hashed_password",
                    Name = "مستخدم اختباري",
                    Phone = "770123456",
                    IsActive = true,
                    EmailConfirmed = true,
                    CreatedAt = DateTime.UtcNow
                };
                
                dbContext.Users.Add(testUser);
                await dbContext.SaveChangesAsync();
                dbContext.ChangeTracker.Clear();  // ✅ تنظيف بعد الحفظ
            }
        }

        /// <summary>
        /// التأكد من وجود المرافق الأساسية
        /// </summary>
        private static async Task EnsureAmenitiesAsync(YemenBookingDbContext dbContext)
        {
            var existingAmenities = await dbContext.Amenities
                .AsNoTracking()  // ✅ عدم تتبع الاستعلام
                .Select(a => a.Name)
                .ToListAsync();

            var requiredAmenities = new[]
            {
                new Amenity 
                { 
                    Id = Guid.NewGuid(), 
                    Name = "واي فاي", 
                    Icon = "📶",
                    Description = "خدمة واي فاي مجانية",
                    IsActive = true 
                },
                new Amenity 
                { 
                    Id = Guid.NewGuid(), 
                    Name = "مسبح", 
                    Icon = "🏊",
                    Description = "مسبح خارجي كبير",
                    IsActive = true 
                },
                new Amenity 
                { 
                    Id = Guid.NewGuid(), 
                    Name = "موقف سيارات", 
                    Icon = "🚗",
                    Description = "موقف سيارات مجاني",
                    IsActive = true 
                },
                new Amenity 
                { 
                    Id = Guid.NewGuid(), 
                    Name = "مطعم", 
                    Icon = "🍽️",
                    Description = "مطعم متنوع",
                    IsActive = true 
                },
                new Amenity 
                { 
                    Id = Guid.NewGuid(), 
                    Name = "صالة رياضية", 
                    Icon = "💪",
                    Description = "صالة رياضية مجهزة",
                    IsActive = true 
                }
            };

            var amenitiesToAdd = requiredAmenities
                .Where(ra => !existingAmenities.Contains(ra.Name))
                .ToList();

            if (amenitiesToAdd.Any())
            {
                dbContext.Amenities.AddRange(amenitiesToAdd);
                await dbContext.SaveChangesAsync();
                dbContext.ChangeTracker.Clear();  // ✅ تنظيف بعد الحفظ
            }
        }

        /// <summary>
        /// إنشاء عقار اختباري كامل البيانات
        /// </summary>
        public static Property CreateValidProperty(
            string name = null,
            string city = null,
            Guid? typeId = null,
            Guid? ownerId = null)
        {
            var random = new Random();
            
            return new Property
            {
                Id = Guid.NewGuid(),
                Name = name ?? $"عقار اختباري {random.Next(1000, 9999)}",
                City = city ?? "صنعاء",
                Currency = "YER",
                TypeId = typeId ?? Guid.Parse("30000000-0000-0000-0000-000000000003"),
                OwnerId = ownerId ?? Guid.Parse("10000000-0000-0000-0000-000000000001"),
                Address = $"شارع {random.Next(1, 100)}",
                Description = "وصف اختباري",
                Latitude = (decimal)(15.3694 + (random.NextDouble() * 0.1)),
                Longitude = (decimal)(44.1910 + (random.NextDouble() * 0.1)),
                StarRating = random.Next(1, 6),
                AverageRating = (decimal)(random.NextDouble() * 5),
                IsActive = true,
                IsApproved = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
        }

        /// <summary>
        /// إنشاء وحدة اختبارية كاملة البيانات
        /// </summary>
        public static Unit CreateValidUnit(Guid propertyId, string name = null)
        {
            var random = new Random();
            
            return new Unit
            {
                Id = Guid.NewGuid(),
                PropertyId = propertyId,
                Name = name ?? $"وحدة {random.Next(1, 100)}",
                UnitTypeId = Guid.Parse("20000000-0000-0000-0000-000000000002"), // غرفة مزدوجة
                MaxCapacity = random.Next(2, 10),
                AdultsCapacity = random.Next(2, 8),
                ChildrenCapacity = random.Next(0, 4),
                IsAvailable = true,
                IsActive = true,
                CustomFeatures = "{}",
                BasePrice = new YemenBooking.Core.ValueObjects.Money(random.Next(50, 500) * 10, "YER"),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
        }
    }
}
