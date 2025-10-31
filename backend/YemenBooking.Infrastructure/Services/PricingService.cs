// using System;
// using System.Collections.Generic;
// using System.Threading;
// using System.Threading.Tasks;
// using YemenBooking.Core.Entities;
// using YemenBooking.Core.Enums;
// using YemenBooking.Core.Interfaces.Repositories;
// using YemenBooking.Application.Infrastructure.Services;
// using System.Linq;

// namespace YemenBooking.Infrastructure.Services
// {
//     /// <summary>
//     /// تنفيذ خدمة التسعير
//     /// Pricing service implementation
//     /// </summary>
//     public class PricingService : IPricingService
//     {
//         private readonly IUnitRepository _unitRepository;
//         private readonly IBookingRepository _bookingRepository;
//         private readonly IPricingRuleRepository _pricingRuleRepository;

//         public PricingService(IUnitRepository unitRepository, IBookingRepository bookingRepository, IPricingRuleRepository pricingRuleRepository)
//         {
//             _unitRepository = unitRepository;
//             _bookingRepository = bookingRepository;
//             _pricingRuleRepository = pricingRuleRepository;
//         }

//         /// <summary>
//         /// حساب السعر وفقاً لطريقة التسعير وتاريخي الوصول والمغادرة
//         /// Calculate price based on pricing method and check-in/check-out dates
//         /// </summary>
//         public async Task<decimal> CalculatePriceAsync(Guid unitId, DateTime checkIn, DateTime checkOut, int guestCount, CancellationToken cancellationToken = default)
//         {
//             var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
//             if (unit == null)
//                 throw new ArgumentException($"Unit with ID '{unitId}' not found.");

//             var baseAmount = unit.BasePrice.Amount;
//             var method = unit.PricingMethod;

//             // اجلب قواعد التسعير للفترة المعنية
//             var rules = (await _pricingRuleRepository
//                 .GetPricingRulesByUnitAsync(unitId, checkIn.Date, checkOut.Date, cancellationToken))
//                 .OrderBy(r => r.StartDate)
//                 .ToList();

//             decimal PriceForDate(DateTime date)
//             {
//                 var rule = rules.FirstOrDefault(r => r.StartDate.Date <= date.Date && r.EndDate.Date >= date.Date);
//                 return rule?.PriceAmount ?? baseAmount;
//             }

//             decimal PriceForHour(DateTime dateTime)
//             {
//                 var rule = rules.FirstOrDefault(r =>
//                     r.StartDate.Date <= dateTime.Date && r.EndDate.Date >= dateTime.Date &&
//                     (!r.StartTime.HasValue || r.StartTime.Value <= dateTime.TimeOfDay) &&
//                     (!r.EndTime.HasValue || r.EndTime.Value >= dateTime.TimeOfDay));
//                 return rule?.PriceAmount ?? baseAmount;
//             }

//             decimal price = 0m;

//             switch (method)
//             {
//                 case PricingMethod.Hourly:
//                 {
//                     var totalHours = (int)Math.Ceiling((checkOut - checkIn).TotalHours);
//                     var cursor = checkIn;
//                     for (int h = 0; h < totalHours; h++)
//                     {
//                         price += PriceForHour(cursor);
//                         cursor = cursor.AddHours(1);
//                     }
//                     break;
//                 }
//                 case PricingMethod.Daily:
//                 default:
//                 {
//                     // اجمع سعر كل يوم ضمن النطاق. هذا يغطي أيضاً الأسبوعي/الشهري كنهج محافظ عند وجود قواعد.
//                     var totalDays = (int)Math.Ceiling((checkOut.Date - checkIn.Date).TotalDays);
//                     if (totalDays <= 0) totalDays = 1;

//                     if (rules.Any())
//                     {
//                         var day = checkIn.Date;
//                         for (int d = 0; d < totalDays; d++)
//                         {
//                             price += PriceForDate(day);
//                             day = day.AddDays(1);
//                         }
//                     }
//                     else
//                     {
//                         // لا توجد قواعد: استخدم الطريقة الأصلية مضروباً في السعر الأساسي
//                         price = method switch
//                         {
//                             PricingMethod.Weekly => baseAmount * (decimal)Math.Ceiling((checkOut.Date - checkIn.Date).TotalDays / 7.0),
//                             PricingMethod.Monthly => baseAmount * (((checkOut.Year - checkIn.Year) * 12) + (checkOut.Month - checkIn.Month) + (checkOut.Day > checkIn.Day ? 1 : 0)),
//                             _ => baseAmount * totalDays
//                         };
//                     }
//                     break;
//                 }
//             }

