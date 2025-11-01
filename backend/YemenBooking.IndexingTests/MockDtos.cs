using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Pricing.Queries.GetPricingBreakdown
{
    /// <summary>
    /// DTOs وهمية للاختبار
    /// </summary>
    public class PricingBreakdownDto
    {
        public DateTime CheckIn { get; set; }
        public DateTime CheckOut { get; set; }
        public int TotalNights { get; set; }
        public string Currency { get; set; } = "YER";
    }

    public class DailyRateDto
    {
        public DateTime Date { get; set; }
        public decimal Price { get; set; }
        public string AppliedRuleName { get; set; } = string.Empty;
    }
}

namespace YemenBooking.Application.Features.Units.Commands.BulkOperations
{
    public class AvailabilityPeriodDto
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; } = "available";
    }
}

namespace YemenBooking.Application.Features.Pricing.Commands.BulkOperations
{
    public class PricingPeriodDto
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal Price { get; set; }
    }
}

namespace YemenBooking.Application.Features.Pricing.Commands.SeasonalPricing
{
    public class SeasonalPricingDto
    {
        public string SeasonName { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal PriceModifier { get; set; }
    }
}
