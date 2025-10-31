using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.UserAnalytics;

/// <summary>
/// استعلام للحصول على تحليل أفواج العملاء ضمن نطاق زمني
/// Query to get customer cohort analysis within a date range
/// </summary>
public class GetCustomerCohortAnalysisQuery : IRequest<ResultDto<List<CohortDto>>>
{
    /// <summary>
    /// النطاق الزمني
    /// Date range
    /// </summary>
    public DateRangeDto Range { get; set; }

    public GetCustomerCohortAnalysisQuery(DateRangeDto range)
    {
        Range = range;
    }
} 