//             return price;
//         }

//         public async Task<decimal> RecalculatePriceAsync(Guid bookingId, DateTime? newCheckIn = null, DateTime? newCheckOut = null, int? newGuestCount = null, CancellationToken cancellationToken = default)
//         {
//             var booking = await _bookingRepository.GetBookingByIdAsync(bookingId, cancellationToken);
//             if (booking == null)
//                 throw new ArgumentException($"Booking with ID '{bookingId}' not found.");
//             return booking.TotalPrice.Amount;
//         }

//         public async Task<decimal> CalculateBasePriceAsync(Guid unitId, int nights, CancellationToken cancellationToken = default)
//         {
//             var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
//             if (unit == null)
//                 throw new ArgumentException($"Unit with ID '{unitId}' not found.");
//             return unit.BasePrice.Amount * nights;
//         }

//         public Task<decimal> CalculateAdditionalFeesAsync(Guid unitId, int guestCount, IEnumerable<Guid>? serviceIds = null, CancellationToken cancellationToken = default)
//         {
//             // TODO: إضافة رسوم إضافية بناءً على الخدمات
//             return Task.FromResult(0m);
//         }

//         public Task<decimal> CalculateDiscountsAsync(Guid unitId, DateTime checkIn, DateTime checkOut, Guid? userId = null, CancellationToken cancellationToken = default)
//         {
//             // TODO: حساب الخصومات مثل العروض أو الخصومات الموسمية
//             return Task.FromResult(0m);
//         }

//         public Task<decimal> CalculateTaxesAsync(decimal baseAmount, Guid propertyId, CancellationToken cancellationToken = default)
//         {
//             // فرض معدل ضريبة ثابت 5%
//             var tax = Math.Round(baseAmount * 0.05m, 2);
//             return Task.FromResult(tax);
//         }

//         public async Task<object> GetPricingBreakdownAsync(Guid unitId, DateTime checkIn, DateTime checkOut, int guestCount, CancellationToken cancellationToken = default)
//         {
//             var nights = (checkOut.Date - checkIn.Date).Days;
//             var basePrice = await CalculateBasePriceAsync(unitId, nights, cancellationToken);
//             var fees = await CalculateAdditionalFeesAsync(unitId, guestCount, null, cancellationToken);
//             var discounts = await CalculateDiscountsAsync(unitId, checkIn, checkOut, null, cancellationToken);
//             var taxes = await CalculateTaxesAsync(basePrice, Guid.Empty, cancellationToken);
//             var total = basePrice + fees + taxes - discounts;
//             return new
//             {
//                 BasePrice = basePrice,
//                 AdditionalFees = fees,
//                 Discounts = discounts,
//                 Taxes = taxes,
//                 TotalPrice = total
//             };
//         }
//     }
// } 
using YemenBooking.Application.Features.Pricing.Commands;
using YemenBooking.Application.Features.Pricing.Commands.SeasonalPricing;
using YemenBooking.Application.Features.Pricing.Commands.BulkOperations;
using YemenBooking.Application.Features.Pricing.DTOs;
using YemenBooking.Application.Features.Pricing.Queries.GetPricingBreakdown;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Infrastructure.Services;

public class PricingService : IPricingService
{
    private readonly IPricingRuleRepository _pricingRepository;
    private readonly IUnitRepository _unitRepository;

    public PricingService(
        IPricingRuleRepository pricingRepository,
        IUnitRepository unitRepository)
    {
        _pricingRepository = pricingRepository;
        _unitRepository = unitRepository;
    }

    public async Task<decimal> CalculatePriceAsync(Guid unitId, DateTime checkIn, DateTime checkOut)
    {
        var unit = await _unitRepository.GetByIdAsync(unitId);
        if (unit == null)
            throw new Exception("Unit not found");

        var totalPrice = 0m;
        var currentDate = checkIn.Date;

        while (currentDate < checkOut.Date)
        {
            var dayPrice = await GetDayPriceAsync(unitId, currentDate, unit.BasePrice.Amount);
            totalPrice += dayPrice;
            currentDate = currentDate.AddDays(1);
        }

        return totalPrice;
    }

