using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetSystemNotifications
{
    /// <summary>
    /// استعلام للحصول على إشعارات النظام
    /// Query to get system notifications
    /// </summary>
    public class GetSystemNotificationsQuery : IRequest<PaginatedResult<NotificationDto>>
    {
        /// <summary>
        /// نوع الإشعار (اختياري)
        /// </summary>
        public string? NotificationType { get; set; }

        /// <summary>
        /// رقم الصفحة
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة
        /// </summary>
        public int PageSize { get; set; } = 10;

        /// <summary>
        /// فلترة بالمستلم (اختياري)
        /// Recipient filter (optional)
        /// </summary>
        public Guid? RecipientId { get; set; }

        /// <summary>
        /// فلترة بالحالة (اختياري)
        /// Notification status filter (optional)
        /// </summary>
        public string? Status { get; set; }

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
        /// خيارات الترتيب: sent_date, recipient_name (اختياري)
        /// Sort options: sent_date, recipient_name (optional)
        /// </summary>
        public string? SortBy { get; set; }
    }
} 