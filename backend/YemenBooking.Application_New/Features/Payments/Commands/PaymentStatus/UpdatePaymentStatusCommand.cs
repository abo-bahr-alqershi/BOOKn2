using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Payments.DTOs;

namespace YemenBooking.Application.Features.Payments.Commands.PaymentStatus;

/// <summary>
/// أمر لتحديث حالة الدفع
/// Command to update payment status
/// </summary>
public class UpdatePaymentStatusCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الدفع
    /// Payment ID
    /// </summary>
    public Guid PaymentId { get; set; }

    /// <summary>
    /// الحالة الجديدة للدفع
    /// New payment status
    /// </summary>
    public YemenBooking.Core.Enums.PaymentStatus NewStatus { get; set; }

    /// <summary>
    /// سجل الاسترداد (مطلوب عند تعيين الحالة إلى مستردة)
    /// Refund record (required when setting status to refunded)
    /// </summary>
    public RefundDto? RefundRecord { get; set; }
} 