using System;
using System.Collections.Generic;
using Bogus;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية لكائن User
    /// </summary>
    public class UserSeeder : ISeeder<User>
    {
        public IEnumerable<User> SeedData()
        {
            // Fixed: Use static date instead of DateTime.UtcNow for PostgreSQL compatibility
            var seedDate = new DateTime(2024, 1, 1, 0, 0, 0, DateTimeKind.Utc);
            
            return new List<User>
            {
                new User
                {
                    Id = Guid.Parse("AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"),
                    Name = "Admin User",
                    Email = "admin@example.com",
                    Password = "Admin@123",
                    Phone = "1234567890",
                    ProfileImage = "",
                    CreatedAt = seedDate,
                    IsActive = true,
                    LastLoginDate = seedDate,
                    TotalSpent = 0m,
                    LoyaltyTier = "Gold",
                    EmailConfirmed = true,
                    EmailConfirmationToken = null,
                    EmailConfirmationTokenExpires = null,
                    PasswordResetToken = null,
                    PasswordResetTokenExpires = null,
                    SettingsJson = "{}",
                    FavoritesJson = "[]",
                    TimeZoneId = "Asia/Aden",
                    Country = "Yemen",
                    City = "Sana'a"
                    
                },
                new User
                {
                    Id = Guid.Parse("BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"),
                    Name = "Property Owner User",
                    Email = "owner@example.com",
                    Password = "Owner@123",
                    Phone = "0987654321",
                    ProfileImage = "",
                    CreatedAt = seedDate,
                    IsActive = true,
                    LastLoginDate = seedDate,
                    TotalSpent = 0m,
                    LoyaltyTier = "Silver",
                    EmailConfirmed = true,
                    EmailConfirmationToken = null,
                    EmailConfirmationTokenExpires = null,
                    PasswordResetToken = null,
                    PasswordResetTokenExpires = null,
                    SettingsJson = "{}",
                    FavoritesJson = "[]",
                    TimeZoneId = "Asia/Aden",
                    Country = "Yemen",
                    City = "Aden"
                }
            };
        }
    }
} 