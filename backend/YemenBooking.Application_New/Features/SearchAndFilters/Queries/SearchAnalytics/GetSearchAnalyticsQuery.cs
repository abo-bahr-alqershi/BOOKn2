using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.SearchAnalytics
{
    /// <summary>
    /// استعلام للحصول على تحليلات البحث
    /// Query to get search analytics
    /// </summary>
    public class GetSearchAnalyticsQuery : IRequest<ResultDto<SearchAnalyticsDto>>
    {
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
    }
} 