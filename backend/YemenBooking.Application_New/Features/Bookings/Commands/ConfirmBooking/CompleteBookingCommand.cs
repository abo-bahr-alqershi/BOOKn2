using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Bookings.Commands.ConfirmBooking;

/// <summary>
/// أمر لإكمال الحجز (إقفال الحالة بعد CheckOut)
/// Command to complete a booking
/// </summary>
public class CompleteBookingCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }
}

