using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع الإشعارات
/// Notification repository interface
/// </summary>
public interface INotificationRepository : IRepository<Notification>
{
    /// <summary>
    /// إنشاء إشعار جديد
    /// Create new notification
    /// </summary>
    Task<bool> CreateNotificationAsync(
        Guid userId,
        string title,
        string message,
        string type = "INFO",
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على إشعارات المستخدم
    /// Get user notifications
    /// </summary>
    Task<IEnumerable<Notification>> GetUserNotificationsAsync(
        Guid userId,
        bool? isRead = null,
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على إشعارات النظام
    /// Get system notifications
    /// </summary>
    Task<IEnumerable<Notification>> GetSystemNotificationsAsync(
        string? notificationType = null,
        DateTime? fromDate = null,
        DateTime? toDate = null,
        int page = 1,
        int pageSize = 50,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث حالة قراءة الإشعار
    /// Update notification read status
    /// </summary>
    Task<bool> MarkNotificationAsReadAsync(
        Guid notificationId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث حالة قراءة جميع إشعارات المستخدم
    /// Mark all user notifications as read
    /// </summary>
    Task<bool> MarkAllUserNotificationsAsReadAsync(
        Guid userId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف الإشعار
    /// Delete notification
    /// </summary>
    Task<bool> DeleteNotificationAsync(
        Guid notificationId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على عدد الإشعارات غير المقروءة
    /// Get unread notifications count
    /// </summary>
    Task<int> GetUnreadNotificationsCountAsync(
        Guid userId,
        CancellationToken cancellationToken = default);
}
