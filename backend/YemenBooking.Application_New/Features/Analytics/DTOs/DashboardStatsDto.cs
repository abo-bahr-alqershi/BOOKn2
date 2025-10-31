namespace YemenBooking.Application.Features.Analytics.DTOs {
    /// <summary>
    /// احصائيات لوحة التحكم للمسؤول
    /// Dashboard statistics for admin
    /// </summary>
    public class DashboardStatsDto
    {
        /// <summary>
        /// عدد المستخدمين غير المؤكدين
        /// Number of unverified users
        /// </summary>
        public int UnverifiedUsers { get; set; }

        /// <summary>
        /// عدد الكيانات غير المعتمدة
        /// Number of unapproved properties
        /// </summary>
        public int UnapprovedProperties { get; set; }

        /// <summary>
        /// عدد الحجوزات غير المؤكدة
        /// Number of unconfirmed bookings
        /// </summary>
        public int UnconfirmedBookings { get; set; }

        /// <summary>
        /// عدد الاشعارات غير المقروءة
        /// Number of unread notifications
        /// </summary>
        public int UnreadNotifications { get; set; }
    }
} 