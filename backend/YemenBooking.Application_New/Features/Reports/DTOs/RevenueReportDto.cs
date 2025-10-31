using System.Collections.Generic;

namespace YemenBooking.Application.Features.Reports.DTOs {
    /// <summary>
    /// تقرير الإيرادات
    /// Revenue report DTO
    /// </summary>
    public class RevenueReportDto
    {
        /// <summary>
        /// عناصر تقرير الإيرادات اليومية
        /// Daily revenue report items
        /// </summary>
        public List<RevenueReportItemDto> Items { get; set; } = new List<RevenueReportItemDto>();
    }
} 