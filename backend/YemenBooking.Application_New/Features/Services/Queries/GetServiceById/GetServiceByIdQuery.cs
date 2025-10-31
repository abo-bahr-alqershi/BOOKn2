using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Services.DTOs;
using System;

namespace YemenBooking.Application.Features.Services.Queries.GetServiceById;

/// <summary>
/// استعلام للحصول على بيانات الخدمة بواسطة المعرف
/// Query to get service details by ID
/// </summary>
public class GetServiceByIdQuery : IRequest<ResultDto<ServiceDetailsDto>>
{
    /// <summary>
    /// معرف الخدمة
    /// Service ID
    /// </summary>
    public Guid ServiceId { get; set; }
} 