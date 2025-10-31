using System;

namespace YemenBooking.Application.Features.Pricing.DTOs {
    /// <summary>
    /// DTO لتحديث سريع للسعر
    /// Quick update pricing request DTO
    /// </summary>
    public class QuickUpdatePricingRequestDto
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal PriceAmount { get; set; }
        public string Currency { get; set; }

    }
} 