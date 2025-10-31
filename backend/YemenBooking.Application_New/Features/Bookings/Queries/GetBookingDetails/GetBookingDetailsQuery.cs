using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings;
using System;
using YemenBooking.Application.Features.Bookings.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingDetails;

/// <summary>
/// استعلام الحصول على تفاصيل الحجز
/// Query to get booking details
/// </summary>
public class GetBookingDetailsQuery : IRequest<ResultDto<BookingDetailsDto>>
{
    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }
    
    /// <summary>
    /// معرف المستخدم (للتحقق من الصلاحية)
    /// User ID (for authorization check)
    /// </summary>
    public Guid UserId { get; set; }
}
