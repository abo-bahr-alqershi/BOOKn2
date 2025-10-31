using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    public class ManagementSummaryDto
    {
        public int TotalUnits { get; set; }
        public int AvailableUnits { get; set; }
        public int UnavailableUnits { get; set; }
        public int MaintenanceUnits { get; set; }
        public int BookedUnits { get; set; }
        public decimal TotalRevenueToday { get; set; }
        public double AvgOccupancyRate { get; set; }
        public IEnumerable<PriceAlertDto> PriceAlerts { get; set; }
    }
} 