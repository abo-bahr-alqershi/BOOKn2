namespace YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Common.Models;

using System;
using System.Collections.Generic;

/// <summary>
/// بيانات نقل فلتر البحث
/// DTO for SearchFilter entity
/// </summary>
public class SearchFilterDto
{
    /// <summary>
    /// معرف الفلتر
    /// FilterId
    /// </summary>
    public Guid FilterId { get; set; }

    /// <summary>
    /// معرف الحقل
    /// FieldId
    /// </summary>
    public Guid FieldId { get; set; }

    /// <summary>
    /// نوع الفلتر
    /// FilterType
    /// </summary>
    public string FilterType { get; set; }

    /// <summary>
    /// الاسم المعروض
    /// DisplayName
    /// </summary>
    public string DisplayName { get; set; }

    /// <summary>
    /// خيارات الفلتر (JSON)
    /// FilterOptions
    /// </summary>
    public Dictionary<string, object> FilterOptions { get; set; }

    /// <summary>
    /// حالة التفعيل
    /// IsActive
    /// </summary>
    public bool IsActive { get; set; }

    /// <summary>
    /// ترتيب الفلتر
    /// SortOrder
    /// </summary>
    public int SortOrder { get; set; }

    /// <summary>
    /// معلومات الحقل الديناميكي المرتبط بالفلتر
    /// Field (UnitTypeFieldDto)
    /// </summary>
    public UnitTypeFieldDto Field { get; set; }
} 