using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Policies.Queries.GetPolicyById;

/// <summary>
/// استعلام للحصول على سياسة محددة
/// Query to get specific policy
/// </summary>
public class GetPolicyByIdQuery : IRequest<ResultDto<PolicyDetailsDto>>
{
    /// <summary>
    /// معرف السياسة
    /// Policy ID
    /// </summary>
    public Guid PolicyId { get; set; }
} 