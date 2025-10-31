using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetPropertyTypes;

/// <summary>
/// استعلام الحصول على جميع أنواع الكيانات المتاحة
/// Query to get all available property types
/// </summary>
public class GetPropertyTypesQuery : IRequest<ResultDto<List<PropertyTypeDto>>>
{
    // لا توجد معلمات خاصة بهذا الاستعلام
}