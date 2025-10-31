namespace YemenBooking.Core.Entities;

using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان المدينة
/// City entity
/// </summary>
[Display(Name = "كيان المدينة")]
public class City
{
    /// <summary>
    /// الاسم الفريد للمدينة (مفتاح أساسي نصي)
    /// City name (string primary key)
    /// </summary>
    [Key]
    public string Name { get; set; }

    /// <summary>
    /// الدولة
    /// Country name
    /// </summary>
    public string Country { get; set; }

    /// <summary>
    /// روابط الصور كـ JSON مخزن
    /// Image URLs as JSON string for simplicity
    /// </summary>
    public string ImagesJson { get; set; } = "[]";

    /// <summary>
    /// العقارات داخل هذه المدينة (ملاحة عكسية)
    /// Properties located in this city (reverse navigation)
    /// </summary>
    public virtual ICollection<Property> Properties { get; set; } = new List<Property>();

    /// <summary>
    /// الصور المرتبطة بالمدينة عبر جدول الصور الموحد
    /// Images associated with this city via shared images table
    /// </summary>
    public virtual ICollection<PropertyImage> Images { get; set; } = new List<PropertyImage>();
}

