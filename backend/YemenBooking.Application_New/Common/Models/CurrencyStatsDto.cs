using System;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// Currency statistics with optional trend indicators over a date window
    /// </summary>
    public class CurrencyStatsDto
    {
        public int TotalCurrencies { get; set; }
        public string? DefaultCurrencyCode { get; set; }
        public int CurrenciesWithExchangeRate { get; set; }
        public double AverageExchangeRate { get; set; }
        public DateTime? LastUpdated { get; set; }

        // Trends over [startDate, endDate] vs previous equal-length window
        public int UpdatesCount { get; set; }
        public double? UpdatesTrendPct { get; set; }
        public double? AverageUpdatedRate { get; set; }
        public double? AverageUpdatedRateTrendPct { get; set; }
    }
}
