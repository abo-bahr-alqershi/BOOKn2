using MediatR;
using System.Collections.Generic;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetSearchFilters;

/// <summary>
/// استعلام الحصول على فلاتر البحث المتاحة
/// Query to get available search filters
/// </summary>
public class GetSearchFiltersQuery : IRequest<ResultDto<SearchFiltersDto>>
{
    /// <summary>
    /// معرف نوع الكيان (اختياري)
    /// </summary>
    public Guid? PropertyTypeId { get; set; }
    
    /// <summary>
    /// السعر الأدنى للفلترة
    /// Minimum price for filtering
    /// </summary>
    public decimal? MinPrice { get; set; }

    /// <summary>
    /// السعر الأقصى للفلترة
    /// Maximum price for filtering
    /// </summary>
    public decimal? MaxPrice { get; set; }

    /// <summary>
    /// قائمة معرفات وسائل الراحة المطلوبة
    /// Required amenity IDs
    /// </summary>
    public List<Guid> Amenities { get; set; } = new();

    /// <summary>
    /// معرف نوع الوحدة المطلوب
    /// Required unit type id (optional)
    /// </summary>
    public Guid? UnitTypeId { get; set; }

    /// <summary>
    /// فلاتر الحقول الديناميكية (مفتاح -> قيمة)
    /// Dynamic field filters (field name -> value)
    /// </summary>
    public Dictionary<string, object> DynamicFieldFilters { get; set; } = new();

    /// <summary>
    /// قائمة معرفات الخدمات المطلوبة
    /// Required service IDs
    /// </summary>
    public List<Guid> ServiceIds { get; set; } = new();
    
    /// <summary>
    /// المدينة (اختياري لتحديد الفلاتر المتاحة بناءً على المنطقة)
    /// </summary>
    public string? City { get; set; }
}


/// <summary>
/// بيانات فلتر نوع الكيان
/// </summary>
public class PropertyTypeFilterDto
{
    /// <summary>
    /// معرف نوع الكيان
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// اسم نوع الكيان
    /// </summary>
    public string Name { get; set; } = string.Empty;
    
    /// <summary>
    /// عدد الكيانات المتاحة من هذا النوع
    /// </summary>
    public int Count { get; set; }
}

/// <summary>
/// بيانات فلتر وسيلة الراحة
/// </summary>
public class AmenityFilterDto
{
    /// <summary>
    /// معرف الوسيلة
    /// </summary>
    public Guid Id { get; set; }
    
    /// <summary>
    /// اسم الوسيلة
    /// </summary>
    public string Name { get; set; } = string.Empty;
    
    /// <summary>
    /// فئة الوسيلة
    /// </summary>
    public string Category { get; set; } = string.Empty;
    
    /// <summary>
    /// عدد الكيانات التي توفر هذه الوسيلة
    /// </summary>
    public int Count { get; set; }
}