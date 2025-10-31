using System;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// ملخص سبب الإلغاء
/// Cancellation reason summary
/// </summary>
public class CancellationReasonDto
{
    /// <summary>
    /// سبب الإلغاء
    /// Cancellation reason
    /// </summary>
    public string Reason { get; set; } = string.Empty;

    /// <summary>
    /// عدد مرات الإلغاء لهذا السبب
    /// Count of cancellations for this reason
    /// </summary>
    public int Count { get; set; }

    /// <summary>
    /// الإيرادات المفقودة بسبب هذا السبب
    /// Lost revenue due to this reason
    /// </summary>
    public decimal LostRevenue { get; set; }
} 