using System;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class PriceAlertDto
    {
        public Guid UnitId { get; set; }
        public string UnitName { get; set; }
        public string AlertType { get; set; }
        public decimal? CurrentPrice { get; set; }
        public decimal? SuggestedPrice { get; set; }
    }
} 