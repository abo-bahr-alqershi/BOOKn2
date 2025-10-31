using System;
using System.Collections.Generic;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Payments.DTOs
{
    /// <summary>
    /// DTO لتحليلات المدفوعات والإيرادات
    /// DTO for payment and revenue analytics
    /// </summary>
    public class PaymentAnalyticsDto
    {
        /// <summary>
        /// ملخص المدفوعات
        /// Payment summary
        /// </summary>
        public PaymentSummaryDto Summary { get; set; }

        /// <summary>
        /// اتجاهات المدفوعات
        /// Payment trends
        /// </summary>
        public List<PaymentTrendDto> Trends { get; set; }

        /// <summary>
        /// تحليلات طرق الدفع
        /// Payment method analytics
        /// </summary>
        public Dictionary<string, MethodAnalyticsDto> MethodAnalytics { get; set; }

        /// <summary>
        /// تحليلات حالات الدفع
        /// Payment status analytics
        /// </summary>
        public Dictionary<string, StatusAnalyticsDto> StatusAnalytics { get; set; }

        /// <summary>
        /// تحليلات الاستردادات
        /// Refund analytics
        /// </summary>
        public RefundAnalyticsDto RefundAnalytics { get; set; }

        /// <summary>
        /// تاريخ البداية
        /// Start date
        /// </summary>
        public DateTime StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية
        /// End date
        /// </summary>
        public DateTime EndDate { get; set; }
    }

    /// <summary>
    /// ملخص المدفوعات
    /// Payment summary
    /// </summary>
    public class PaymentSummaryDto
    {
        /// <summary>
        /// إجمالي المعاملات
        /// Total transactions
        /// </summary>
        public int TotalTransactions { get; set; }

        /// <summary>
        /// إجمالي المبلغ
        /// Total amount
        /// </summary>
        public MoneyDto TotalAmount { get; set; }

        /// <summary>
        /// متوسط قيمة المعاملة
        /// Average transaction value
        /// </summary>
        public MoneyDto AverageTransactionValue { get; set; }

        /// <summary>
        /// معدل النجاح
        /// Success rate
        /// </summary>
        public double SuccessRate { get; set; }

        /// <summary>
        /// المعاملات الناجحة
        /// Successful transactions
        /// </summary>
        public int SuccessfulTransactions { get; set; }

        /// <summary>
        /// المعاملات الفاشلة
        /// Failed transactions
        /// </summary>
        public int FailedTransactions { get; set; }

        /// <summary>
        /// المعاملات المعلقة
        /// Pending transactions
        /// </summary>
        public int PendingTransactions { get; set; }

        /// <summary>
        /// إجمالي المبالغ المستردة
        /// Total refunded
        /// </summary>
        public MoneyDto TotalRefunded { get; set; }

        /// <summary>
        /// عدد الاستردادات
        /// Refund count
        /// </summary>
        public int RefundCount { get; set; }

        /// <summary>
        /// الإيرادات اليومية
        /// Daily revenue
        /// </summary>
        public decimal DailyRevenue { get; set; }

        /// <summary>
        /// الإيرادات الأسبوعية
        /// Weekly revenue
        /// </summary>
        public decimal WeeklyRevenue { get; set; }

        /// <summary>
        /// الإيرادات الشهرية
        /// Monthly revenue
        /// </summary>
        public decimal MonthlyRevenue { get; set; }

        /// <summary>
        /// معدل النمو
        /// Growth rate
        /// </summary>
        public double GrowthRate { get; set; }

        /// <summary>
        /// إيرادات الحجوزات
        /// Bookings revenue
        /// </summary>
        public decimal BookingsRevenue { get; set; }

        /// <summary>
        /// إيرادات الخدمات
        /// Services revenue
        /// </summary>
        public decimal ServicesRevenue { get; set; }

        /// <summary>
        /// إيرادات أخرى
        /// Other revenue
        /// </summary>
        public decimal OtherRevenue { get; set; }
    }

    /// <summary>
    /// اتجاه المدفوعات
    /// Payment trend
    /// </summary>
    public class PaymentTrendDto
    {
        /// <summary>
        /// التاريخ
        /// Date
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>
        /// عدد المعاملات
        /// Transaction count
        /// </summary>
        public int TransactionCount { get; set; }

        /// <summary>
        /// إجمالي المبلغ
        /// Total amount
        /// </summary>
        public MoneyDto TotalAmount { get; set; }

        /// <summary>
        /// معدل النجاح
        /// Success rate
        /// </summary>
        public double SuccessRate { get; set; }

        /// <summary>
        /// توزيع طرق الدفع
        /// Method breakdown
        /// </summary>
        public Dictionary<string, int> MethodBreakdown { get; set; }
    }

    /// <summary>
    /// تحليلات طريقة الدفع
    /// Method analytics
    /// </summary>
    public class MethodAnalyticsDto
    {
        /// <summary>
        /// طريقة الدفع
        /// Payment method
        /// </summary>
        public string Method { get; set; }

        /// <summary>
        /// عدد المعاملات
        /// Transaction count
        /// </summary>
        public int TransactionCount { get; set; }

        /// <summary>
        /// إجمالي المبلغ
        /// Total amount
        /// </summary>
        public MoneyDto TotalAmount { get; set; }

        /// <summary>
        /// النسبة المئوية
        /// Percentage
        /// </summary>
        public double Percentage { get; set; }

        /// <summary>
        /// معدل النجاح
        /// Success rate
        /// </summary>
        public double SuccessRate { get; set; }

        /// <summary>
        /// متوسط المبلغ
        /// Average amount
        /// </summary>
        public MoneyDto AverageAmount { get; set; }
    }

    /// <summary>
    /// تحليلات حالة الدفع
    /// Status analytics
    /// </summary>
    public class StatusAnalyticsDto
    {
        /// <summary>
        /// حالة الدفع
        /// Payment status
        /// </summary>
        public string Status { get; set; }

        /// <summary>
        /// العدد
        /// Count
        /// </summary>
        public int Count { get; set; }

        /// <summary>
        /// إجمالي المبلغ
        /// Total amount
        /// </summary>
        public MoneyDto TotalAmount { get; set; }

        /// <summary>
        /// النسبة المئوية
        /// Percentage
        /// </summary>
        public double Percentage { get; set; }
    }

    /// <summary>
    /// تحليلات الاستردادات
    /// Refund analytics
    /// </summary>
    public class RefundAnalyticsDto
    {
        /// <summary>
        /// إجمالي الاستردادات
        /// Total refunds
        /// </summary>
        public int TotalRefunds { get; set; }

        /// <summary>
        /// إجمالي المبلغ المسترد
        /// Total refunded amount
        /// </summary>
        public MoneyDto TotalRefundedAmount { get; set; }

        /// <summary>
        /// معدل الاسترداد
        /// Refund rate
        /// </summary>
        public double RefundRate { get; set; }

        /// <summary>
        /// متوسط وقت الاسترداد
        /// Average refund time
        /// </summary>
        public double AverageRefundTime { get; set; }

        /// <summary>
        /// أسباب الاسترداد
        /// Refund reasons
        /// </summary>
        public Dictionary<string, int> RefundReasons { get; set; }

        /// <summary>
        /// اتجاهات الاستردادات
        /// Refund trends
        /// </summary>
        public List<RefundTrendDto> Trends { get; set; }
    }

    /// <summary>
    /// اتجاه الاستردادات
    /// Refund trend
    /// </summary>
    public class RefundTrendDto
    {
        /// <summary>
        /// التاريخ
        /// Date
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>
        /// عدد الاستردادات
        /// Refund count
        /// </summary>
        public int RefundCount { get; set; }

        /// <summary>
        /// المبلغ المسترد
        /// Refunded amount
        /// </summary>
        public MoneyDto RefundedAmount { get; set; }
    }

}
