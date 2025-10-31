using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Payments.Queries.GetPaymentAnalytics
{
    /// <summary>
    /// استعلام جلب تحليلات المدفوعات والإيرادات
    /// Query to get payment and revenue analytics
    /// </summary>
    public class GetPaymentAnalyticsQuery : IRequest<ResultDto<PaymentAnalyticsDto>>
    {
        /// <summary>
        /// تاريخ البداية (اختياري - افتراضياً آخر 30 يوم)
        /// Start date (optional - defaults to last 30 days)
        /// </summary>
        public DateTime? StartDate { get; set; }

        /// <summary>
        /// تاريخ النهاية (اختياري - افتراضياً اليوم)
        /// End date (optional - defaults to today)
        /// </summary>
        public DateTime? EndDate { get; set; }

        /// <summary>
        /// معرف العقار (اختياري - للفلترة حسب عقار معين)
        /// Property ID (optional - to filter by specific property)
        /// </summary>
        public Guid? PropertyId { get; set; }
    }
}
