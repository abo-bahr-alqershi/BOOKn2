using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Policies.Queries.GetAllPolicies
{
    /// <summary>
    /// استعلام للحصول على جميع السياسات مع الصفحات
    /// Query to get all policies with pagination
    /// </summary>
    public class GetAllPoliciesQuery : IRequest<PaginatedResult<PolicyDto>>
    {
        /// <summary>
        /// رقم الصفحة
        /// Page number
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة
        /// Page size
        /// </summary>
        public int PageSize { get; set; } = 20;

        /// <summary>
        /// نص البحث
        /// Search term
        /// </summary>
        public string? SearchTerm { get; set; }

        /// <summary>
        /// معرف الكيان للفلترة
        /// Property ID for filtering
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// نوع السياسة للفلترة
        /// Policy type for filtering
        /// </summary>
        public PolicyType? PolicyType { get; set; }
    }
}
