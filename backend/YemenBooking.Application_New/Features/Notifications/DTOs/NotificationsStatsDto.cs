using System;

namespace YemenBooking.Application.Features.Notifications.DTOs {
    /// <summary>
    /// إحصائيات الإشعارات المعروضة في لوحة الإدارة
    /// Notifications statistics for admin dashboard
    /// </summary>
    public class NotificationsStatsDto
    {
        public int Total { get; set; }
        public int Pending { get; set; }
        public int Sent { get; set; }
        public int Delivered { get; set; }
        public int Read { get; set; }
        public int Failed { get; set; }

        public int Today { get; set; }
        public int Last7Days { get; set; }
        public int Last30Days { get; set; }

        // Trends over [from,to] vs previous equal-length window (rounded %)
        public int TotalTrend { get; set; }
        public int SentTrend { get; set; }
        public int PendingTrend { get; set; }
        public int FailedTrend { get; set; }

        // Read rate in % for the window and its trend
        public int ReadRate { get; set; }
        public int ReadRateTrend { get; set; }
    }
}

