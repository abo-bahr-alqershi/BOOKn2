using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units.DTOs;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetUnitTypes;

/// <summary>
/// استعلام الحصول على أنواع الوحدات المتاحة
/// Query to get available unit types
/// </summary>
public class GetUnitTypesQuery : IRequest<ResultDto<List<UnitTypeDto>>>
{
    /// <summary>
    /// معرف نوع الكيان
    /// </summary>
    public Guid PropertyTypeId { get; set; }
}