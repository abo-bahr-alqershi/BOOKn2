using System;
using MediatR;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics;

/// <summary>
/// استعلام للحصول على تحليل نافذة الحجز لكيان محدد
/// Query to get booking window analysis for a specific property
/// </summary>
public class GetBookingWindowAnalysisQuery : IRequest<ResultDto<BookingWindowDto>>
{
    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    public Guid PropertyId { get; set; }

    public GetBookingWindowAnalysisQuery(Guid propertyId)
    {
        PropertyId = propertyId;
    }
} 