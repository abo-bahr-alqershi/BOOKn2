using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Payments.Commands.VoidPayment;

/// <summary>
/// أمر لإبطال الدفعة
/// Command to void a payment
/// </summary>
public class VoidPaymentCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الدفعة
    /// Payment identifier
    /// </summary>
    public Guid PaymentId { get; set; }
}