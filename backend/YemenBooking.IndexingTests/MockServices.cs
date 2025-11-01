using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Application.Features.Units.Commands.BulkOperations;
using YemenBooking.Application.Features.Pricing.Commands.BulkOperations;
using YemenBooking.Application.Features.Pricing.Commands.SeasonalPricing;
using YemenBooking.Application.Features.Pricing.Queries.GetPricingBreakdown;
using YemenBooking.Core.Entities;

namespace YemenBooking.IndexingTests
{
    /// <summary>
    /// خدمات وهمية للاختبار
    /// </summary>
    public class MockAvailabilityService : IAvailabilityService
    {
        public Task<bool> CheckAvailabilityAsync(Guid unitId, DateTime checkIn, DateTime checkOut, Guid? excludeBookingId = null)
        {
            // افتراض أن جميع الوحدات متاحة للاختبار
            return Task.FromResult(true);
        }

        public Task BlockForBookingAsync(Guid unitId, Guid bookingId, DateTime checkIn, DateTime checkOut)
        {
            // عملية وهمية لحجز الفترة
            return Task.CompletedTask;
        }

        public Task ReleaseBookingAsync(Guid bookingId)
        {
            // عملية وهمية لتحرير الحجز
            return Task.CompletedTask;
        }

        public Task<Dictionary<DateTime, string>> GetMonthlyCalendarAsync(Guid unitId, int year, int month)
        {
            // إرجاع تقويم وهمي كل الأيام متاحة
            var calendar = new Dictionary<DateTime, string>();
            var daysInMonth = DateTime.DaysInMonth(year, month);
            
            for (int day = 1; day <= daysInMonth; day++)
            {
                calendar[new DateTime(year, month, day)] = "available";
            }
            
            return Task.FromResult(calendar);
        }

        public Task ApplyBulkAvailabilityAsync(Guid unitId, List<AvailabilityPeriodDto> periods)
        {
            // عملية وهمية لتطبيق تحديثات التوفر
            return Task.CompletedTask;
        }

        public Task<IEnumerable<Guid>> GetAvailableUnitsInPropertyAsync(
            Guid propertyId,
            DateTime checkIn,
            DateTime checkOut,
            int guestCount,
            CancellationToken cancellationToken = default)
        {
            // إرجاع قائمة وهمية من الوحدات
            var units = new List<Guid> { Guid.NewGuid(), Guid.NewGuid() };
            return Task.FromResult<IEnumerable<Guid>>(units);
        }
    }

    /// <summary>
    /// خدمة تسعير وهمية للاختبار
    /// </summary>
    public class MockPricingService : IPricingService
    {
        public Task<decimal> CalculatePriceAsync(Guid unitId, DateTime checkIn, DateTime checkOut)
        {
            // سعر افتراضي للاختبار
            var nights = (checkOut - checkIn).Days;
            if (nights <= 0) nights = 1;
            return Task.FromResult(100m * nights);
        }

        public Task<Dictionary<DateTime, decimal>> GetPricingCalendarAsync(Guid unitId, int year, int month)
        {
            // إرجاع تقويم تسعير وهمي
            var calendar = new Dictionary<DateTime, decimal>();
            var daysInMonth = DateTime.DaysInMonth(year, month);
            
            for (int day = 1; day <= daysInMonth; day++)
            {
                calendar[new DateTime(year, month, day)] = 100m; // سعر ثابت
            }
            
            return Task.FromResult(calendar);
        }

        public Task ApplySeasonalPricingAsync(Guid unitId, SeasonalPricingDto seasonalPricing)
        {
            // عملية وهمية
            return Task.CompletedTask;
        }

        public Task ApplyBulkPricingAsync(Guid unitId, List<PricingPeriodDto> periods)
        {
            // عملية وهمية
            return Task.CompletedTask;
        }

        public Task<PricingBreakdownDto> GetPricingBreakdownAsync(Guid unitId, DateTime checkIn, DateTime checkOut)
        {
            // إرجاع تفاصيل تسعير وهمية
            var nights = (checkOut - checkIn).Days;
            if (nights <= 0) nights = 1;
            var totalPrice = 100m * nights;
            
            var days = new List<DayPriceDto>();
            
            for (var date = checkIn; date < checkOut; date = date.AddDays(1))
            {
                days.Add(new DayPriceDto
                {
                    Date = date,
                    Price = 100m,
                    PriceType = "Standard"
                });
            }
            
            var breakdown = new PricingBreakdownDto
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                TotalNights = nights,
                Currency = "YER",
                Days = days,
                SubTotal = totalPrice,
                Total = totalPrice
            };
            
            return Task.FromResult(breakdown);
        }
    }
}
