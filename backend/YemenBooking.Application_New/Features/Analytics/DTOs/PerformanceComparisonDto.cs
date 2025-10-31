using System;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// مقارنة أداء الكيان بين فترتين زمنيتين
/// Property performance comparison between two periods
/// </summary>
public class PerformanceComparisonDto
{
    /// <summary>
    /// إيرادات الفترة الحالية
    /// Current period revenue
    /// </summary>
    public decimal CurrentPeriodRevenue { get; set; }

    /// <summary>
    /// إيرادات الفترة السابقة
    /// Previous period revenue
    /// </summary>
    public decimal PreviousPeriodRevenue { get; set; }

    /// <summary>
    /// نسبة التغير في الإيرادات
    /// Revenue change percentage
    /// </summary>
    public double RevenueChangePercentage { get; set; }
} 