using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Bookings.Commands.CancelBooking;

/// <summary>
/// أمر إلغاء الحجز
/// Command to cancel booking
/// </summary>
public class CancelBookingCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الحجز
    /// </summary>
    public Guid BookingId { get; set; }
    
    /// <summary>
    /// معرف المستخدم
    /// </summary>
    public Guid UserId { get; set; }
    
    /// <summary>
    /// سبب الإلغاء
    /// </summary>
    public string CancellationReason { get; set; } = string.Empty;

    /// <summary>
    /// هل يتم استرداد المدفوعات المرتبطة قبل الإلغاء
    /// Whether to refund associated successful payments before cancellation
    /// </summary>
    public bool RefundPayments { get; set; } = false;
}