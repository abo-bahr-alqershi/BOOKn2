using MediatR;
using YemenBooking.Application.Common.Models;
using System;
using YemenBooking.Application.Features.Bookings.DTOs;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByDateRange;

/// <summary>
/// استعلام للحصول على الحجوزات في نطاق زمني
/// Query to get bookings by date range
/// </summary>
public class GetBookingsByDateRangeQuery : IRequest<PaginatedResult<BookingDto>>
{
    /// <summary>
    /// تاريخ البداية
    /// Start date
    /// </summary>
    public DateTime StartDate { get; set; }

    /// <summary>
    /// تاريخ النهاية
    /// End date
    /// </summary>
    public DateTime EndDate { get; set; }

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

    /// <summary>
    /// معرف المستخدم للفلترة (اختياري)
    /// عندما يكون نوع المستخدم مالك أو موظف في الكيان، يجب أن يكون أحد عملائهم السابقين أو الحاليين.
    /// User identifier for filtering (optional). When user type is property owner or staff, must be one of their past or current clients.
    /// </summary>
    public Guid? UserId { get; set; }

    /// <summary>
    /// بحث باسم الضيف أو البريد الإلكتروني (اختياري)
    /// Guest name or email search (optional)
    /// </summary>
    public string? GuestNameOrEmail { get; set; }

    /// <summary>
    /// فلترة بالوحدة (اختياري)
    /// Unit filter (optional)
    /// </summary>
    public Guid? UnitId { get; set; }

    /// <summary>
    /// مصدر الحجز (اختياري)
    /// BookingDto source (optional)
    /// </summary>
    public string? BookingSource { get; set; }

    /// <summary>
    /// فلترة بالحجوزات المباشرة (اختياري)
    /// Walk-in filter (optional)
    /// </summary>
    public bool? IsWalkIn { get; set; }

    /// <summary>
    /// فلترة بالسعر الأدنى (اختياري)
    /// Minimum total price filter (optional)
    /// </summary>
    public decimal? MinTotalPrice { get; set; }

    /// <summary>
    /// فلترة بعدد الضيوف (اختياري)
    /// Minimum guests count filter (optional)
    /// </summary>
    public int? MinGuestsCount { get; set; }

    /// <summary>
    /// خيارات الترتيب المتقدمة: check_in_date, booking_date, total_price (اختياري)
    /// Sort options: check_in_date, booking_date, total_price (optional)
    /// </summary>
    public string? SortBy { get; set; }
} 