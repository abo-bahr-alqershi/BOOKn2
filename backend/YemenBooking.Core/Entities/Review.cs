namespace YemenBooking.Core.Entities;

using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

/// <summary>
/// كيان المراجعة
/// Review entity
/// </summary>
[Display(Name = "كيان المراجعة")]
public class Review : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الحجز
    /// Booking identifier
    /// </summary>
    [Display(Name = "معرف الحجز")]
    public Guid BookingId { get; set; }

    /// <summary>
    /// معرف الكيان
    /// Property identifier
    /// </summary>
    [Display(Name = "معرف الكيان")]
    public Guid PropertyId { get; set; }
    
    /// <summary>
    /// تقييم النظافة
    /// Cleanliness rating
    /// </summary>
    [Display(Name = "تقييم النظافة")]
    public int Cleanliness { get; set; }
    
    /// <summary>
    /// تقييم الخدمة
    /// Service rating
    /// </summary>
    [Display(Name = "تقييم الخدمة")]
    public int Service { get; set; }
    
    /// <summary>
    /// تقييم الموقع
    /// Location rating
    /// </summary>
    [Display(Name = "تقييم الموقع")]
    public int Location { get; set; }
    
    /// <summary>
    /// تقييم القيمة
    /// Value rating
    /// </summary>
    [Display(Name = "تقييم القيمة")]
    public int Value { get; set; }

    /// <summary>
    /// متوسط التقييم
    /// Average rating
    /// </summary>
    [Display(Name = "متوسط التقييم")]
    public decimal AverageRating { get; set; }
    
    /// <summary>
    /// تعليق المراجعة
    /// Review comment
    /// </summary>
    [Display(Name = "تعليق المراجعة")]
    public string Comment { get; set; }
    
    /// <summary>
    /// تاريخ إنشاء المراجعة
    /// Review creation date
    /// </summary>
    [Display(Name = "تاريخ إنشاء المراجعة")]
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// نص رد المراجعة
    /// Review response text
    /// </summary>
    [Display(Name = "نص رد المراجعة")]
    public string? ResponseText { get; set; }

    /// <summary>
    /// تاريخ رد المراجعة
    /// Review response date
    /// </summary>
    [Display(Name = "تاريخ رد المراجعة")]
    public DateTime? ResponseDate { get; set; }

    /// <summary>
    /// هل الرد في انتظار الموافقة
    /// Is pending approval for moderation
    /// </summary>
    [Display(Name = "هل الرد في انتظار الموافقة")]
    public bool IsPendingApproval { get; set; } = true;
    
    /// <summary>
    /// الحجز المرتبط بالمراجعة
    /// Booking associated with the review
    /// </summary>
    [Display(Name = "الحجز المرتبط بالمراجعة")]
    public virtual Booking Booking { get; set; }
    
    /// <summary>
    /// الكيان المرتبط بالمراجعة
    /// Property associated with the review
    /// </summary>
    [Display(Name = "الكيان المرتبط بالمراجعة")]
    public virtual Property Property { get; set; }

    /// <summary>
    /// صور المراجعة المرتبطة
    /// Review images associated with the review
    /// </summary>
    [Display(Name = "صور المراجعة المرتبطة")]
    public virtual ICollection<ReviewImage> Images { get; set; } = new List<ReviewImage>();

    /// <summary>
    /// الردود على التقييم
    /// Responses associated with the review
    /// </summary>
    [Display(Name = "ردود التقييم")]
    public virtual ICollection<ReviewResponse> Responses { get; set; } = new List<ReviewResponse>();
} 