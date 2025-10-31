using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Bookings.Commands.ConfirmBooking;

/// <summary>
/// أمر لتأكيد الحجز
/// Command to confirm a booking
/// </summary>
public class ConfirmBookingCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }
} 