using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// بيانات المخططات البيانية المالية
    /// Financial Chart Data DTO
    /// </summary>
    public class FinancialChartDto
    {
        public string Label { get; set; }
        public decimal Value { get; set; }
        public string Color { get; set; }
        public string Category { get; set; }
        public DateTime? Date { get; set; }
    }

    /// <summary>
    /// الملخص المالي الشامل
    /// Comprehensive Financial Summary DTO
    /// </summary>
    public class FinancialSummaryDto
    {
        // الأصول والخصوم
        public decimal TotalAssets { get; set; }
        public decimal TotalLiabilities { get; set; }
        public decimal TotalEquity { get; set; }
        public decimal CurrentAssets { get; set; }
        public decimal CurrentLiabilities { get; set; }
        public decimal WorkingCapital { get; set; }
        
        // نسب السيولة
        public decimal CurrentRatio { get; set; }
        public decimal QuickRatio { get; set; }
        public decimal CashRatio { get; set; }
        
        // نسب الديون
        public decimal DebtToEquityRatio { get; set; }
        public decimal DebtToAssetsRatio { get; set; }
        
        // نسب الربحية
        public decimal ReturnOnAssets { get; set; }
        public decimal ReturnOnEquity { get; set; }
        public decimal GrossProfitMargin { get; set; }
        public decimal NetProfitMargin { get; set; }
        public decimal OperatingProfitMargin { get; set; }
        
        // التدفق النقدي
        public decimal CashFromOperations { get; set; }
        public decimal CashFromInvesting { get; set; }
        public decimal CashFromFinancing { get; set; }
        public decimal NetCashFlow { get; set; }
        
        // مؤشرات إضافية
        public int ActiveBookings { get; set; }
        public int TotalProperties { get; set; }
        public int TotalUnits { get; set; }
        public decimal OccupancyRate { get; set; }
        public decimal AverageBookingValue { get; set; }
        public decimal CustomerAcquisitionCost { get; set; }
        public decimal CustomerLifetimeValue { get; set; }
        
        // التاريخ
        public DateTime CalculatedAt { get; set; }
        public DateTime PeriodStart { get; set; }
        public DateTime PeriodEnd { get; set; }
    }

    /// <summary>
    /// البيانات التحليلية للإيرادات والمصروفات
    /// Revenue and Expense Analytics DTO
    /// </summary>
    public class FinancialAnalyticsDto
    {
        public List<FinancialChartDto> RevenueByCategory { get; set; }
        public List<FinancialChartDto> ExpensesByCategory { get; set; }
        public List<FinancialChartDto> CashFlowOverTime { get; set; }
        public List<FinancialChartDto> RevenueOverTime { get; set; }
        public List<FinancialChartDto> ExpensesOverTime { get; set; }
        public List<FinancialChartDto> ProfitOverTime { get; set; }
        
        public decimal TotalRevenue { get; set; }
        public decimal TotalExpenses { get; set; }
        public decimal NetProfit { get; set; }
        public decimal ProfitMargin { get; set; }
        
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
    }
}
