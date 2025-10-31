// using YemenBooking.Application.Common.Models;
// using YemenBooking.Core.Entities;
// using YemenBooking.Core.Enums;

// namespace YemenBooking.Application.Infrastructure.Services;

// /// <summary>
// /// نوع الإشعار
// /// Notification type
// /// </summary>
// public enum NotificationType
// {
//     Email = 1,
//     SMS = 2,
//     Push = 3,
//     InApp = 4,
//     WhatsApp = 5
// }

// /// <summary>
// /// واجهة خدمة الإشعارات
// /// Notification service interface
// /// </summary>
// public interface INotificationService
// {
//     /// <summary>
//     /// إرسال إشعار
//     /// Send a notification
//     /// </summary>
//     Task<ResultDto<bool>> SendNotificationAsync(NotificationRequest request, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// إرسال إشعارات متعددة
//     /// Send multiple notifications
//     /// </summary>
//     Task<ResultDto<int>> SendBatchNotificationsAsync(IEnumerable<NotificationRequest> requests, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// إرسال إشعار البريد الإلكتروني
//     /// Send email notification
//     /// </summary>
//     Task<ResultDto<bool>> SendEmailAsync(EmailNotification email, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// إرسال رسالة نصية قصيرة
//     /// Send SMS notification
//     /// </summary>
//     Task<ResultDto<bool>> SendSmsAsync(SmsNotification sms, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// إرسال إشعار داخل التطبيق
//     /// Send in-app notification
//     /// </summary>
//     Task<ResultDto<bool>> SendInAppNotificationAsync(InAppNotification notification, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// إرسال إشعار دفع
//     /// Send push notification
//     /// </summary>
//     Task<ResultDto<bool>> SendPushNotificationAsync(PushNotification push, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// الحصول على قوالب الإشعارات
//     /// Get notification templates
//     /// </summary>
//     Task<ResultDto<IEnumerable<NotificationTemplate>>> GetTemplatesAsync(NotificationType type, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// تسجيل قراءة الإشعار
//     /// Mark notification as read
//     /// </summary>
//     Task<ResultDto<bool>> MarkAsReadAsync(Guid notificationId, CancellationToken cancellationToken = default);

//     /// <summary>
//     /// حذف إشعار
//     /// Delete notification
//     /// </summary>
//     Task<ResultDto<bool>> DeleteNotificationAsync(Guid notificationId, CancellationToken cancellationToken = default);
// }

// /// <summary>
// /// طلب الإشعار
// /// Notification request
// /// </summary>
// public class NotificationRequest
// {
//     public Guid UserId { get; set; }
//     public NotificationType Type { get; set; }
//     public string Title { get; set; }
//     public string Message { get; set; }
//     public NotificationPriority Priority { get; set; }
//     public Dictionary<string, string> Data { get; set; }
//     public string TemplateId { get; set; }
//     public Dictionary<string, string> TemplateVariables { get; set; }
//     public DateTime? ScheduledAt { get; set; }
// }

// /// <summary>
// /// إشعار البريد الإلكتروني
// /// Email notification
// /// </summary>
// public class EmailNotification
// {
//     public string To { get; set; }
//     public string[] Cc { get; set; }
//     public string[] Bcc { get; set; }
//     public string Subject { get; set; }
//     public string Body { get; set; }
//     public bool IsHtml { get; set; }
//     public Dictionary<string, byte[]> Attachments { get; set; }
//     public string TemplateId { get; set; }
//     public Dictionary<string, string> TemplateVariables { get; set; }
// }

// /// <summary>
// /// إشعار الرسائل النصية
// /// SMS notification
// /// </summary>
// public class SmsNotification
// {
//     public string PhoneNumber { get; set; }
//     public string Message { get; set; }
//     public string SenderId { get; set; }
//     public string TemplateId { get; set; }
//     public Dictionary<string, string> TemplateVariables { get; set; }
// }

// /// <summary>
// /// إشعار داخل التطبيق
// /// In-app notification
// /// </summary>
// public class InAppNotification
// {
//     public Guid UserId { get; set; }
//     public string Title { get; set; }
//     public string Message { get; set; }
//     public NotificationType Type { get; set; }
//     public string ActionUrl { get; set; }
//     public string IconUrl { get; set; }
//     public Dictionary<string, string> Data { get; set; }
//     public bool IsPersistent { get; set; }
// }

// /// <summary>
// /// إشعار الدفع
// /// Push notification
// /// </summary>
// public class PushNotification
// {
//     public Guid UserId { get; set; }
//     public string Title { get; set; }
//     public string Body { get; set; }
//     public string ImageUrl { get; set; }
//     public string Sound { get; set; }
//     public int Badge { get; set; }
//     public Dictionary<string, string> Data { get; set; }
//     public string[] DeviceTokens { get; set; }
// }

// /// <summary>
// /// قالب الإشعار
// /// Notification template
// /// </summary>
// public class NotificationTemplate
// {
//     public string Id { get; set; }
//     public string Name { get; set; }
//     public NotificationType Type { get; set; }
//     public string Subject { get; set; }
//     public string Body { get; set; }
//     public List<string> RequiredVariables { get; set; }
//     public bool IsActive { get; set; }
// }

// /// <summary>
// /// أولوية الإشعار
// /// Notification priority
// /// </summary>
// public enum NotificationPriority
// {
//     Low = 0,
//     Normal = 1,
//     High = 2,
//     Urgent = 3
// }
