using System.Collections.Generic;

namespace YemenBooking.Application.Features.Reports.DTOs {
    /// <summary>
    /// تقرير العميل
    /// Customer report DTO
    /// </summary>
    public class CustomerReportDto
    {
        /// <summary>
        /// عناصر تقرير العملاء
        /// Customer report items
        /// </summary>
        public List<CustomerReportItemDto> Items { get; set; } = new List<CustomerReportItemDto>();
    }
} 