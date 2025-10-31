namespace YemenBooking.Core.Entities;

using System;
using YemenBooking.Core.ValueObjects;
using System.Collections.Generic;
using YemenBooking.Core.Enums;
using System.ComponentModel.DataAnnotations;

/// <summary>
/// كيان الحجز
/// Booking entity
/// </summary>
[Display(Name = "كيان الحجز")]
public class Booking : BaseEntity<Guid>
{
    /// <summary>
    /// معرف المستخدم
    /// User identifier
    /// </summary>
    [Display(Name = "معرف المستخدم")]
    public Guid UserId { get; set; }
    
    /// <summary>
    /// معرف الوحدة
    /// Unit identifier
    /// </summary>
    [Display(Name = "معرف الوحدة")]
    public Guid UnitId { get; set; }
    
    /// <summary>
    /// تاريخ الوصول
    /// Check-in date
    /// </summary>
    [Display(Name = "تاريخ الوصول")]
    public DateTime CheckIn { get; set; }
    
    /// <summary>
    /// تاريخ المغادرة
    /// Check-out date
    /// </summary>
    [Display(Name = "تاريخ المغادرة")]
    public DateTime CheckOut { get; set; }
    
    /// <summary>
    /// عدد الضيوف
    /// Number of guests
    /// </summary>
    [Display(Name = "عدد الضيوف")]
    public int GuestsCount { get; set; }
    
    /// <summary>
    /// السعر الإجمالي للحجز
    /// Total price of the booking
    /// </summary>
    [Display(Name = "السعر الإجمالي للحجز")]
    public Money TotalPrice { get; set; }
    
    /// <summary>
    /// حالة الحجز (مؤكّد، معلّق، ملغى)
    /// Booking status (Confirmed, Pending, Cancelled)
    /// </summary>
    [Display(Name = "حالة الحجز")]
    public BookingStatus Status { get; set; }
    
    /// <summary>
    /// تاريخ الحجز
    /// Booking date
    /// </summary>
    [Display(Name = "تاريخ الحجز")]
    public DateTime BookedAt { get; set; }

    /// <summary>
    /// مصدر الحجز (ويب، موبايل، حجز مباشر)
    /// Booking source (WebApp, MobileApp, WalkIn)
    /// </summary>
    [Display(Name = "مصدر الحجز")]
    public string? BookingSource { get; set; }

    /// <summary>
    /// سبب الإلغاء
    /// Cancellation reason
    /// </summary>
    [Display(Name = "سبب الإلغاء")]
    public string? CancellationReason { get; set; }

    /// <summary>
    /// هل الحجز مباشر (Walk-in)
    /// Is walk-in booking
    /// </summary>
    [Display(Name = "هل الحجز مباشر")]
    public bool IsWalkIn { get; set; } = false;
    
    /// <summary>
    /// المستخدم المرتبط بالحجز
    /// User associated with the booking
    /// </summary>
    [Display(Name = "المستخدم المرتبط بالحجز")]
    public virtual User User { get; set; }
    
    /// <summary>
    /// الوحدة المرتبطة بالحجز
    /// Unit associated with the booking
    /// </summary>
    [Display(Name = "الوحدة المرتبطة بالحجز")]
    public virtual Unit Unit { get; set; }
    
    /// <summary>
    /// المدفوعات المرتبطة بالحجز
    /// Payments associated with the booking
    /// </summary>
    [Display(Name = "المدفوعات المرتبطة بالحجز")]
    public virtual ICollection<Payment> Payments { get; set; } = new List<Payment>();
    
    /// <summary>
    /// الخدمات المرتبطة بالحجز
    /// Services associated with the booking
    /// </summary>
    [Display(Name = "الخدمات المرتبطة بالحجز")]
    public virtual ICollection<BookingService> BookingServices { get; set; } = new List<BookingService>();
    
    /// <summary>
    /// المراجعات المرتبطة بالحجز
    /// Reviews associated with the booking
    /// </summary>
    [Display(Name = "المراجعات المرتبطة بالحجز")]
    public virtual ICollection<Review> Reviews { get; set; } = new List<Review>();

    /// <summary>
    /// التجاوزات المتعلقة بالحجز
    /// Availability blocks related to this booking
    /// </summary>
    public virtual ICollection<UnitAvailability> Availabilities { get; set; } = new List<UnitAvailability>();

    /// <summary>
    /// مبلغ عمولة المنصة
    /// Platform commission amount
    /// </summary>
    [Display(Name = "مبلغ عمولة المنصة")]
    public decimal PlatformCommissionAmount { get; set; }

    /// <summary>
    /// تاريخ تسجيل الوصول الفعلي
    /// Actual check-in date
    /// </summary>
    [Display(Name = "تاريخ تسجيل الوصول الفعلي")]
    public DateTime? ActualCheckInDate { get; set; }

    /// <summary>
    /// تاريخ المغادرة الفعلي
    /// Actual check-out date
    /// </summary>
    [Display(Name = "تاريخ المغادرة الفعلي")]
    public DateTime? ActualCheckOutDate { get; set; }

    /// <summary>
    /// المبلغ النهائي المدفوع
    /// Final amount
    /// </summary>
    [Display(Name = "المبلغ النهائي المدفوع")]
    public decimal FinalAmount { get; set; }

    /// <summary>
    /// تقييم العميل
    /// Customer rating
    /// </summary>
    [Display(Name = "تقييم العميل")]
    public decimal? CustomerRating { get; set; }

    /// <summary>
    /// ملاحظات إكمال الحجز
    /// Completion notes
    /// </summary>
    [Display(Name = "ملاحظات إكمال الحجز")]
    public string? CompletionNotes { get; set; }

    /// <summary>
    /// لقطة سياسات العقار وقت إنشاء الحجز (JSON)
    /// Property policy snapshot at booking time (JSON)
    /// </summary>
    [Display(Name = "لقطة سياسات العقار وقت إنشاء الحجز (JSON)")]
    public string? PolicySnapshot { get; set; }

    /// <summary>
    /// تاريخ حفظ لقطة السياسات
    /// When the policy snapshot was captured
    /// </summary>
    [Display(Name = "تاريخ حفظ لقطة السياسات")]
    public DateTime? PolicySnapshotAt { get; set; }
}