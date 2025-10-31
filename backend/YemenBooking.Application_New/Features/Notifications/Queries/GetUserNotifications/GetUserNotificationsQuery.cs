using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetUserNotifications
{
    /// <summary>
    /// استعلام للحصول على إشعارات المستخدم
    /// Query to get user notifications
    /// </summary>
    public class GetUserNotificationsQuery : IRequest<PaginatedResult<NotificationDto>>
    {
        /// <summary>
        /// معرف المستخدم
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// الحالة (مقروءة/غير مقروءة) (اختياري)
        /// </summary>
        public bool? IsRead { get; set; }

        /// <summary>
        /// رقم الصفحة
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة
        /// </summary>
        public int PageSize { get; set; } = 10;

        /// <summary>
        /// فلترة بنوع الإشعار (اختياري)
        /// Notification type filter (optional)
        /// </summary>
        public string? NotificationType { get; set; }

        /// <summary>
        /// فلترة بتاريخ الإرسال بعد (اختياري)
        /// Sent after date filter (optional)
        /// </summary>
        public DateTime? SentAfter { get; set; }

        /// <summary>
        /// فلترة بتاريخ الإرسال قبل (اختياري)
        /// Sent before date filter (optional)
        /// </summary>
        public DateTime? SentBefore { get; set; }

        /// <summary>
        /// خيارات الترتيب: sent_date, status (اختياري)
        /// Sort options: sent_date, status (optional)
        /// </summary>
        public string? SortBy { get; set; }
    }
} 