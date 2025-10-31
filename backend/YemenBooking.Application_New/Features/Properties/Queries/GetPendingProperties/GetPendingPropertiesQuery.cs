using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.Queries.GetPendingProperties;

/// <summary>
/// استعلام للحصول على الكيانات في انتظار الموافقة
/// Query to get pending properties for approval
/// </summary>
public class GetPendingPropertiesQuery : IRequest<PaginatedResult<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>>
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
    public int PageSize { get; set; } = 10;
} 