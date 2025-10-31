using System;
using MediatR;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries;

/// <summary>
/// استعلام للحصول على تحليل مشاعر التقييمات لكيان محدد
/// Query to get review sentiment analysis for a specific property
/// </summary>
public class GetReviewSentimentAnalysisQuery : IRequest<ResultDto<ReviewSentimentDto>>
{
    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    public Guid PropertyId { get; set; }

    public GetReviewSentimentAnalysisQuery(Guid propertyId)
    {
        PropertyId = propertyId;
    }
} 