using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings.DTOs;
using System;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByUnit;

/// <summary>
/// استعلام للحصول على حجوزات الوحدة
/// Query to get bookings by unit
/// </summary>
public class GetBookingsByUnitQuery : IRequest<PaginatedResult<BookingDto>>
{
    /// <summary>
    /// معرف الوحدة
    /// Unit ID
    /// </summary>
    public Guid UnitId { get; set; }

    /// <summary>
    /// تاريخ البداية (اختياري)
    /// Start date (optional)
    /// </summary>
    public DateTime? StartDate { get; set; }

    /// <summary>
    /// تاريخ النهاية (اختياري)
    /// End date (optional)
    /// </summary>
    public DateTime? EndDate { get; set; }

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