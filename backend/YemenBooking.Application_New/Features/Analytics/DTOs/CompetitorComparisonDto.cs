namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class CompetitorComparisonDto
    {
        public decimal OurAverage { get; set; }
        public decimal MarketAverage { get; set; }
        public string PricePosition { get; set; }
        public decimal SuggestedAdjustment { get; set; }
    }
} 