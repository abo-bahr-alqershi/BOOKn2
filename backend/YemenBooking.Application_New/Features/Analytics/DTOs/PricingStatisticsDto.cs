using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class PricingStatisticsDto
    {
        public DateRangeRequestDto DateRange { get; set; }
        public decimal AveragePrice { get; set; }
        public decimal MinPrice { get; set; }
        public decimal MaxPrice { get; set; }
        public decimal PriceVariance { get; set; }
        public IEnumerable<SeasonalAdjustmentDto> SeasonalAdjustments { get; set; }
        public CompetitorComparisonDto? CompetitorComparison { get; set; }
    }
} 