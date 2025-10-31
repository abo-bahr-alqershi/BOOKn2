using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Amenities.Queries.GetAllAmenities;

/// <summary>
/// استعلام الحصول على جميع وسائل الراحة
/// Query to get all amenities
/// </summary>
public class GetAllAmenitiesQuery : IRequest<ResultDto<List<AmenityDto>>>
{
    /// <summary>
    /// فلترة حسب الفئة (اختياري)
    /// </summary>
    public string? Category { get; set; }
}