using System;
using MediatR;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.FinancialAnalytics;

/// <summary>
/// استعلام للحصول على تفصيل الإيرادات الكلي لمنصة ضمن نطاق زمني
/// Query to get total platform revenue breakdown within a date range
/// </summary>
public class GetPlatformRevenueBreakdownQuery : IRequest<ResultDto<RevenueBreakdownDto>>
{
    /// <summary>
    /// النطاق الزمني
    /// Date range
    /// </summary>
    public DateRangeDto Range { get; set; }

    public GetPlatformRevenueBreakdownQuery(DateRangeDto range)
    {
        Range = range;
    }
} 