using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.FinancialAnalytics
{
    /// <summary>
    /// استعلام للحصول على تقرير الإيرادات
    /// Query to get revenue report
    /// </summary>
    public class GetRevenueReportQuery : IRequest<ResultDto<RevenueReportDto>>
    {
        /// <summary>
        /// تاريخ البداية
        /// </summary>
        public DateTime StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية
        /// </summary>
        public DateTime EndDate { get; set; }

        /// <summary>
        /// معرف الكيان (اختياري)
        /// </summary>
        public Guid? PropertyId { get; set; }
    }
} 