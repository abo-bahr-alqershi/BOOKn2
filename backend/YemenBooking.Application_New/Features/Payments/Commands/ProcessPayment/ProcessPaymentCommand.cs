using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Payments.DTOs;
using YemenBooking.Core.Enums;
using YemenBooking.Core.ValueObjects;
using System;

namespace YemenBooking.Application.Features.Payments.Commands.ProcessPayment
{
    /// <summary>
    /// أمر معالجة الدفع
    /// Command to process payment
    /// </summary>
    public class ProcessPaymentCommand : IRequest<ResultDto<ProcessPaymentResponse>>
{
    /// <summary>
    /// معرف الحجز
    /// </summary>
    public Guid BookingId { get; set; }
    
    /// <summary>
    /// المبلغ المدفوع
    /// </summary>
    public Money Amount { get; set; } = null!;
    
    /// <summary>
    /// طريقة الدفع
    /// </summary>
    public PaymentMethodEnum PaymentMethod { get; set; }
    
    /// <summary>
    /// تفاصيل بطاقة الائتمان (إن كانت الطريقة بطاقة)
    /// </summary>
    public CardDetails? CardDetails { get; set; }
    
    /// <summary>
    /// معرف المحفظة الإلكترونية (إن كانت الطريقة محفظة)
    /// </summary>
    public string? WalletId { get; set; }
}

/// <summary>
/// تفاصيل البطاقة الائتمانية
/// </summary>
public class CardDetails
{
    /// <summary>
    /// رقم البطاقة
    /// </summary>
    public string CardNumber { get; set; } = string.Empty;
    
    /// <summary>
    /// اسم حامل البطاقة
    /// </summary>
    public string CardholderName { get; set; } = string.Empty;
    
    /// <summary>
    /// شهر انتهاء الصلاحية
    /// </summary>
    public int ExpiryMonth { get; set; }
    
    /// <summary>
    /// سنة انتهاء الصلاحية
    /// </summary>
    public int ExpiryYear { get; set; }
    
    /// <summary>
    /// رمز الأمان CVV
    /// </summary>
    public string CVV { get; set; } = string.Empty;
    }
}
