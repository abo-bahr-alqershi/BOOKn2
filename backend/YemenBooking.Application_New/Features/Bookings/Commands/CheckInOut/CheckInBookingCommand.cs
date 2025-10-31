using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Bookings.Commands.CheckInOut;

/// <summary>
/// أمر لتسجيل الوصول لحجز
/// Command to check-in a booking
/// </summary>
public class CheckInBookingCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }
}

