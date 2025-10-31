using System;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Pricing.DTOs {
    /// <summary>
    /// DTO لقاعدة التسعير
    /// DTO for pricing rule
    /// </summary>
    public class PricingRuleDto
    {
        /// <summary>
        /// المعرف الفريد لقاعدة التسعير
        /// Pricing rule identifier
        /// </summary>
        public Guid PricingId { get; set; }

        /// <summary>
        /// معرف الوحدة
        /// Unit identifier
        /// </summary>
        public Guid UnitId { get; set; }

        /// <summary>
        /// نوع السعر
        /// Price type
        /// </summary>
        public string PriceType { get; set; }

        /// <summary>
        /// تاريخ بداية السعر
        /// Start date
        /// </summary>
        public DateTime StartDate { get; set; }

        /// <summary>
        /// تاريخ نهاية السعر
        /// End date
        /// </summary>
        public DateTime EndDate { get; set; }
        public TimeSpan? StartTime { get; set; }
        public TimeSpan? EndTime { get; set; }

        /// <summary>
        /// مبلغ السعر
        /// Price amount
        /// </summary>
        public decimal PriceAmount { get; set; }

        /// <summary>
        /// فئة التسعير
        /// Pricing tier
        /// </summary>
        public string PricingTier { get; set; }

        /// <summary>
        /// الزيادة أو الخصم بالنسبة المئوية
        /// Percentage change
        /// </summary>
        public decimal? PercentageChange { get; set; }

        /// <summary>
        /// السعر الأدنى
        /// Minimum price
        /// </summary>
        public decimal? MinPrice { get; set; }

        /// <summary>
        /// السعر الأقصى
        /// Maximum price
        /// </summary>
        public decimal? MaxPrice { get; set; }

        /// <summary>
        /// الوصف
        /// Description
        /// </summary>
        public string Description { get; set; }
        /// <summary>
        /// عملة السعر
        /// Currency code for the pricing rule
        /// </summary>
        public string Currency { get; set; }
        /// <summary>
        /// السعر الأساسي للوحدة
        /// Base price of the unit
        /// </summary>
        public MoneyDto BasePrice { get; set; }
        // audit fields
        public bool IsActive { get; set; }
        public string CreatedBy { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
} 