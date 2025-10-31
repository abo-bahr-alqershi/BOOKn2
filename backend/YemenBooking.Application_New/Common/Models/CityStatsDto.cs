using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Common.Models
{
    /// <summary>
    /// City statistics with optional trend indicators over a date window
    /// </summary>
    public class CityStatsDto
    {
        public int TotalCities { get; set; }
        public int ActiveCities { get; set; }
        public Dictionary<string, int> ByCountry { get; set; } = new();

        // Aggregate media
        public int TotalImages { get; set; }
        public double? ImagesTrend { get; set; }

        // Trends over [startDate, endDate] vs previous equal-length window
        public int UpdatesCount { get; set; }
        public double? UpdatesTrendPct { get; set; }
    }
}
