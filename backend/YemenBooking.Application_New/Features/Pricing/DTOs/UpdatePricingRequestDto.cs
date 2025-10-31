using System;

namespace YemenBooking.Application.Features.Pricing.DTOs {
    /// <summary>
    /// DTO لتحديث قاعدة تسعير
    /// Update pricing rule request DTO
    /// </summary>
    public class UpdatePricingRequestDto : CreatePricingRequestDto
    {
        public Guid PricingId { get; set; }
        // Currency is inherited from CreatePricingRequestDto
    }
} 