using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Bookings.DTOs;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByUser;

/// <summary>
/// استعلام للحصول على حجوزات المستخدم
/// Query to get user bookings
/// </summary>
public class GetBookingsByUserQuery : IRequest<PaginatedResult<BookingDto>>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

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
    /// حالة الحجز (اختياري)
    /// BookingDto status (optional)
    /// </summary>
    public string? Status { get; set; }

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