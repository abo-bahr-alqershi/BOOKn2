using System;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// إحصائيات المستخدم مدى الحياة
/// User lifetime statistics
/// </summary>
public class UserLifetimeStatsDto
{
    /// <summary>
    /// إجمالي الليالي المقضاة
    /// Total nights stayed
    /// </summary>
    public int TotalNightsStayed { get; set; }

    /// <summary>
    /// إجمالي المبلغ المنفق
    /// Total money spent
    /// </summary>
    public decimal TotalMoneySpent { get; set; }

    /// <summary>
    /// المدينة المفضلة
    /// Favorite city
    /// </summary>
    public string FavoriteCity { get; set; } = string.Empty;
} 