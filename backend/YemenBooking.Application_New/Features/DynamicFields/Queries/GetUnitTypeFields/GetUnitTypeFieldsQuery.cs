using YemenBooking.Application.Features;
namespace YemenBooking.Application.Features.DynamicFields.Queries.GetUnitTypeFields;
using YemenBooking.Application.Features.Units.DTOs;

using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;

/// <summary>
/// Get dynamic fields for unit type
/// </summary>
public class GetUnitTypeFieldsQuery : IRequest<List<UnitTypeFieldDto>>
{
    /// <summary>
    /// معرف نوع الوحدة
    /// UnitTypeId
    /// </summary>
    public string unitTypeId { get; set; }

    /// <summary>
    /// حالة التفعيل (اختياري)
    /// IsActive
    /// </summary>
    public bool? IsActive { get; set; }

    /// <summary>
    /// يظهر في البحث فقط (اختياري)
    /// IsSearchable
    /// </summary>
    public bool? IsSearchable { get; set; }

    /// <summary>
    /// عام فقط (اختياري)
    /// IsPublic
    /// </summary>
    public bool? IsPublic { get; set; }

    /// <summary>
    /// يحدد ما إذا كان الحقل مخصص للوحدات للتصفية (اختياري)
    /// Filter for unit-specific fields
    /// </summary>
    public bool? IsForUnits { get; set; }

    /// <summary>
    /// فئة الحقل (اختياري)
    /// Category
    /// </summary>
    public string? Category { get; set; }
    /// <summary>
    /// نص البحث في الحقول (اختياري)
    /// SearchTerm
    /// </summary>
    public string? SearchTerm { get; set; }
} 