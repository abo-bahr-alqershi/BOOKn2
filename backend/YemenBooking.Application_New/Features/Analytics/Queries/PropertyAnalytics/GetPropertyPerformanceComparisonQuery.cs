using System;
using MediatR;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.PropertyAnalytics;

/// <summary>
/// استعلام للحصول على مقارنة أداء الكيان بين فترتين زمنيتين
/// Query to get property performance comparison between two date ranges
/// </summary>
public class GetPropertyPerformanceComparisonQuery : IRequest<ResultDto<PerformanceComparisonDto>>
{
    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// النطاق الزمني الحالي
    /// Current date range
    /// </summary>
    public DateRangeDto CurrentRange { get; set; }

    /// <summary>
    /// النطاق الزمني السابق
    /// Previous date range
    /// </summary>
    public DateRangeDto PreviousRange { get; set; }

    public GetPropertyPerformanceComparisonQuery(Guid propertyId, DateRangeDto currentRange, DateRangeDto previousRange)
    {
        PropertyId = propertyId;
        CurrentRange = currentRange;
        PreviousRange = previousRange;
    }
} 