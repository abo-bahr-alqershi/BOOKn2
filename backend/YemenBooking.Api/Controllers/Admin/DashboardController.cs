using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Analytics.Commands.Reports;
using YemenBooking.Application.Features.Analytics.Queries.Dashboard;
using YemenBooking.Application.Features.Analytics.Queries.UserAnalytics;
using YemenBooking.Application.Features.Analytics.Queries.FinancialAnalytics;
using YemenBooking.Application.Features.Payments.Queries.GetPaymentAnalytics;
using YemenBooking.Application.Features.Analytics.Queries.PropertyAnalytics;
using YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics;
using YemenBooking.Application.Features.Analytics.Queries;
using System;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بمعلومات لوحة تحكم الإدارة
    /// Controller for admin dashboard operations
    /// </summary>
    public class DashboardController : BaseAdminController
    {
        public DashboardController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// استعلام عن بيانات لوحة القيادة للإدارة
        /// Get admin dashboard data for the given date range
        /// </summary>
        [HttpPost("dashboard")]
        public async Task<IActionResult> GetAdminDashboard([FromBody] GetAdminDashboardQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// تصدير تقرير لوحة القيادة
        /// Export dashboard report
        /// </summary>
        [HttpPost("dashboard/export")]
        public async Task<IActionResult> ExportDashboardReport([FromBody] ExportDashboardReportCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// استعلام تقرير العملاء
        /// Get customer report
        /// </summary>
        [HttpGet("dashboard/customer-report")]
        public async Task<IActionResult> GetCustomerReport([FromQuery] GetCustomerReportQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام الملخص المالي
        /// Get financial summary
        /// </summary>
        [HttpGet("dashboard/financial-summary")]
        public async Task<IActionResult> GetFinancialSummary([FromQuery] GetFinancialSummaryQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام مؤشرات أداء الكيان
        /// Get property performance
        /// </summary>
        [HttpPost("dashboard/performance")]
        public async Task<IActionResult> GetPropertyPerformance([FromBody] GetPropertyPerformanceQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام مقارنة أداء الكيان
        /// Get property performance comparison
        /// </summary>
        [HttpPost("dashboard/performance-comparison")]
        public async Task<IActionResult> GetPropertyPerformanceComparison([FromBody] GetPropertyPerformanceComparisonQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام نسبة الإشغال لكيان
        /// Get occupancy rate
        /// </summary>
        [HttpPost("dashboard/occupancy-rate")]
        public async Task<IActionResult> GetOccupancyRate([FromBody] GetOccupancyRateQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام تقرير الإشغال
        /// Get occupancy report
        /// </summary>
        [HttpPost("dashboard/occupancy-report")]
        public async Task<IActionResult> GetOccupancyReport([FromBody] GetOccupancyReportQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام تقرير الإيرادات
        /// Get revenue report
        /// </summary>
        [HttpPost("dashboard/revenue-report")]
        public async Task<IActionResult> GetRevenueReport([FromBody] GetRevenueReportQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام تحليل أسباب إلغاء الحجوزات
        /// Get platform cancellation analysis
        /// </summary>
        [HttpPost("dashboard/cancellation-analysis")]
        public async Task<IActionResult> GetPlatformCancellationAnalysis([FromBody] GetPlatformCancellationAnalysisQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام تفصيل الإيرادات للمنصة
        /// Get platform revenue breakdown
        /// </summary>
        [HttpPost("dashboard/revenue-breakdown")]
        public async Task<IActionResult> GetPlatformRevenueBreakdown([FromBody] GetPlatformRevenueBreakdownQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام قمع اكتساب العملاء
        /// Get user acquisition funnel
        /// </summary>
        [HttpPost("dashboard/user-acquisition-funnel")]
        public async Task<IActionResult> GetUserAcquisitionFunnel([FromBody] GetUserAcquisitionFunnelQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام للحصول على تحليل أفواج العملاء ضمن نطاق زمني
        /// Query to get customer cohort analysis within a date range
        /// </summary>
        [HttpPost("dashboard/customer-cohort-analysis")]
        public async Task<IActionResult> GetCustomerCohortAnalysis([FromBody] GetCustomerCohortAnalysisQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام للحصول على تحليل مشاعر التقييمات لكيان محدد
        /// Query to get review sentiment analysis for a specific property
        /// </summary>
        [HttpGet("dashboard/review-sentiment-analysis/{propertyId}")]
        public async Task<IActionResult> GetReviewSentimentAnalysis(Guid propertyId)
        {
            var query = new GetReviewSentimentAnalysisQuery(propertyId);
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// استعلام أفضل الكيانات أداءً
        /// Get top performing properties
        /// </summary>
        [HttpGet("dashboard/top-properties/{count}")]
        public async Task<IActionResult> GetTopPerformingProperties(int count)
        {
            var query = new GetTopPerformingPropertiesQuery(count);
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 