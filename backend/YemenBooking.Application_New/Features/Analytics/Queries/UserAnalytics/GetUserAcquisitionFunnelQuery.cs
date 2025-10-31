using System;
using MediatR;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.UserAnalytics;

/// <summary>
/// استعلام للحصول على بيانات قمع اكتساب العملاء ضمن نطاق زمني
/// Query to get user acquisition funnel data within a date range
/// </summary>
public class GetUserAcquisitionFunnelQuery : IRequest<ResultDto<UserFunnelDto>>
{
    /// <summary>
    /// النطاق الزمني
    /// Date range
    /// </summary>
    public DateRangeDto Range { get; set; }

    public GetUserAcquisitionFunnelQuery(DateRangeDto range)
    {
        Range = range;
    }
} 