using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع قنوات الإشعارات
/// Notification channels repository interface
/// </summary>
public interface INotificationChannelRepository : IRepository<NotificationChannel>
{
    /// <summary>
    /// الحصول على جميع القنوات النشطة
    /// Get all active channels
    /// </summary>
    Task<IEnumerable<NotificationChannel>> GetActiveChannelsAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على قناة بواسطة المعرف الفريد
    /// Get channel by identifier
    /// </summary>
    Task<NotificationChannel?> GetByIdentifierAsync(string identifier, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على القنوات مع تفاصيل المشتركين
    /// Get channels with subscribers details
    /// </summary>
    Task<IEnumerable<NotificationChannel>> GetChannelsWithSubscribersAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على قنوات المستخدم
    /// Get user channels
    /// </summary>
    Task<IEnumerable<NotificationChannel>> GetUserChannelsAsync(Guid userId, bool activeOnly = true, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على القنوات المتاحة للمستخدم
    /// Get available channels for user
    /// </summary>
    Task<IEnumerable<NotificationChannel>> GetAvailableChannelsForUserAsync(Guid userId, string? userRole = null, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على قناة مع المشتركين
    /// Get channel with subscribers
    /// </summary>
    Task<NotificationChannel?> GetChannelWithSubscribersAsync(Guid channelId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على إحصائيات القنوات
    /// Get channels statistics
    /// </summary>
    Task<Dictionary<string, object>> GetChannelsStatisticsAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من وجود اشتراك
    /// Check if user is subscribed
    /// </summary>
    Task<bool> IsUserSubscribedAsync(Guid userId, Guid channelId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// اشتراك مستخدم في قناة
    /// Subscribe user to channel
    /// </summary>
    Task<UserChannel> SubscribeUserAsync(Guid userId, Guid channelId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إلغاء اشتراك مستخدم من قناة
    /// Unsubscribe user from channel
    /// </summary>
    Task<bool> UnsubscribeUserAsync(Guid userId, Guid channelId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على اشتراك المستخدم في القناة
    /// Get user channel subscription
    /// </summary>
    Task<UserChannel?> GetUserChannelAsync(Guid userId, Guid channelId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على اشتراكات المستخدم
    /// Get user subscriptions
    /// </summary>
    Task<IEnumerable<UserChannel>> GetUserSubscriptionsAsync(Guid userId, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على مشتركي القناة
    /// Get channel subscribers
    /// </summary>
    Task<IEnumerable<UserChannel>> GetChannelSubscribersAsync(Guid channelId, bool activeOnly = true, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تحديث اشتراك المستخدم
    /// Update user subscription
    /// </summary>
    Task<UserChannel> UpdateUserSubscriptionAsync(UserChannel subscription, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إضافة سجل إشعار للقناة
    /// Add notification history for channel
    /// </summary>
    Task<NotificationChannelHistory> AddChannelNotificationHistoryAsync(NotificationChannelHistory history, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على سجل إشعارات القناة
    /// Get channel notification history
    /// </summary>
    Task<IEnumerable<NotificationChannelHistory>> GetChannelNotificationHistoryAsync(
        Guid channelId, 
        int page = 1, 
        int pageSize = 20, 
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على معرفات المستخدمين المشتركين في القناة
    /// Get subscriber user IDs for a channel
    /// </summary>
    Task<IEnumerable<Guid>> GetChannelSubscriberIdsAsync(Guid channelId, bool activeOnly = true, CancellationToken cancellationToken = default);
    
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
    /// اشتراك عدة مستخدمين في قناة
    /// Subscribe multiple users to channel
    /// </summary>
    Task<int> BulkSubscribeUsersAsync(Guid channelId, IEnumerable<Guid> userIds, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إلغاء اشتراك عدة مستخدمين من قناة
    /// Unsubscribe multiple users from channel
    /// </summary>
    Task<int> BulkUnsubscribeUsersAsync(Guid channelId, IEnumerable<Guid> userIds, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تحديث إحصائيات القناة
    /// Update channel statistics
    /// </summary>
    Task UpdateChannelStatisticsAsync(Guid channelId, CancellationToken cancellationToken = default);
}
