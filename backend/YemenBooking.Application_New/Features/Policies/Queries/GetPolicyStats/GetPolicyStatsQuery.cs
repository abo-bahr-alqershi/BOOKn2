using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;
using System;

namespace YemenBooking.Application.Features.Policies.Queries.GetPolicyStats
{
    /// <summary>
    /// استعلام للحصول على إحصائيات السياسات
    /// Query to get policy statistics
    /// </summary>
    public class GetPolicyStatsQuery : IRequest<ResultDto<PolicyStatsDto>>
    {
        public Guid? PropertyId { get; set; }
    }
}
