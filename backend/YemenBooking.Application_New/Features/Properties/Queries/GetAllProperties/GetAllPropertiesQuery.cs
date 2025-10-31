using MediatR;
using YemenBooking.Application.Common.Models;
using System;
using System.Collections.Generic;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.Queries.GetAllProperties;

/// <summary>
/// استعلام للحصول على جميع الكيانات
/// Query to get all properties
/// </summary>
public class GetAllPropertiesQuery : IRequest<PaginatedResult<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>>
{
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
    /// مصطلح البحث (اختياري)
    /// Search term (optional)
    /// </summary>
    public string? SearchTerm { get; set; }

    /// <summary>
    /// معرف نوع الكيان (اختياري)
    /// Property type ID (optional)
    /// </summary>
    public Guid? PropertyTypeId { get; set; }

    /// <summary>
    /// الحد الأدنى للسعر (اختياري)
    /// Minimum price (optional)
    /// </summary>
    public decimal? MinPrice { get; set; }

    /// <summary>
    /// الحد الأقصى للسعر (اختياري)
    /// Maximum price (optional)
    /// </summary>
    public decimal? MaxPrice { get; set; }

    /// <summary>
    /// نوع الترتيب (اختياري)
    /// Sort type (optional)
    /// </summary>
    public string? SortBy { get; set; }

    /// <summary>
    /// ترتيب تصاعدي أو تنازلي (افتراضي: تصاعدي)
    /// Ascending or descending order (default: ascending)
    /// </summary>
    public bool IsAscending { get; set; } = true;

    /// <summary>
    /// فلترة بالمرافق: السماح باختيار كيانات تحتوي على كل المرافق المحددة
    /// Amenity filter: include only properties containing all specified amenities
    /// </summary>
    public IEnumerable<Guid>? AmenityIds { get; set; }

    /// <summary>
    /// فلترة بالتقييم النجمي: عرض الكيانات ذات التقييمات المحددة
    /// Star ratings filter: include properties with specified star ratings
    /// </summary>
    public int[]? StarRatings { get; set; }

    /// <summary>
    /// فلترة بمتوسط تقييم أعلى من قيمة معينة
    /// Filter by minimum average rating
    /// </summary>
    public double? MinAverageRating { get; set; }

    /// <summary>
    /// فلترة بحالة الموافقة (مقبول/مرفوض)
    /// Filter by approval status
    /// </summary>
    public bool? IsApproved { get; set; }

    /// <summary>
    /// فلترة بحسب وجود حجوزات نشطة
    /// Filter by having active bookings
    /// </summary>
    public bool? HasActiveBookings { get; set; }
} 