using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;

namespace YemenBooking.Application.Features.SearchAndFilters.Commands.Search;

/// <summary>
/// أمر البحث في الكيانات
/// Search properties command
/// </summary>
public class SearchPropertiesCommand : IRequest<ResultDto<SearchPropertiesResponse>>
{
    /// <summary>
    /// المدينة
    /// City
    /// </summary>
    public string? City { get; set; }

    /// <summary>
    /// تاريخ الدخول
    /// Check-in date
    /// </summary>
    public DateTime? CheckIn { get; set; }

    /// <summary>
    /// تاريخ الخروج
    /// Check-out date
    /// </summary>
    public DateTime? CheckOut { get; set; }

    /// <summary>
    /// عدد الضيوف
    /// Guest count
    /// </summary>
    public int? GuestCount { get; set; }

    /// <summary>
    /// نوع الكيان
    /// Property type ID
    /// </summary>
    public Guid? PropertyTypeId { get; set; }

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
    /// ترتيب النتائج
    /// Sort by
    /// </summary>
    public string? SortBy { get; set; }

    /// <summary>
    /// اتجاه الترتيب
    /// Sort direction
    /// </summary>
    public string SortDirection { get; set; } = "asc";

    /// <summary>
    /// الحد الأدنى للسعر
    /// Minimum price
    /// </summary>
    public decimal? MinPrice { get; set; }

    /// <summary>
    /// الحد الأقصى للسعر
    /// Maximum price
    /// </summary>
    public decimal? MaxPrice { get; set; }

    /// <summary>
    /// المرافق المطلوبة
    /// Required amenities
    /// </summary>
    public List<Guid>? AmenityIds { get; set; }

    /// <summary>
    /// تقييم النجوم
    /// Star rating
    /// </summary>
    public List<int>? StarRatings { get; set; }

    /// <summary>
    /// الحد الأدنى لمتوسط التقييم
    /// Minimum average rating
    /// </summary>
    public decimal? MinAverageRating { get; set; }

    /// <summary>
    /// البحث النصي
    /// Search term
    /// </summary>
    public string? SearchTerm { get; set; }

    /// <summary>
    /// الموقع الجغرافي - خط العرض
    /// Latitude for location search
    /// </summary>
    public double? Latitude { get; set; }

    /// <summary>
    /// الموقع الجغرافي - خط الطول
    /// Longitude for location search
    /// </summary>
    public double? Longitude { get; set; }

    /// <summary>
    /// نطاق البحث بالكيلومتر
    /// Search radius in kilometers
    /// </summary>
    public double? RadiusKm { get; set; }
}






