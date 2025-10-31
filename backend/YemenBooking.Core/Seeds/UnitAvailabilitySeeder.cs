using System;
using System.Collections.Generic;
using System.Linq;
using Bogus;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Seeds
{
    /// <summary>
    /// مولد البيانات الأولية للإتاحة
    /// Unit availability data seeder
    /// </summary>
    public class UnitAvailabilitySeeder : ISeeder<UnitAvailability>
    {
        public IEnumerable<UnitAvailability> SeedData()
        {
            var availabilities = new List<UnitAvailability>();
            var random = new Random(42); // Fixed seed for consistent data
            var today = DateTime.UtcNow.Date;
            
            // Generate availability data for the next 6 months
            for (int i = 0; i < 10; i++) // Generate for 10 units
            {
                var unitId = Guid.NewGuid();
                
                // Add some blocked periods for maintenance
                availabilities.Add(new UnitAvailability
                {
                    Id = Guid.NewGuid(),
                    UnitId = unitId,
                    StartDate = today.AddDays(random.Next(30, 60)),
                    EndDate = today.AddDays(random.Next(61, 65)),
                    Status = AvailabilityStatus.Maintenance,
                    Reason = "صيانة دورية",
                    Notes = "صيانة شهرية للوحدة",
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });
                
                // Add some owner use periods
                if (random.Next(100) < 30) // 30% chance
                {
                    availabilities.Add(new UnitAvailability
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unitId,
                        StartDate = today.AddDays(random.Next(70, 100)),
                        EndDate = today.AddDays(random.Next(101, 110)),
                        Status = AvailabilityStatus.OwnerUse,
                        Reason = "استخدام المالك",
                        Notes = "المالك سيستخدم الوحدة في هذه الفترة",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });
                }
                
                // Add some blocked periods for special events
                if (random.Next(100) < 20) // 20% chance
                {
                    availabilities.Add(new UnitAvailability
                    {
                        Id = Guid.NewGuid(),
                        UnitId = unitId,
                        StartDate = today.AddDays(random.Next(120, 150)),
                        EndDate = today.AddDays(random.Next(151, 160)),
                        Status = AvailabilityStatus.Blocked,
                        Reason = "حدث خاص",
                        Notes = "محجوز لحدث خاص",
                        CreatedAt = DateTime.UtcNow,
                        UpdatedAt = DateTime.UtcNow,
                        IsActive = true,
                        IsDeleted = false
                    });
                }
            }
            
            return availabilities;
        }
        
        /// <summary>
        /// إنشاء بيانات إتاحة لوحدة محددة
        /// Generate availability data for specific unit
        /// </summary>
        public IEnumerable<UnitAvailability> SeedDataForUnit(Guid unitId, DateTime startDate, DateTime endDate)
        {
            var availabilities = new List<UnitAvailability>();
            var random = new Random();
            var currentDate = startDate;
            
            while (currentDate < endDate)
            {
                // Randomly decide the status for this period
                var statusChoice = random.Next(100);
                string status;
                string reason;
                int durationDays;
                
                if (statusChoice < 60) // 60% available
                {
                    status = AvailabilityStatus.Available;
                    reason = "متاح للحجز";
                    durationDays = random.Next(7, 21); // Available for 1-3 weeks
                }
                else if (statusChoice < 80) // 20% booked
                {
                    status = AvailabilityStatus.Booked;
                    reason = "محجوز من عميل";
                    durationDays = random.Next(3, 10); // Booked for 3-10 days
                }
                else if (statusChoice < 90) // 10% maintenance
                {
                    status = AvailabilityStatus.Maintenance;
                    reason = "صيانة";
                    durationDays = random.Next(2, 5); // Maintenance for 2-5 days
                }
                else // 10% owner use
                {
                    status = AvailabilityStatus.OwnerUse;
                    reason = "استخدام المالك";
                    durationDays = random.Next(5, 14); // Owner use for 5-14 days
                }
                
                var periodEnd = currentDate.AddDays(durationDays);
                if (periodEnd > endDate) periodEnd = endDate;
                
                availabilities.Add(new UnitAvailability
                {
                    Id = Guid.NewGuid(),
                    UnitId = unitId,
                    StartDate = currentDate,
                    EndDate = periodEnd,
                    Status = status,
                    Reason = reason,
                    Notes = $"فترة {status} من {currentDate:yyyy-MM-dd} إلى {periodEnd:yyyy-MM-dd}",
                    BookingId = status == AvailabilityStatus.Booked ? Guid.NewGuid() : null,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    IsActive = true,
                    IsDeleted = false
                });
                
                currentDate = periodEnd.AddDays(1);
            }
            
            return availabilities;
        }
    }
}
