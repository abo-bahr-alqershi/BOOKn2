namespace YemenBooking.Application.Features.Properties.DTOs;

using System;
using System.Collections.Generic;

/// <summary>
/// بيانات نوع العقار
/// Property type data transfer object
/// </summary>
public class PropertyTypeDto
{
    /// <summary>
    /// معرف نوع العقار
    /// Property type ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// اسم نوع العقار (فندق، شاليه، استراحة، فيلا، شقة)
    /// Property type name (hotel, chalet, resort, villa, apartment)
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// وصف نوع العقار
    /// Property type description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// عدد العقارات من هذا النوع
    /// Number of properties of this type
    /// </summary>
    public int PropertiesCount { get; set; }

    /// <summary>
    /// وسائل الراحة الافتراضية لهذا النوع من العقارات
    /// Default amenities for this property type
    /// </summary>
    public List<string> DefaultAmenities { get; set; } = new();

    /// <summary>
    /// معرفات أنواع الوحدات التابعة لهذا النوع من العقارات
    /// Unit type identifiers belonging to this property type
    /// </summary>
    public List<Guid> UnitTypeIds { get; set; } = new();

    /// <summary>
    /// ايقونة لنوع العقار
    /// Icon for the property type
    /// </summary>
    public string Icon { get; set; } = string.Empty;

}
