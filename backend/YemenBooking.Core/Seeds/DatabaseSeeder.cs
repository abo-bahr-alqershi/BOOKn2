using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using System;
using YemenBooking.Core.Seeds;
using System.Linq;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// فئة لتجميع وتشغيل جميع مولدات البيانات الأولية
    /// </summary>
    public static class DatabaseSeeder
    {
        public static void Seed(ModelBuilder modelBuilder)
        {
            var userSeeder = new UserSeeder();
            modelBuilder.Entity<User>().HasData(userSeeder.SeedData());

            // Static seeding for bookings removed to avoid owned type seed issues

            // Seed default currencies
            // Fixed: Use static date instead of DateTime.UtcNow for PostgreSQL compatibility
            var seedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            modelBuilder.Entity<Currency>().HasData(
                new Currency { Code = "YER", ArabicCode = "ريال", Name = "Yemeni Rial", ArabicName = "الريال اليمني", IsDefault = true, ExchangeRate = null, LastUpdated = null },
                new Currency { Code = "USD", ArabicCode = "دولار", Name = "US Dollar", ArabicName = "الدولار الأمريكي", IsDefault = false, ExchangeRate = 0.004m, LastUpdated = seedDate }
            );

            // Seed some cities
            modelBuilder.Entity<City>().HasData(
                new City { Name = "صنعاء", Country = "اليمن", ImagesJson = "[]" },
                new City { Name = "عدن", Country = "اليمن", ImagesJson = "[]" },
                new City { Name = "تعز", Country = "اليمن", ImagesJson = "[]" }
            );
            
            // Seed user roles
            // Fixed: Use static date instead of DateTime.UtcNow for PostgreSQL compatibility
            modelBuilder.Entity<UserRole>().HasData(
                new
                {
                    Id = Guid.Parse("CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC"),
                    UserId = Guid.Parse("AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"),
                    RoleId = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                },
                new
                {
                    Id = Guid.Parse("DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD"),
                    UserId = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"),
                    RoleId = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    AssignedAt = seedDate,
                    CreatedAt = seedDate,
                    UpdatedAt = seedDate,
                    IsActive = true,
                    IsDeleted = false
                }
            );
            
            // Seed property types with Arabic names
            var propertyTypeSeeder = new PropertyTypeSeeder();
            modelBuilder.Entity<PropertyType>().HasData(propertyTypeSeeder.SeedData());
            
            // Seed properties with Arabic names
            var propertySeeder = new PropertySeeder();
            modelBuilder.Entity<Property>().HasData(propertySeeder.SeedData());
            
            // Seed property policies in Arabic
            var policySeeder = new PropertyPolicySeeder();
            modelBuilder.Entity<PropertyPolicy>().HasData(policySeeder.SeedData());
        }
    }
} 