namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان نوع الكيان
/// Property Type entity
/// </summary>
[Display(Name = "كيان نوع الكيان")]
public class PropertyType : BaseEntity<Guid>
{
    /// <summary>
    /// اسم نوع الكيان (فندق، شاليه، استراحة، فيلا، شقة)
    /// Property type name (Hotel, Chalet, Rest House, Villa, Apartment)
    /// </summary>
    [Display(Name = "اسم نوع الكيان")]
    public string Name { get; set; }
    
    /// <summary>
    /// وصف نوع الكيان
    /// Property type description
    /// </summary>
    [Display(Name = "وصف نوع الكيان")]
    public string Description { get; set; }
    
    /// <summary>
    /// المرافق الافتراضية لنوع الكيان (JSON)
    /// Default amenities for the property type (JSON)
    /// </summary>
    [Display(Name = "المرافق الافتراضية لنوع الكيان")]
    public string DefaultAmenities { get; set; }

    /// <summary>
    /// ايقونة لنوع العقار
    /// Icon for the property type
    /// </summary>
    public string Icon { get; set; } = string.Empty;

    
    /// <summary>
    /// الكيانات المرتبطة بهذا النوع
    /// Properties associated with this type
    /// </summary>
    [Display(Name = "الكيانات المرتبطة بهذا النوع")]
    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();
    
    /// <summary>
    /// أنواع الوحدات المرتبطة بهذا النوع من الكيانات
    /// Unit types associated with this property type
    /// </summary>
    [Display(Name = "أنواع الوحدات المرتبطة بهذا النوع")]
    public virtual ICollection<UnitType> UnitTypes { get; set; } = new List<UnitType>();
    
    /// <summary>
    /// الوسائل المرتبطة بنوع الكيان
    /// Amenities associated with this property type
    /// </summary>
    [Display(Name = "الوسائل المرتبطة بنوع الكيان")]
    public virtual ICollection<PropertyTypeAmenity> PropertyTypeAmenities { get; set; } = new List<PropertyTypeAmenity>();

} 