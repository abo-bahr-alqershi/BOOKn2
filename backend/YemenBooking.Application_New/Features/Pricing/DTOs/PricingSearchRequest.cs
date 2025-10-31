using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Pricing.DTOs {
    /// <summary>
    /// طلب البحث عن قواعد التسعير
    /// DTO for pricing search request
    /// </summary>
    public class PricingSearchRequest
    {
        /// <summary>
        /// قائمة معرفات الوحدات
        /// List of unit IDs
        /// </summary>
        public IEnumerable<Guid>? UnitIds { get; set; }

        /// <summary>
        /// معرف الكيان
        /// Property ID
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// تاريخ البداية
        /// Start date
        /// </summary>
        public DateTime? StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية
        /// End date
        /// </summary>
        public DateTime? EndDate { get; set; }

        /// <summary>
        /// قائمة أنواع الأسعار
        /// Price types
        /// </summary>
        public IEnumerable<string>? PriceTypes { get; set; }

        /// <summary>
        /// قائمة فئات التسعير
        /// Pricing tiers
        /// </summary>
        public IEnumerable<string>? PricingTiers { get; set; }

        /// <summary>
        /// تضمين التعارضات
        /// Include conflicts
        /// </summary>
        public bool? IncludeConflicts { get; set; }
    }
} 