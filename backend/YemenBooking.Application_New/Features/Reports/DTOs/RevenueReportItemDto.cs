using System;

namespace YemenBooking.Application.Features.Reports.DTOs {
    /// <summary>
    /// عنصر تقرير الإيرادات اليومية
    /// Daily revenue report item
    /// </summary>
    public class RevenueReportItemDto
    {
        /// <summary>
        /// التاريخ
        /// Date
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>
        /// الإجمالي اليومي
        /// Revenue for that day
        /// </summary>
        public decimal Revenue { get; set; }
    }
} 