    private async Task<decimal> GetDayPriceAsync(Guid unitId, DateTime date, decimal basePrice)
    {
        var rule = await _pricingRepository.GetPriceForDateAsync(unitId, date);
        
        if (rule == null)
            return basePrice;

        // Apply percentage change if exists
        if (rule.PercentageChange.HasValue)
        {
            var change = basePrice * (rule.PercentageChange.Value / 100);
            return basePrice + change;
        }

        return rule.PriceAmount;
    }

    public async Task<Dictionary<DateTime, decimal>> GetPricingCalendarAsync(Guid unitId, int year, int month)
    {
        return await _pricingRepository.GetPricingCalendarAsync(unitId, year, month);
    }

    public async Task ApplySeasonalPricingAsync(Guid unitId, SeasonalPricingDto seasonalPricing)
    {
        var rules = new List<PricingRule>();

        foreach (var season in seasonalPricing.Seasons)
        {
            var rule = new PricingRule
            {
                Id = Guid.NewGuid(),
                UnitId = unitId,
                PriceType = season.Type,
                StartDate = season.StartDate,
                EndDate = season.EndDate,
                PriceAmount = season.Price,
                PricingTier = season.Priority.ToString(),
                PercentageChange = season.PercentageChange,
                MinPrice = season.MinPrice,
                MaxPrice = season.MaxPrice,
                Description = season.Description,
                Currency = seasonalPricing.Currency,
                CreatedAt = DateTime.UtcNow
            };
            
            rules.Add(rule);
        }

        await _pricingRepository.BulkCreateAsync(rules);
    }

    public async Task ApplyBulkPricingAsync(Guid unitId, List<PricingPeriodDto> periods)
    {
        var rules = new List<PricingRule>();

        foreach (var period in periods)
        {
            // Delete existing rules in this range if needed
            if (period.OverwriteExisting)
            {
                await _pricingRepository.DeleteRangeAsync(unitId, period.StartDate, period.EndDate);
            }

            var rule = new PricingRule
            {
                Id = Guid.NewGuid(),
                UnitId = unitId,
                PriceType = period.PriceType,
                StartDate = period.StartDate,
                EndDate = period.EndDate,
                StartTime = period.StartTime,
                EndTime = period.EndTime,
                PriceAmount = period.Price,
                PricingTier = string.IsNullOrWhiteSpace(period.Tier) ? "1" : period.Tier,
                PercentageChange = period.PercentageChange,
                MinPrice = period.MinPrice,
                MaxPrice = period.MaxPrice,
                Description = period.Description,
                Currency = period.Currency,
                CreatedAt = DateTime.UtcNow
            };
            
            rules.Add(rule);
        }

        await _pricingRepository.BulkCreateAsync(rules);
    }

    public async Task<PricingBreakdownDto> GetPricingBreakdownAsync(Guid unitId, DateTime checkIn, DateTime checkOut)
    {
        var unit = await _unitRepository.GetByIdAsync(unitId);
        if (unit == null)
            throw new Exception("Unit not found");

        var breakdown = new PricingBreakdownDto
        {
            CheckIn = checkIn,
            CheckOut = checkOut,
            Currency = unit.BasePrice.Currency,
            Days = new List<DayPriceDto>()
        };

        var currentDate = checkIn.Date;

        while (currentDate < checkOut.Date)
        {
            var dayPrice = await GetDayPriceAsync(unitId, currentDate, unit.BasePrice.Amount);
            var rule = await _pricingRepository.GetPriceForDateAsync(unitId, currentDate);

            breakdown.Days.Add(new DayPriceDto
            {
                Date = currentDate,
                Price = dayPrice,
                PriceType = rule?.PriceType ?? "Base",
                Description = rule?.Description
            });

            currentDate = currentDate.AddDays(1);
        }

        breakdown.TotalNights = breakdown.Days.Count;
        breakdown.SubTotal = breakdown.Days.Sum(d => d.Price);
        breakdown.Total = breakdown.SubTotal; // Add taxes/fees if needed

        return breakdown;
    }
}