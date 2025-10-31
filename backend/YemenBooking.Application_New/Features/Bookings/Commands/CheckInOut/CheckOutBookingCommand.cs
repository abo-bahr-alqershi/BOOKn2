using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Bookings.Commands.CheckInOut;

/// <summary>
/// أمر لتسجيل المغادرة لحجز
/// Command to check-out a booking
/// </summary>
public class CheckOutBookingCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }
}

