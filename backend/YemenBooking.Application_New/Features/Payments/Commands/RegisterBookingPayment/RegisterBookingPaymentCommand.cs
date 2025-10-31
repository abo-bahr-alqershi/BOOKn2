using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Payments.DTOs;

namespace YemenBooking.Application.Features.Payments.Commands.RegisterBookingPayment;

/// <summary>
/// أمر تسجيل دفعة للحجز
/// Command to register a payment for booking
/// </summary>
public class RegisterBookingPaymentCommand : IRequest<ResultDto<PaymentDto>>
{
    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }

    /// <summary>
    /// المبلغ المدفوع
    /// Amount paid
    /// </summary>
    public MoneyDto Amount { get; set; }

    /// <summary>
    /// طريقة الدفع
    /// Payment method
    /// </summary>
    public PaymentMethodEnum PaymentMethod { get; set; }

    /// <summary>
    /// معرف المعاملة (اختياري)
    /// Transaction ID (optional)
    /// </summary>
    public string TransactionId { get; set; } = string.Empty;

    /// <summary>
    /// ملاحظات الدفع
    /// Payment notes
    /// </summary>
    public string Notes { get; set; } = string.Empty;

    /// <summary>
    /// التاريخ والوقت للدفع (اختياري - إذا كان فارغاً سيستخدم التوقيت الحالي)
    /// Payment date and time (optional - if empty will use current time)
    /// </summary>
    public DateTime? PaymentDate { get; set; }
}
