using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using System;
using System.Collections.Generic;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;

namespace YemenBooking.Application.Features.Properties.Queries.SearchProperties;

/// <summary>
/// استعلام البحث عن العقارات
/// Query to search for properties
/// </summary>
public class SearchPropertiesQuery : IRequest<ResultDto<SearchPropertiesResponse>>
{
    /// <summary>
    /// كلمة البحث
    /// </summary>
    public string? SearchTerm { get; set; }
    
    /// <summary>
    /// المدينة
    /// </summary>
    public string? City { get; set; }
    
    /// <summary>
    /// تاريخ الوصول
    /// </summary>
    public DateTime? CheckIn { get; set; }
    
    /// <summary>
    /// تاريخ المغادرة
    /// </summary>
    public DateTime? CheckOut { get; set; }
    
    /// <summary>
    /// عدد الضيوف
    /// </summary>
    public int? GuestsCount { get; set; }
    
    /// <summary>
    /// نوع الكيان (فندق، شاليه، إلخ)
    /// </summary>
    public Guid? PropertyTypeId { get; set; }
    
    /// <summary>
    /// السعر الأدنى
    /// </summary>
    public decimal? MinPrice { get; set; }
    
    /// <summary>
    /// السعر الأقصى
    /// </summary>
    public decimal? MaxPrice { get; set; }
    
    /// <summary>
    /// تصنيف النجوم الأدنى
    /// </summary>
    public int? MinStarRating { get; set; }
    
    /// <summary>
    /// وسائل الراحة المطلوبة
    /// </summary>
    public List<Guid> RequiredAmenities { get; set; } = new();

    /// <summary>
    /// معرف نوع الوحدة المطلوب (اختياري)
    /// Required unit type ID (optional)
    /// </summary>
    public Guid? UnitTypeId { get; set; }

    /// <summary>
    /// معرفات الخدمات المطلوبة (اختياري)
    /// Required service IDs (optional)
    /// </summary>
    public List<Guid> ServiceIds { get; set; } = new();
   
    /// <summary>
    /// فلاتر الحقول الديناميكية (مفتاح-قيمة)
    /// Dynamic field filters
    /// </summary>
    public Dictionary<string, object> DynamicFieldFilters { get; set; } = new();
    
    /// <summary>
    /// خط العرض (للبحث بالموقع)
    /// </summary>
    public decimal? Latitude { get; set; }
    
    /// <summary>
    /// خط الطول (للبحث بالموقع)
    /// </summary>
    public decimal? Longitude { get; set; }
    
    /// <summary>
    /// نصف قطر البحث بالكيلومتر
    /// </summary>
    public double? RadiusKm { get; set; }
    
    /// <summary>
    /// ترتيب النتائج
    /// </summary>
    public string? SortBy { get; set; } // price_asc, price_desc, rating, distance
    
    /// <summary>
    /// رقم الصفحة
    /// </summary>
    public int PageNumber { get; set; } = 1;
    
    /// <summary>
    /// حجم الصفحة
    /// </summary>
    public int PageSize { get; set; } = 20;

    /// <summary>
    /// العملة المفضلة لعرض الأسعار
    /// Preferred currency to present prices
    /// </summary>
    public string? PreferredCurrency { get; set; }
}