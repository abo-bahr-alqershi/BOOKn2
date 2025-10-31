using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries;

/// <summary>
/// استعلام للحصول على تحليل أسباب إلغاء الحجوزات ضمن نطاق زمني
/// Query to get cancellation reasons analysis within a date range
/// </summary>
public class GetPlatformCancellationAnalysisQuery : IRequest<ResultDto<List<CancellationReasonDto>>>
{
    /// <summary>
    /// النطاق الزمني
    /// Date range
    /// </summary>
    public DateRangeDto Range { get; set; }

    public GetPlatformCancellationAnalysisQuery(DateRangeDto range)
    {
        Range = range;
    }
} 