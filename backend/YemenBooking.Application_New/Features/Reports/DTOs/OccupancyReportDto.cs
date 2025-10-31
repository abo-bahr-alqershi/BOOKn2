using System.Collections.Generic;

namespace YemenBooking.Application.Features.Reports.DTOs {
    /// <summary>
    /// تقرير الإشغال
    /// Occupancy report DTO
    /// </summary>
    public class OccupancyReportDto
    {
        /// <summary>
        /// عناصر تقرير الإشغال اليومي
        /// Daily occupancy report items
        /// </summary>
        public List<OccupancyReportItemDto> Items { get; set; } = new List<OccupancyReportItemDto>();
    }
} 