using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace YemenBooking.Application.Features.Analytics.Services;

/// <summary>
/// واجهة خدمة تتبع الأحداث للتحليلات
/// Interface for analytics tracker service
/// </summary>
public interface IAnalyticsTrackerService
{
    /// <summary>
    /// تتبع حدث محدد مع خصائص
    /// Track a specific event with properties
    /// </summary>
    Task TrackEventAsync(string eventName, Dictionary<string, string> properties);

    /// <summary>
    /// الحصول على عدد الأحداث ضمن نطاق زمني للأسماء المحددة
    /// Get counts of events within a date range for specified event names
    /// </summary>
    Task<Dictionary<string, int>> GetEventCountsAsync(DateTime startDate, DateTime endDate, IEnumerable<string> eventNames);
} 