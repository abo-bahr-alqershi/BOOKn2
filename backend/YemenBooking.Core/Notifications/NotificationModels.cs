using System;

namespace YemenBooking.Core.Notifications
{
    /// <summary>
    /// طلب الإشعار
    /// Notification request
    /// </summary>
    public class NotificationRequest
    {
        /// <summary>
        /// معرف المستخدم المستلم
        /// Identifier of the recipient user
        /// </summary>
        public Guid UserId { get; set; }

        /// <summary>
        /// نوع الإشعار
        /// Notification type
        /// </summary>
        public NotificationType Type { get; set; }

        /// <summary>
        /// عنوان الإشعار
        /// Notification title
        /// </summary>
        public string Title { get; set; } = null!;

        /// <summary>
        /// رسالة الإشعار
        /// Notification message
        /// </summary>
        public string Message { get; set; } = null!;

        /// <summary>
        /// بيانات إضافية للإشعار
        /// Additional data for the notification
        /// </summary>
        public object? Data { get; set; }
    }

    /// <summary>
    /// أنواع الإشعارات
    /// Notification types
    /// </summary>
    public enum NotificationType
    {
        BookingCancelled,
        CheckInCompleted,
        BookingCompleted,
        BookingConfirmed,
        BookingCreated,
        BookingUpdated,
        PaymentProcessed,
        PaymentVoided,
        RefundProcessed,
        PaymentFailed,
        System,
        Promotion,
        Alert
    }
} 