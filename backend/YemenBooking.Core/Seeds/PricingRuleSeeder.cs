using System;
using System.Collections.Generic;
using System.Linq;
using Bogus;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية لقواعد التسعير
    /// Pricing rules data seeder
    /// </summary>
    public class PricingRuleSeeder : ISeeder<PricingRule>
    {
        public IEnumerable<PricingRule> SeedData()
        {
            var pricingRules = new List<PricingRule>();
            var random = new Random(42); // Fixed seed for consistent data
            var today = DateTime.UtcNow.Date;
            
            // Generate pricing rules for 10 units
            for (int i = 0; i < 10; i++)
            {
                var unitId = Guid.NewGuid();
                var basePrice = random.Next(100, 500) * 1000; // Base price between 100,000 - 500,000 YER
                
                // Base pricing rule (always needed)
                pricingRules.Add(new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unitId,
                    PriceType = PriceType.Base,
                    StartDate = today,
                    EndDate = today.AddYears(1),
                    PriceAmount = basePrice,
                    PricingTier = PricingTier.Standard,
                    Currency = "YER",
                    Description = "السعر الأساسي للوحدة",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });
                
                // Weekend pricing (Friday & Saturday)
                pricingRules.Add(new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unitId,
                    PriceType = PriceType.Weekend,
                    StartDate = today,
                    EndDate = today.AddYears(1),
                    PriceAmount = basePrice * 1.2m, // 20% increase for weekends
                    PricingTier = PricingTier.Standard,
                    PercentageChange = 20,
                    Currency = "YER",
                    Description = "سعر نهاية الأسبوع (الجمعة والسبت)",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });
                
                // Seasonal pricing (Summer)
                pricingRules.Add(new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unitId,
                    PriceType = PriceType.Seasonal,
                    StartDate = new DateTime(today.Year, 6, 1), // June
                    EndDate = new DateTime(today.Year, 8, 31), // August
                    PriceAmount = basePrice * 1.3m, // 30% increase for summer
                    PricingTier = PricingTier.Premium,
                    PercentageChange = 30,
                    Currency = "YER",
                    Description = "سعر موسم الصيف",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });
                
                // Holiday pricing (Eid, Ramadan, etc.)
                pricingRules.Add(new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unitId,
                    PriceType = PriceType.Holiday,
                    StartDate = today.AddDays(60), // Approximate holiday period
                    EndDate = today.AddDays(70),
                    PriceAmount = basePrice * 1.5m, // 50% increase for holidays
                    PricingTier = PricingTier.Luxury,
                    PercentageChange = 50,
                    Currency = "YER",
                    Description = "سعر العطلات والأعياد",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });
                
                // Early bird discount
                if (random.Next(100) < 50) // 50% chance
                {
                    pricingRules.Add(new PricingRule
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unitId,
                        PriceType = PriceType.EarlyBird,
                        StartDate = today.AddDays(30),
                        EndDate = today.AddDays(180),
                        PriceAmount = basePrice * 0.85m, // 15% discount for early booking
                        PricingTier = PricingTier.Economy,
                        PercentageChange = -15,
                        MinPrice = basePrice * 0.7m,
                        Currency = "YER",
                        Description = "خصم الحجز المبكر (15% خصم)",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });
                }
                
                // Last minute discount
                if (random.Next(100) < 30) // 30% chance
                {
                    pricingRules.Add(new PricingRule
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unitId,
                        PriceType = PriceType.LastMinute,
                        StartDate = today,
                        EndDate = today.AddDays(14),
                        PriceAmount = basePrice * 0.8m, // 20% discount for last minute
                        PricingTier = PricingTier.Economy,
                        PercentageChange = -20,
                        MinPrice = basePrice * 0.6m,
                        Currency = "YER",
                        Description = "خصم اللحظة الأخيرة (20% خصم)",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });
                }
            }
            
            return pricingRules;
        }
        
        /// <summary>
        /// إنشاء قواعد تسعير لوحدة محددة
        /// Generate pricing rules for specific unit
        /// </summary>
        public IEnumerable<PricingRule> SeedDataForUnit(Guid unitId, decimal basePrice, string currency = "YER")
        {
            var pricingRules = new List<PricingRule>();
            var today = DateTime.UtcNow.Date;
            
            // Base pricing rule
            pricingRules.Add(new PricingRule
            {
                Id = Guid.NewGuid(),
                UnitId = unitId,
                PriceType = PriceType.Base,
                StartDate = today,
                EndDate = today.AddYears(2),
                PriceAmount = basePrice,
                PricingTier = PricingTier.Standard,
                Currency = currency,
                Description = "السعر الأساسي",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true,
                IsDeleted = false
            });
            
            // Weekend pricing
            pricingRules.Add(new PricingRule
            {
                Id = Guid.NewGuid(),
                UnitId = unitId,
                PriceType = PriceType.Weekend,
                StartDate = today,
                EndDate = today.AddYears(2),
                StartTime = new TimeSpan(0, 0, 0), // Start of Friday
                EndTime = new TimeSpan(23, 59, 59), // End of Saturday
                PriceAmount = basePrice * 1.25m,
                PricingTier = PricingTier.Standard,
                PercentageChange = 25,
                Currency = currency,
                Description = "أسعار نهاية الأسبوع",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true,
                IsDeleted = false
            });
            
            // Peak season (Summer)
            pricingRules.Add(new PricingRule
            {
                Id = Guid.NewGuid(),
                UnitId = unitId,
                PriceType = PriceType.Peak,
                StartDate = new DateTime(today.Year, 6, 1),
                EndDate = new DateTime(today.Year, 9, 30),
                PriceAmount = basePrice * 1.4m,
                PricingTier = PricingTier.Premium,
                PercentageChange = 40,
                MaxPrice = basePrice * 2m,
                Currency = currency,
                Description = "موسم الذروة (الصيف)",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true,
                IsDeleted = false
            });
            
            // Off-peak season (Winter)
            pricingRules.Add(new PricingRule
            {
                Id = Guid.NewGuid(),
                UnitId = unitId,
                PriceType = PriceType.OffPeak,
                StartDate = new DateTime(today.Year, 12, 1),
                EndDate = new DateTime(today.Year + 1, 2, 28),
                PriceAmount = basePrice * 0.75m,
                PricingTier = PricingTier.Economy,
                PercentageChange = -25,
                MinPrice = basePrice * 0.5m,
                Currency = currency,
                Description = "موسم الركود (الشتاء)",
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                IsActive = true,
                IsDeleted = false
            });
            
            return pricingRules;
        }
    }
}
