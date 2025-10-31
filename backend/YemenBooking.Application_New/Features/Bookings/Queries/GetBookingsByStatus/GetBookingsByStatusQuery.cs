using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings.DTOs;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByStatus;

/// <summary>
/// استعلام للحصول على الحجوزات حسب الحالة
/// Query to get bookings by status
/// </summary>
public class GetBookingsByStatusQuery : IRequest<PaginatedResult<BookingDto>>
{
    /// <summary>
    /// حالة الحجز
    /// BookingDto status
    /// </summary>
    public string Status { get; set; } = string.Empty;

    /// <summary>
    /// رقم الصفحة
    /// Page number
    /// </summary>
    public int PageNumber { get; set; } = 1;

    /// <summary>
    /// حجم الصفحة
    /// Page size
    /// </summary>
    public int PageSize { get; set; } = 10;
} 