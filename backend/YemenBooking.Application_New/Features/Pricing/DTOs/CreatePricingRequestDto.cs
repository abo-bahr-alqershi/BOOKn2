using System;

namespace YemenBooking.Application.Features.Pricing.DTOs {
    /// <summary>
    /// DTO لإنشاء قاعدة تسعير جديدة
    /// Create new pricing rule request DTO
    /// </summary>
    public class CreatePricingRequestDto
    {
        public Guid UnitId { get; set; }
        /// <summary>
        /// نوع السعر (مخفى، افتراضي 'base')
        /// </summary>
        public string PriceType { get; set; } = "base";
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public TimeSpan? StartTime { get; set; }
        public TimeSpan? EndTime { get; set; }
        public decimal PriceAmount { get; set; }
        public string PricingTier { get; set; }
        public decimal? PercentageChange { get; set; }
        public decimal? MinPrice { get; set; }
        public decimal? MaxPrice { get; set; }
        public string? Description { get; set; }
        /// <summary>
        /// عملة السعر
        /// Currency code for the pricing rule
        /// </summary>
        public string Currency { get; set; }
        public bool? OverrideConflicts { get; set; }
    }
} 