using System;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class AvailabilityCalendarDto
    {
        public DateTime Date { get; set; }
        public string Status { get; set; }
        public string? Reason { get; set; }
        public string? PricingTier { get; set; }
        public decimal? CurrentPrice { get; set; }
        // Currency code for the calendar entry
        public string Currency { get; set; }
    }
} 