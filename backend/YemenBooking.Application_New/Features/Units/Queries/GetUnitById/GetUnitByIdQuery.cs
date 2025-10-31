using MediatR;
using System;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.GetUnitById;

/// <summary>
/// استعلام للحصول على بيانات الوحدة بواسطة المعرف
/// Query to get unit details by ID
/// </summary>
public class GetUnitByIdQuery : IRequest<ResultDto<UnitDetailsDto>>
{
    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }

    /// <summary>
    /// تضمين القيم الديناميكية (اختياري)
    /// IncludeDynamicFields
    /// </summary>
    public bool IncludeDynamicFields { get; set; } = true;

} 