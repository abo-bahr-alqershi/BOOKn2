using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.FinancialAnalytics
{
    /// <summary>
    /// استعلام للحصول على الملخص المالي
    /// Query to get financial summary
    /// </summary>
    public class GetFinancialSummaryQuery : IRequest<ResultDto<FinancialSummaryDto>>
    {
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

        /// <summary>
        /// معرف الكيان (اختياري)
        /// Property identifier (optional)
        /// </summary>
        public Guid? PropertyId { get; set; }
    }
} 