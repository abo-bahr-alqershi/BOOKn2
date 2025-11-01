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
        private static readonly object _lock = new object();
        private static bool _initialized = false;

        /// <summary>
        /// تهيئة جميع البيانات الأساسية المطلوبة
        /// </summary>
        public static async Task EnsureAllBaseDataAsync(YemenBookingDbContext dbContext)
        {
            bool shouldInitialize = false;
            
            lock (_lock)
            {
                if (!_initialized)
                {
                    shouldInitialize = true;
                    _initialized = true;
                }
            }

            if (!shouldInitialize) return;

            // التأكد من وجود أنواع العقارات
            await EnsurePropertyTypesAsync(dbContext);
            
            // التأكد من وجود أنواع الوحدات
            await EnsureUnitTypesAsync(dbContext);
            
            // التأكد من وجود المستخدمين الاختباريين
            await EnsureTestUsersAsync(dbContext);
            
            // التأكد من وجود المرافق الأساسية
            await EnsureAmenitiesAsync(dbContext);
        }

        /// <summary>
        /// التأكد من وجود أنواع العقارات
        /// </summary>
        private static async Task EnsurePropertyTypesAsync(YemenBookingDbContext dbContext)
        {
            var existingTypes = await dbContext.PropertyTypes
                .Select(pt => pt.Id)
                .ToListAsync();

            var requiredTypes = new[]
            {
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000001"), 
                    Name = "منتجع",
                    Icon = "🏖️",
                    IsActive = true 
                },
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000002"), 
                    Name = "شقق مفروشة",
                    Icon = "🏢",
                    IsActive = true 
                },
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000003"), 
                    Name = "فندق",
                    Icon = "🏨",
                    IsActive = true 
                },
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000004"), 
                    Name = "فيلا",
                    Icon = "🏡",
                    IsActive = true 
                },
                new PropertyType 
                { 
                    Id = Guid.Parse("30000000-0000-0000-0000-000000000005"), 
                    Name = "شاليه",
                    Icon = "🏠",
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
            }
        }

        /// <summary>
        /// التأكد من وجود أنواع الوحدات
        /// </summary>
        private static async Task EnsureUnitTypesAsync(YemenBookingDbContext dbContext)
        {
            // التحقق أولاً من وجود PropertyType المطلوب
            var propertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000003"); // فندق
            var propertyTypeExists = await dbContext.PropertyTypes.AnyAsync(pt => pt.Id == propertyTypeId);
            if (!propertyTypeExists)
            {
                // PropertyTypes يجب أن تكون موجودة بالفعل من EnsurePropertyTypesAsync
                return; // الخروج إذا لم يكن PropertyType موجود
            }
            
            var existingTypes = await dbContext.UnitTypes
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
                    IsActive = true
                },
                new UnitType
                {
                    Id = Guid.Parse("20000000-0000-0000-0000-000000000002"),
                    Name = "غرفة مزدوجة",
                    Description = "غرفة مزدوجة واسعة",
                    PropertyTypeId = propertyTypeId,
                    MaxCapacity = 2,
                    IsActive = true
                },
                new UnitType
                {
                    Id = Guid.Parse("20000000-0000-0000-0000-000000000003"),
                    Name = "جناح",
                    Description = "جناح فاخر",
                    PropertyTypeId = propertyTypeId,
                    MaxCapacity = 4,
                    IsActive = true
                },
                new UnitType
                {
                    Id = Guid.Parse("20000000-0000-0000-0000-000000000004"),
                    Name = "شقة",
                    Description = "شقة كاملة مفروشة",
                    PropertyTypeId = propertyTypeId,
                    MaxCapacity = 6,
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
            }
        }

        /// <summary>
        /// التأكد من وجود المستخدمين الاختباريين
        /// </summary>
        private static async Task EnsureTestUsersAsync(YemenBookingDbContext dbContext)
        {
            var testUserId = Guid.Parse("10000000-0000-0000-0000-000000000001");
            
            var existingUser = await dbContext.Users
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
            }
        }

        /// <summary>
        /// التأكد من وجود المرافق الأساسية
        /// </summary>
        private static async Task EnsureAmenitiesAsync(YemenBookingDbContext dbContext)
        {
            var existingAmenities = await dbContext.Amenities
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
