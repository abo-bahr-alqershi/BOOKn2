using System;

namespace YemenBooking.Application.Features.Pricing.DTOs {
    /// <summary>
    /// DTO للتحديث السريع للسعر
    /// Quick pricing update request DTO
    /// </summary>
    public class QuickPricingUpdateRequestDto
    {
        public decimal PriceAmount { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
} 