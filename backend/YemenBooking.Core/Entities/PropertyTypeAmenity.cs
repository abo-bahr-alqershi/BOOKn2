namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان وسيلة نوع الكيان
/// Property Type Amenity entity
/// </summary>
[Display(Name = "كيان وسيلة نوع الكيان")]
public class PropertyTypeAmenity : BaseEntity<Guid>
{
    /// <summary>
    /// معرف نوع الكيان
    /// Property type identifier
    /// </summary>
    [Display(Name = "معرف نوع الكيان")]
    public Guid PropertyTypeId { get; set; }
    
    /// <summary>
    /// معرف الوسيلة
    /// Amenity identifier
    /// </summary>
    [Display(Name = "معرف الوسيلة")]
    public Guid AmenityId { get; set; }
    
    /// <summary>
    /// هل هي وسيلة افتراضية
    /// Is default amenity
    /// </summary>
    [Display(Name = "هل هي وسيلة افتراضية")]
    public bool IsDefault { get; set; }
    
    /// <summary>
    /// نوع الكيان المرتبط
    /// Property type associated
    /// </summary>
    [Display(Name = "نوع الكيان المرتبط")]
    public virtual PropertyType PropertyType { get; set; }
    
    /// <summary>
    /// الوسيلة المرتبطة
    /// Amenity associated
    /// </summary>
    [Display(Name = "الوسيلة المرتبطة")]
    public virtual Amenity Amenity { get; set; }
    
    /// <summary>
    /// وسائل الكيان المرتبطة
    /// Property amenities associated
    /// </summary>
    [Display(Name = "وسائل الكيان المرتبطة")]
    public virtual ICollection<PropertyAmenity> PropertyAmenities { get; set; } = new List<PropertyAmenity>();
} 