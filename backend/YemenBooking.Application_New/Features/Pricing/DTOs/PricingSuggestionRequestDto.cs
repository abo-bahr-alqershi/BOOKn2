using System;

namespace YemenBooking.Application.Features.Pricing.DTOs {
    /// <summary>
    /// DTO لطلب اقتراحات الأسعار
    /// Pricing suggestion request DTO
    /// </summary>
    public class PricingSuggestionRequestDto
    {
        public Guid UnitId { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
} 