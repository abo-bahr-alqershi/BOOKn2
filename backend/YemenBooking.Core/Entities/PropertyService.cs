namespace YemenBooking.Core.Entities;

using System;
using YemenBooking.Core.ValueObjects;
using System.Collections.Generic;
using YemenBooking.Core.Enums;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان خدمة الكيان
/// Property Service entity
/// </summary>
[Display(Name = "كيان خدمة الكيان")]
public class PropertyService : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    [Display(Name = "معرف الكيان")]
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// اسم الخدمة (نقل من المطار، سبا، غسيل ملابس)
    /// Service name (Airport Transfer, Spa, Laundry)
    /// </summary>
    [Display(Name = "اسم الخدمة")]
    public string Name { get; set; }
    
    /// <summary>
    /// سعر الخدمة
    /// Service price
    /// </summary>
    [Display(Name = "سعر الخدمة")]
    public Money Price { get; set; }
    
    /// <summary>
    /// وصف الخدمة
    /// Service description
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// أيقونة الخدمة
    /// Service icon
    /// </summary>
    public string Icon { get; set; } = string.Empty;

    /// <summary>
    /// نموذج التسعير (ثابت، للشخص، للليلة)
    /// Pricing model (Fixed, Per Person, Per Night)
    /// </summary>
    [Display(Name = "نموذج التسعير")]
    public PricingModel PricingModel { get; set; }
    
    /// <summary>
    /// الكيان المرتبط بالخدمة
    /// Property associated with the service
    /// </summary>
    [Display(Name = "الكيان المرتبط بالخدمة")]
    public virtual Property Property { get; set; }
    
    /// <summary>
    /// الحجوزات المرتبطة بهذه الخدمة
    /// Bookings associated with this service
    /// </summary>
    [Display(Name = "الحجوزات المرتبطة بهذه الخدمة")]
    public virtual ICollection<BookingService> BookingServices { get; set; } = new List<BookingService>();
} 