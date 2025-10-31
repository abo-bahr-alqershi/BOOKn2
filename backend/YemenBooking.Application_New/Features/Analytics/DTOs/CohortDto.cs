using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Analytics.DTOs;

/// <summary>
/// بيانات تحليل أفواج العملاء
/// Customer cohort analysis data
/// </summary>
public class CohortDto
{
    /// <summary>
    /// فترة المجموعة (الشهر)
    /// Cohort period (e.g., month)
    /// </summary>
    public string CohortPeriod { get; set; } = string.Empty;

    /// <summary>
    /// إجمالي المستخدمين الجدد
    /// Total new users in cohort
    /// </summary>
    public int TotalNewUsers { get; set; }

    /// <summary>
    /// معدلات الاحتفاظ الشهرية
    /// Monthly retention rates
    /// </summary>
    public List<double> MonthlyRetention { get; set; } = new List<double>();
} 