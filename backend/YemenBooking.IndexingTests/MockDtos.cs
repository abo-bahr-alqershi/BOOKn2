using System;
using System.Collections.Generic;

// تم حذف PricingBreakdownDto لأنه موجود في المشروع الأصلي

namespace YemenBooking.Application.Features.Units.Commands.BulkOperations
{
    /// <summary>
    /// DTO فترة الإتاحة
    /// </summary>
    public class AvailabilityPeriodDto
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string Status { get; set; } = "available";
    }
}

namespace YemenBooking.Application.Features.Pricing.Commands.BulkOperations
{
    /// <summary>
    /// DTO فترة التسعير
    /// </summary>
    public class PricingPeriodDto
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal Price { get; set; }
    }
}

namespace YemenBooking.Application.Features.Pricing.Commands.SeasonalPricing
{
    /// <summary>
    /// DTO التسعير الموسمي
    /// </summary>
    public class SeasonalPricingDto
    {
        public string SeasonName { get; set; } = string.Empty;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal PriceModifier { get; set; }
    }
}
