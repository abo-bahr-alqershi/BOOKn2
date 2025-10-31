using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Services;

/// <summary>
/// واجهة خدمة قنوات الإشعارات
/// Notification channels service interface
/// </summary>
public interface INotificationChannelService
{
    /// <summary>
    /// إنشاء قناة جديدة
    /// Create new channel
    /// </summary>
    Task<NotificationChannel> CreateChannelAsync(
        string name,
        string identifier,
        string? description = null,
        string type = "CUSTOM",
        Guid? createdBy = null,
        string? icon = null,
        string? color = null,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تحديث قناة
    /// Update channel
    /// </summary>
    Task<NotificationChannel> UpdateChannelAsync(
        Guid channelId,
        string? name = null,
        string? description = null,
        bool? isActive = null,
        string? icon = null,
        string? color = null,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// حذف قناة
    /// Delete channel
    /// </summary>
    Task<bool> DeleteChannelAsync(Guid channelId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على قناة
    /// Get channel
    /// </summary>
    Task<NotificationChannel?> GetChannelAsync(Guid channelId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على جميع القنوات
    /// Get all channels
    /// </summary>
    Task<IEnumerable<NotificationChannel>> GetAllChannelsAsync(bool activeOnly = false, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// البحث عن القنوات
    /// Search channels
    /// </summary>
    Task<IEnumerable<NotificationChannel>> SearchChannelsAsync(
        string? searchTerm = null,
        string? type = null,
        bool? isActive = null,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على قنوات المستخدم
    /// Get user channels
    /// </summary>
    Task<IEnumerable<NotificationChannel>> GetUserChannelsAsync(
        Guid userId,
        bool activeOnly = true,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// اشتراك مستخدم في قناة
    /// Subscribe user to channel
    /// </summary>
    Task<UserChannel> SubscribeUserAsync(
        Guid userId,
        Guid channelId,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إلغاء اشتراك مستخدم من قناة
    /// Unsubscribe user from channel
    /// </summary>
    Task<bool> UnsubscribeUserAsync(
        Guid userId,
        Guid channelId,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// اشتراك عدة مستخدمين في قناة
    /// Subscribe multiple users to channel
    /// </summary>
    Task<int> BulkSubscribeUsersAsync(
        Guid channelId,
        IEnumerable<Guid> userIds,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إلغاء اشتراك عدة مستخدمين من قناة
    /// Unsubscribe multiple users from channel
    /// </summary>
    Task<int> BulkUnsubscribeUsersAsync(
        Guid channelId,
        IEnumerable<Guid> userIds,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تبديل كتم الإشعارات للمستخدم في قناة
    /// Toggle mute notifications for user in channel
    /// </summary>
    Task<UserChannel> ToggleMuteAsync(
        Guid userId,
        Guid channelId,
        bool mute,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على مشتركي القناة
    /// Get channel subscribers
    /// </summary>
    Task<IEnumerable<UserChannel>> GetChannelSubscribersAsync(
        Guid channelId,
        bool activeOnly = true,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على معرفات المشتركين
    /// Get subscriber IDs
    /// </summary>
    Task<IEnumerable<Guid>> GetChannelSubscriberIdsAsync(
        Guid channelId,
        bool activeOnly = true,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إرسال إشعار عبر القناة
    /// Send notification through channel
    /// </summary>
    Task<NotificationChannelHistory> SendChannelNotificationAsync(
        Guid channelId,
        string title,
        string content,
        string type = "INFO",
        Guid? senderId = null,
        Dictionary<string, string>? data = null,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على سجل إشعارات القناة
    /// Get channel notification history
    /// </summary>
    Task<IEnumerable<NotificationChannelHistory>> GetChannelHistoryAsync(
        Guid channelId,
        int page = 1,
        int pageSize = 20,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على إحصائيات القنوات
    /// Get channels statistics
    /// </summary>
    Task<Dictionary<string, object>> GetChannelsStatisticsAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على إحصائيات قناة محددة
    /// Get specific channel statistics
    /// </summary>
    Task<Dictionary<string, object>> GetChannelStatisticsAsync(Guid channelId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إنشاء قنوات النظام الافتراضية
    /// Create default system channels
    /// </summary>
    Task CreateDefaultSystemChannelsAsync(CancellationToken cancellationToken = default);
}
