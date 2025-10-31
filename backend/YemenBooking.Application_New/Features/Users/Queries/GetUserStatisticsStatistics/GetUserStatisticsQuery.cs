using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetUserStatisticsStatistics;

/// <summary>
/// استعلام الحصول على إحصائيات المستخدم
/// Query to get user statistics
/// </summary>
public class GetUserStatisticsQuery : IRequest<ResultDto<UserStatisticsDto>>
{
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
}