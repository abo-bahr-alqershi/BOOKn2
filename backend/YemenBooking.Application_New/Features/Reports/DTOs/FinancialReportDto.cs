using System;
using System.Collections.Generic;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Reports.DTOs {
    /// <summary>
    /// DTO للتقرير المالي
    /// Financial Report DTO
    /// </summary>
    public class FinancialReportDto
    {
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public decimal TotalRevenue { get; set; }
        public decimal TotalExpenses { get; set; }
        public decimal TotalCommissions { get; set; }
        public decimal TotalRefunds { get; set; }
        public decimal NetProfit { get; set; }
        public int TransactionCount { get; set; }
        public Dictionary<TransactionType, decimal> TransactionsByType { get; set; }
    }
}
