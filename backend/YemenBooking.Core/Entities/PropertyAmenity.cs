namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.ValueObjects;

/// <summary>
/// كيان وسيلة الكيان
/// Property Amenity entity
/// </summary>
[Display(Name = "كيان وسيلة الكيان")]
public class PropertyAmenity : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    [Display(Name = "معرف الكيان")]
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// معرف وسيلة نوع الكيان
    /// Property type amenity identifier
    /// </summary>
    [Display(Name = "معرف وسيلة نوع الكيان")]
    public Guid PtaId { get; set; }
    
    /// <summary>
    /// هل الوسيلة متاحة
    /// Is amenity available
    /// </summary>
    [Display(Name = "هل الوسيلة متاحة")]
    public bool IsAvailable { get; set; }
    
    /// <summary>
    /// التكلفة الإضافية للوسيلة
    /// Extra cost for the amenity
    /// </summary>
    [Display(Name = "التكلفة الإضافية للوسيلة")]
    public Money ExtraCost { get; set; }
    
    /// <summary>
    /// الكيان المرتبط
    /// Property associated
    /// </summary>
    [Display(Name = "الكيان المرتبط")]
    public virtual Property Property { get; set; }
    
    /// <summary>
    /// وسيلة نوع الكيان المرتبطة
    /// Property type amenity associated
    /// </summary>
    [Display(Name = "وسيلة نوع الكيان المرتبطة")]
    public virtual PropertyTypeAmenity PropertyTypeAmenity { get; set; }
} 