using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Services.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingServices;

/// <summary>
/// استعلام للحصول على خدمات الحجز
/// Query to get booking services
/// </summary>
public class GetBookingServicesQuery : IRequest<ResultDto<IEnumerable<ServiceDto>>>
{
    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }
} 