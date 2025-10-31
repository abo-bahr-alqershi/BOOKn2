using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// بيانات قمع اكتساب العملاء
/// User acquisition funnel data
/// </summary>
public class UserFunnelDto
{
    /// <summary>
    /// إجمالي الزوار
    /// Total visitors
    /// </summary>
    public int TotalVisitors { get; set; }

    /// <summary>
    /// إجمالي عمليات البحث
    /// Total searches
    /// </summary>
    public int TotalSearches { get; set; }

    /// <summary>
    /// إجمالي مشاهدات الكيانات
    /// Total property views
    /// </summary>
    public int TotalPropertyViews { get; set; }

    /// <summary>
    /// إجمالي الحجوزات المكتملة
    /// Total bookings completed
    /// </summary>
    public int TotalBookingsCompleted { get; set; }

    /// <summary>
    /// معدلات التحويل لكل مرحلة
    /// Conversion rates for each stage
    /// </summary>
    public Dictionary<string, double> ConversionRates { get; set; } = new Dictionary<string, double>();
} 