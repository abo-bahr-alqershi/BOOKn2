using System;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class AvailabilityStatisticsDto
    {
        public DateRangeRequestDto DateRange { get; set; }
        public int TotalDays { get; set; }
        public int AvailableDays { get; set; }
        public int UnavailableDays { get; set; }
        public int MaintenanceDays { get; set; }
        public int BookedDays { get; set; }
        public double OccupancyRate { get; set; }
        public decimal RevenueLostDueToUnavailability { get; set; }
        public decimal AverageDailyRate { get; set; }
        public decimal RevenuePerAvailableUnit { get; set; }
    }
} 