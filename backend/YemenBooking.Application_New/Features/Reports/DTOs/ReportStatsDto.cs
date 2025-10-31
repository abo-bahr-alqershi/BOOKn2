using System;
using System.Collections.Generic;

namespace YemenBooking.Application.Features.Reports.DTOs {
    /// <summary>
    /// إحصائيات عامة عن البلاغات
    /// General analytics and statistics for reports
    /// </summary>
    public class ReportStatsDto
    {
        /// <summary>
        /// إجمالي عدد البلاغات
        /// Total number of reports
        /// </summary>
        public int TotalReports { get; set; }

        /// <summary>
        /// عدد البلاغات المعلقة
        /// Number of pending reports
        /// </summary>
        public int PendingReports { get; set; }

        /// <summary>
        /// عدد البلاغات المحلولة
        /// Number of resolved reports
        /// </summary>
        public int ResolvedReports { get; set; }

        /// <summary>
        /// عدد البلاغات المرفوضة
        /// Number of dismissed reports
        /// </summary>
        public int DismissedReports { get; set; }

        /// <summary>
        /// عدد البلاغات المصعّدة
        /// Number of escalated reports
        /// </summary>
        public int EscalatedReports { get; set; }

        /// <summary>
        /// متوسط زمن حل البلاغ (بالأيام)
        /// Average resolution time in days
        /// </summary>
        public double AverageResolutionTime { get; set; }

        /// <summary>
        /// عدد البلاغات حسب السبب
        /// Number of reports by reason/category
        /// </summary>
        public Dictionary<string, int> ReportsByCategory { get; set; } = new();

        /// <summary>
        /// اتجاه البلاغات على مدى الأيام الأخيرة
        /// Trend of reports over recent days
        /// </summary>
        public List<ReportTrendItem> ReportsTrend { get; set; } = new();
    }

    /// <summary>
    /// عنصر يمثل اتجاه البلاغات ليوم معين
    /// Trend item representing report count for a specific date
    /// </summary>
    public class ReportTrendItem
    {
        /// <summary>
        /// التاريخ
        /// Date
        /// </summary>
        public DateTime Date { get; set; }

        /// <summary>
        /// عدد البلاغات في ذلك التاريخ
        /// Report count on that date
        /// </summary>
        public int Count { get; set; }
    }
} 