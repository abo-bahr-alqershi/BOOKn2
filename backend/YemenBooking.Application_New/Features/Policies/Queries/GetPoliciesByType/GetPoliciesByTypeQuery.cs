using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Policies.Queries.GetPoliciesByType
{
    /// <summary>
    /// استعلام للحصول على السياسات حسب النوع
    /// Query to get policies by type
    /// </summary>
    public class GetPoliciesByTypeQuery : IRequest<PaginatedResult<PolicyDto>>
    {
        /// <summary>
        /// نوع السياسة
        /// </summary>
        public PolicyType PolicyType { get; set; }

        /// <summary>
        /// رقم الصفحة
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة
        /// </summary>
        public int PageSize { get; set; } = 10;
    }
} 