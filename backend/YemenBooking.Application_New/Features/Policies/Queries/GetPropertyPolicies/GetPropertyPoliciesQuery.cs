using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Policies.Queries.GetPropertyPolicies;

/// <summary>
/// استعلام للحصول على سياسات الكيان
/// Query to get property policies
/// </summary>
public class GetPropertyPoliciesQuery : IRequest<ResultDto<IEnumerable<PolicyDto>>>
{
    /// <summary>
    /// معرف الكيان
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }
}