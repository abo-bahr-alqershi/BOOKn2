using System;

namespace YemenBooking.Core.ValueObjects;

/// <summary>
/// ملخص سبب الإلغاء
/// Cancellation reason summary
/// </summary>
public class CancellationReasonSummary
{
    /// <summary>
    /// سبب الإلغاء
    /// Cancellation reason
    /// </summary>
    public string Reason { get; set; } = string.Empty;

    /// <summary>
    /// عدد الإلغاءات لهذا السبب
    /// Count of cancellations for this reason
    /// </summary>
    public int Count { get; set; }

    /// <summary>
    /// الإيرادات المفقودة بسبب هذا السبب
    /// Lost revenue due to this reason
    /// </summary>
    public decimal LostRevenue { get; set; }
} 