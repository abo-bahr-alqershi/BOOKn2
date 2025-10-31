using System;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// تفصيل الإيرادات في المنصة
/// Platform revenue breakdown
/// </summary>
public class RevenueBreakdownDto
{
    /// <summary>
    /// إجمالي الإيرادات
    /// Total revenue
    /// </summary>
    public decimal TotalRevenue { get; set; }

    /// <summary>
    /// الإيرادات من العمولة
    /// Revenue from commissions
    /// </summary>
    public decimal RevenueFromCommissions { get; set; }

    /// <summary>
    /// الإيرادات من الخدمات
    /// Revenue from services
    /// </summary>
    public decimal RevenueFromServices { get; set; }
} 