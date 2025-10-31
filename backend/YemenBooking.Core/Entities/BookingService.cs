namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.ValueObjects;

/// <summary>
/// كيان خدمة الحجز
/// Booking Service entity
/// </summary>
[Display(Name = "كيان خدمة الحجز")]
public class BookingService : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الحجز
    /// Booking identifier
    /// </summary>
    [Display(Name = "معرف الحجز")]
    public Guid BookingId { get; set; }
    
    /// <summary>
    /// معرف الخدمة
    /// Service identifier
    /// </summary>
    [Display(Name = "معرف الخدمة")]
    public Guid ServiceId { get; set; }
    
    /// <summary>
    /// الكمية
    /// Quantity
    /// </summary>
    [Display(Name = "الكمية")]
    public int Quantity { get; set; }
    
    /// <summary>
    /// السعر الإجمالي للخدمة
    /// Total price of the service
    /// </summary>
    [Display(Name = "السعر الإجمالي للخدمة")]
    public Money TotalPrice { get; set; }
    
    /// <summary>
    /// الحجز المرتبط بخدمة الحجز
    /// Booking associated with the booking service
    /// </summary>
    [Display(Name = "الحجز المرتبط بخدمة الحجز")]
    public virtual Booking Booking { get; set; }
    
    /// <summary>
    /// الخدمة المرتبطة بخدمة الحجز
    /// Service associated with the booking service
    /// </summary>
    [Display(Name = "الخدمة المرتبطة بخدمة الحجز")]
    public virtual PropertyService Service { get; set; }
} 