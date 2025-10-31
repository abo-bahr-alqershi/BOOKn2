using System;
using System.Collections.Generic;
using Bogus;
using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية لكائن Unit
    /// Generates comprehensive seed data for Unit entities with diverse scenarios
    /// </summary>
    public class UnitSeeder : ISeeder<Unit>
    {
        public IEnumerable<Unit> SeedData()
        {
            var baseDate = DateTime.UtcNow;
            var units = new List<Unit>();
            
            // أسماء وحدات متنوعة
            var unitNames = new[]
            {
                "غرفة مفردة", "غرفة مزدوجة", "جناح ملكي", "غرفة عائلية", "استوديو",
                "شقة بغرفة نوم واحدة", "شقة بغرفتي نوم", "شقة بثلاث غرف نوم",
                "شاليه صغير", "شاليه كبير", "فيلا مستقلة", "جناح تنفيذي",
                "غرفة ديلوكس", "غرفة بريميوم", "جناح بريزيدنتال", "بنتهاوس",
                "غرفة بإطلالة بحرية", "غرفة بإطلالة جبلية", "غرفة اقتصادية", "غرفة قياسية"
            };
            
            var random = new Random(54321);
            
            // توليد 80 وحدة متنوعة
            for (int i = 0; i < 80; i++)
            {
                var unitName = unitNames[i % unitNames.Length];
                var unitNumber = (i / unitNames.Length) + 1;
                var fullName = unitNumber > 1 ? $"{unitName} - رقم {unitNumber}" : unitName;
                
                // تحديد السعر والعملة بناءً على نوع الوحدة
                decimal basePrice;
                string currency;
                
                if (i % 5 == 0) // 20% من الوحدات بالدولار
                {
                    basePrice = random.Next(30, 350);
                    currency = "USD";
                }
                else
                {
                    basePrice = random.Next(15000, 250000);
                    currency = "YER";
                }
                
                // تحديد السعة القصوى بناءً على نوع الوحدة
                int maxCapacity;
                if (fullName.Contains("مفردة") || fullName.Contains("استوديو") || fullName.Contains("اقتصادية"))
                {
                    maxCapacity = random.Next(1, 2);
                }
                else if (fullName.Contains("مزدوجة") || fullName.Contains("قياسية"))
                {
                    maxCapacity = random.Next(2, 3);
                }
                else if (fullName.Contains("عائلية") || fullName.Contains("بغرفتي نوم"))
                {
                    maxCapacity = random.Next(4, 6);
                }
                else if (fullName.Contains("فيلا") || fullName.Contains("بنتهاوس") || fullName.Contains("بريزيدنتال"))
                {
                    maxCapacity = random.Next(6, 12);
                }
                else
                {
                    maxCapacity = random.Next(2, 4);
                }
                
                // تحديد التوفر
                bool isAvailable = random.Next(100) < 75; // 75% متاحة
                
                // تحديد طريقة التسعير
                var pricingMethod = random.Next(4) switch
                {
                    0 => PricingMethod.Hourly,
                    1 => PricingMethod.Daily,
                    2 => PricingMethod.Weekly,
                    _ => PricingMethod.Monthly
                };
                
                var unit = new Unit
                {
                    Id = Guid.NewGuid(),
                    PropertyId = Guid.NewGuid(), // سيتم تحديثه في DataSeedingService
                    UnitTypeId = Guid.NewGuid(), // سيتم تحديثه في DataSeedingService
                    Name = fullName,
                    BasePrice = new Money(basePrice, currency),
                    MaxCapacity = maxCapacity,
                    CustomFeatures = "[]",
                    IsAvailable = isAvailable,
                    ViewCount = random.Next(50, 1200),
                    BookingCount = random.Next(10, 250),
                    PricingMethod = pricingMethod,
                    CreatedAt = baseDate.AddDays(-random.Next(5, 120)),
                    UpdatedAt = baseDate.AddDays(-random.Next(0, 10)),
                    IsActive = true,
                    IsDeleted = false
                };
                
                units.Add(unit);
            }
            
            return units;
        }
    }
} 