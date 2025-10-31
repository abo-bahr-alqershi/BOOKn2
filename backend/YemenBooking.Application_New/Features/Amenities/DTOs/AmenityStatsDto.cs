using System.Collections.Generic;

namespace YemenBooking.Application.Features.Amenities.DTOs {
    /// <summary>
    /// DTO لإحصائيات المرافق
    /// Amenity statistics DTO
    /// </summary>
    public class AmenityStatsDto
    {
        public int TotalAmenities { get; set; }
        public int ActiveAmenities { get; set; }
        public int TotalAssignments { get; set; }
        public decimal TotalRevenue { get; set; }
        public Dictionary<string, int> PopularAmenities { get; set; } = new();
        public Dictionary<string, decimal> RevenueByAmenity { get; set; } = new();
    }
}

