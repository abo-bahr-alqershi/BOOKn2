using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.PropertyTypes.DTOs;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetPropertyTypesWithUnits
{
    /// <summary>
    /// استعلام لإرجاع أنواع العقارات مع أنواع الوحدات التابعة لكل نوع
    /// Query to get property types with their unit types
    /// </summary>
    public class GetPropertyTypesWithUnitsQuery : IRequest<ResultDto<List<PropertyTypeWithUnitsDto>>>
    {
    }
}
