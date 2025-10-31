using MediatR;
using YemenBooking.Application.Common.Models;
using System;
using System.Collections.Generic;
using YemenBooking.Application.Features.Bookings.DTOs;

namespace YemenBooking.Application.Features.Bookings.Queries.GetBookingsByProperty;

/// <summary>
/// استعلام للحصول على حجوزات الكيان
/// Query to get bookings by property
/// </summary>
public class GetBookingsByPropertyQuery : IRequest<PaginatedResult<BookingDto>>
{
    /// <summary>
    /// معرف الكيان
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }

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

    /// <summary>
    /// معرف المستخدم للفلترة (اختياري)
    /// User identifier for filtering (optional)
    /// </summary>
    public Guid? UserId { get; set; }

    /// <summary>
    /// نوع الكيان للفلترة (اختياري)
    /// Property type for filtering (optional)
    /// </summary>
    public Guid? PropertyTypeId { get; set; }

    /// <summary>
    /// قائمة المرافق للفلترة (اختياري)
    /// List of required amenity IDs (optional)
    /// </summary>
    public List<Guid>? AmenityIds { get; set; }

    /// <summary>
    /// حالة الحجز للفلترة (اختياري)
    /// BookingDto status filter (optional)
    /// </summary>
    public string? Status { get; set; }

    /// <summary>
    /// حالة الدفع للفلترة (اختياري)
    /// Payment status filter (optional)
    /// </summary>
    public string? PaymentStatusDto { get; set; }

    /// <summary>
    /// بحث باسم الضيف أو البريد الإلكتروني (اختياري)
    /// Guest name or email search (optional)
    /// </summary>
    public string? GuestNameOrEmail { get; set; }

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