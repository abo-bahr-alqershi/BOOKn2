using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Services.DTOs;
using System;

namespace YemenBooking.Application.Features.Services.Queries.GetPropertyServices;

/// <summary>
/// استعلام للحصول على خدمات الكيان
/// Query to get property services
/// </summary>
public class GetPropertyServicesQuery : IRequest<ResultDto<IEnumerable<ServiceDto>>>
{
    /// <summary>
    /// معرف الكيان
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }
} 