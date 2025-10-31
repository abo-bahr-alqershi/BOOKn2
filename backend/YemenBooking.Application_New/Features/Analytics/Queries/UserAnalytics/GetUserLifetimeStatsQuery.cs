using System;
using MediatR;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.UserAnalytics;

/// <summary>
/// استعلام للحصول على إحصائيات المستخدم مدى الحياة
/// Query to get user lifetime statistics
/// </summary>
public class GetUserLifetimeStatsQuery : IRequest<ResultDto<UserLifetimeStatsDto>>
{
    /// <summary>
    /// معرف المستخدم
    /// User identifier
    /// </summary>
    public Guid UserId { get; set; }

    public GetUserLifetimeStatsQuery(Guid userId)
    {
        UserId = userId;
    }
} 