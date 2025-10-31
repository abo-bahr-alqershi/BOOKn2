using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings;
using System;
using YemenBooking.Application.Features.Bookings.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingById;

/// <summary>
/// استعلام للحصول على بيانات الحجز بواسطة المعرف
/// Query to get booking details by ID
/// </summary>
public class GetBookingByIdQuery : IRequest<ResultDto<BookingDetailsDto>>
{
    /// <summary>
    /// معرف الحجز
    /// BookingDto ID
    /// </summary>
    public Guid BookingId { get; set; }
} 