using System;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// بيانات متابعة تقدم ولاء المستخدم
/// User loyalty progress data
/// </summary>
public class LoyaltyProgressDto
{
    /// <summary>
    /// الفئة الحالية
    /// Current tier
    /// </summary>
    public string CurrentTier { get; set; } = string.Empty;

    /// <summary>
    /// الفئة التالية
    /// Next tier
    /// </summary>
    public string NextTier { get; set; } = string.Empty;

    /// <summary>
    /// المبلغ المطلوب للفئة التالية
    /// Amount needed for next tier
    /// </summary>
    public decimal AmountNeededForNextTier { get; set; }
} 