namespace YemenBooking.Core.Entities;

using System;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Enums;

/// <summary>
/// كيان الدفع
/// Payment entity
/// </summary>
[Display(Name = "كيان الدفع")]
public class Payment : BaseEntity<Guid>
{
    /// <summary>
    /// معرف الحجز
    /// Booking identifier
    /// </summary>
    [Display(Name = "معرف الحجز")]
    public Guid BookingId { get; set; }
    
    /// <summary>
    /// المبلغ المدفوع
    /// Paid amount
    /// </summary>
    [Display(Name = "المبلغ المدفوع")]
    public Money Amount { get; set; }

    /// <summary>
    /// طريقة الدفع (بطاقة، نقدي، محفظة)
    /// Payment method (Card, Cash, Wallet)
    /// </summary>
    [Display(Name = "طريقة الدفع")]
    public PaymentMethodEnum PaymentMethod { get; set; }
    
    /// <summary>
    /// معرف المعاملة
    /// Transaction identifier
    /// </summary>
    [Display(Name = "معرف المعاملة")]
    public string TransactionId { get; set; }
    
    /// <summary>
    /// حالة الدفع (ناجح، فاشل، معلّق)
    /// Payment status (Successful, Failed, Pending)
    /// </summary>
    [Display(Name = "حالة الدفع")]
    public PaymentStatus Status { get; set; }
    
    /// <summary>
    /// تاريخ الدفع
    /// Payment date
    /// </summary>
    [Display(Name = "تاريخ الدفع")]
    public DateTime PaymentDate { get; set; }
    
    /// <summary>
    /// معرف المعاملة في بوابة الدفع
    /// Gateway transaction identifier
    /// </summary>
    [Display(Name = "معرف المعاملة في بوابة الدفع")]
    public string GatewayTransactionId { get; set; } = string.Empty;

    /// <summary>
    /// معرف المستخدم الذي قام بمعالجة الدفع
    /// User ID who processed the payment
    /// </summary>
    [Display(Name = "معرف المستخدم الذي قام بمعالجة الدفع")]
    public Guid ProcessedBy { get; set; }

    /// <summary>
    /// تاريخ معالجة الدفع (توافق نقاط نهاية الموبايل)
    /// Payment processed date
    /// </summary>
    public DateTime? ProcessedAt { get; set; }
    
    /// <summary>
    /// الحجز المرتبط بالدفع
    /// Booking associated with the payment
    /// </summary>
    [Display(Name = "الحجز المرتبط بالدفع")]
    public virtual Booking Booking { get; set; }
} 