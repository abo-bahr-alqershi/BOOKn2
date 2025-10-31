using YemenBooking.Application.Features.Pricing.Commands.BulkOperations;
using YemenBooking.Application.Features.Pricing.Commands.SeasonalPricing;
using YemenBooking.Application.Features.Pricing.Queries.GetPricingBreakdown;

namespace YemenBooking.Application.Features.Pricing.Services;

/// <summary>
/// واجهة خدمة التسعير
/// Pricing service interface
/// </summary>
public interface IPricingService
{
    /// <summary>
    /// حساب السعر الإجمالي لفترة إقامة
    /// Calculate the total price for a stay
    /// </summary>
    Task<decimal> CalculatePriceAsync(Guid unitId, DateTime checkIn, DateTime checkOut);

    /// <summary>
    /// الحصول على تقويم التسعير الشهري لوحدة معينة
    /// Retrieve the monthly pricing calendar for a unit
    /// </summary>
    Task<Dictionary<DateTime, decimal>> GetPricingCalendarAsync(Guid unitId, int year, int month);

    /// <summary>
    /// تطبيق تسعير موسمي مخصص
    /// Apply seasonal pricing rules for a unit
    /// </summary>
    Task ApplySeasonalPricingAsync(Guid unitId, SeasonalPricingDto seasonalPricing);

    /// <summary>
    /// تطبيق تسعير مجمع عبر فترات متعددة
    /// Apply bulk pricing periods for a unit
    /// </summary>
    Task ApplyBulkPricingAsync(Guid unitId, List<PricingPeriodDto> periods);

    /// <summary>
    /// الحصول على تفاصيل التسعير التفصيلية لفترة إقامة
    /// Retrieve a detailed pricing breakdown for the stay
    /// </summary>
    Task<PricingBreakdownDto> GetPricingBreakdownAsync(Guid unitId, DateTime checkIn, DateTime checkOut);
}