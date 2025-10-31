using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Payments.Commands.RefundPayment;

/// <summary>
/// أمر لاسترداد الدفع
/// Command to refund a payment
/// </summary>
public class RefundPaymentCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الدفع
    /// Payment ID
    /// </summary>
    public Guid PaymentId { get; set; }

    /// <summary>
    /// المبلغ المسترد
    /// Refund amount
    /// </summary>
    public MoneyDto RefundAmount { get; set; }
    /// <summary>
    /// سبب الاسترداد
    /// Refund reason
    /// </summary>
    public string RefundReason { get; set; }
} 