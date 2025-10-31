using YemenBooking.Application.Features;
namespace YemenBooking.Application.Features.DynamicFields.Queries.GetFieldGroupsByUnitType;
using YemenBooking.Application.Features.DynamicFields.DTOs;

using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;

/// <summary>
/// جلب مجموعات الحقول لنوع وحدة معين
/// Get field groups by unit type
/// </summary>
public class GetFieldGroupsByUnitTypeQuery : IRequest<List<FieldGroupDto>>
{
    /// <summary>
    /// معرف نوع الوحدة
    /// UnitTypeId
    /// </summary>
    public string UnitTypeId { get; set; }
} 