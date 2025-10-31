namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

/// <summary>
/// كيان الإتاحة للوحدة
/// Unit availability entity
/// </summary>
[Display(Name = "كيان إتاحة الوحدة")]
public class UnitAvailability : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الوحدة
    /// Unit identifier
    /// </summary>
    [Display(Name = "معرف الوحدة")]
    public Guid UnitId { get; set; }
    public virtual Unit Unit { get; set; }

    /// <summary>
    /// تاريخ ووقت البداية
    /// Start date and time
    /// </summary>
    [Display(Name = "تاريخ ووقت البداية")]
    public DateTime StartDate { get; set; }

    /// <summary>
    /// تاريخ ووقت النهاية
    /// End date and time
    /// </summary>
    [Display(Name = "تاريخ ووقت النهاية")]
    public DateTime EndDate { get; set; }

    /// <summary>
    /// حالة الإتاحة
    /// Availability status
    /// </summary>
    [Display(Name = "حالة الإتاحة")]
    public string Status { get; set; } = null!;

    /// <summary>
    /// سبب عدم الإتاحة
    /// Unavailability reason
    /// </summary>
    [Display(Name = "سبب عدم الإتاحة")]
    public string? Reason { get; set; }

    /// <summary>
    /// ملاحظات
    /// Notes
    /// </summary>
    [Display(Name = "ملاحظات")]
    public string? Notes { get; set; }

    /// <summary>
    /// معرف الحجز المرتبط بالتجاوز (اختياري)
    /// Booking identifier for related block
    /// </summary>
    public Guid? BookingId { get; set; }

    /// <summary>
    /// الكيان الحجز المرتبط بهذا التجاوز
    /// Navigation to booking entity
    /// </summary>
    public virtual Booking? Booking { get; set; }
} 