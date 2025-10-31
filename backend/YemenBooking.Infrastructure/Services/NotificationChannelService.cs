using Microsoft.Extensions.Logging;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services;

/// <summary>
/// تنفيذ خدمة قنوات الإشعارات
/// Notification channels service implementation
/// </summary>
public class NotificationChannelService : INotificationChannelService
{
    private readonly INotificationChannelRepository _channelRepository;
    private readonly INotificationRepository _notificationRepository;
    private readonly IFirebaseService _firebaseService;
    private readonly ILogger<NotificationChannelService> _logger;
    
    public NotificationChannelService(
        INotificationChannelRepository channelRepository,
        INotificationRepository notificationRepository,
        IFirebaseService firebaseService,
        ILogger<NotificationChannelService> logger)
    {
        _channelRepository = channelRepository;
        _notificationRepository = notificationRepository;
        _firebaseService = firebaseService;
        _logger = logger;
    }
    
    public async Task<NotificationChannel> CreateChannelAsync(
        string name, 
        string identifier, 
        string? description = null, 
        string type = "CUSTOM", 
        Guid? createdBy = null,
        string? icon = null,
        string? color = null,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Creating new channel: {Name} with identifier: {Identifier}", name, identifier);
        
        // التحقق من عدم وجود قناة بنفس المعرف
        var existingChannel = await _channelRepository.GetByIdentifierAsync(identifier, cancellationToken);
        if (existingChannel != null)
        {
            throw new InvalidOperationException($"Channel with identifier '{identifier}' already exists");
        }
        
        var channel = type == "SYSTEM" 
            ? NotificationChannel.CreateSystemChannel(name, identifier)
            : NotificationChannel.CreateCustomChannel(name, identifier, createdBy ?? Guid.Empty);
            
        if (!string.IsNullOrWhiteSpace(description))
        {
            channel.Description = description;
        }
        
        if (!string.IsNullOrWhiteSpace(icon))
        {
            channel.Icon = icon;
        }
        
        if (!string.IsNullOrWhiteSpace(color))
        {
            channel.Color = color;
        }
        
        channel.Type = type;
        
        await _channelRepository.AddAsync(channel, cancellationToken);
        // Persist creation (BaseRepository does not auto-save)
        await _channelRepository.SaveChangesAsync(cancellationToken);
        
        _logger.LogInformation("Channel created successfully: {ChannelId}", channel.Id);
        
        return channel;
    }
    
    public async Task<NotificationChannel> UpdateChannelAsync(
        Guid channelId, 
        string? name = null, 
        string? description = null, 
        bool? isActive = null,
        string? icon = null,
        string? color = null,
        CancellationToken cancellationToken = default)
    {
        var channel = await _channelRepository.GetByIdAsync(channelId, cancellationToken);
        if (channel == null)
        {
            throw new KeyNotFoundException($"Channel with ID '{channelId}' not found");
        }
        
        if (!string.IsNullOrWhiteSpace(name))
        {
            channel.Name = name;
        }
        
        if (description != null)
        {
            channel.Description = description;
        }
        
        if (isActive.HasValue)
        {
            channel.IsActive = isActive.Value;
        }
        
        if (!string.IsNullOrWhiteSpace(icon))
        {
            channel.Icon = icon;
        }
        
        if (!string.IsNullOrWhiteSpace(color))
        {
            channel.Color = color;
        }
        
        channel.UpdatedAt = DateTime.UtcNow;
        
        await _channelRepository.UpdateAsync(channel, cancellationToken);
        // Persist update
        await _channelRepository.SaveChangesAsync(cancellationToken);
        
        _logger.LogInformation("Channel updated: {ChannelId}", channelId);
        
        return channel;
    }
    
    public async Task<bool> DeleteChannelAsync(Guid channelId, CancellationToken cancellationToken = default)
    {
        var channel = await _channelRepository.GetByIdAsync(channelId, cancellationToken);
        if (channel == null)
        {
            return false;
        }
        
        if (!channel.IsDeletable)
        {
            throw new InvalidOperationException($"Channel '{channel.Name}' cannot be deleted");
        }
        
        await _channelRepository.DeleteAsync(channel, cancellationToken);
        // Persist deletion
        await _channelRepository.SaveChangesAsync(cancellationToken);
        
        _logger.LogInformation("Channel deleted: {ChannelId}", channelId);
        
        return true;
    }
    
    public async Task<NotificationChannel?> GetChannelAsync(Guid channelId, CancellationToken cancellationToken = default)
    {
        return await _channelRepository.GetChannelWithSubscribersAsync(channelId, cancellationToken);
    }
    
    public async Task<IEnumerable<NotificationChannel>> GetAllChannelsAsync(bool activeOnly = false, CancellationToken cancellationToken = default)
    {
        if (activeOnly)
        {
            return await _channelRepository.GetActiveChannelsAsync(cancellationToken);
        }
        
        return await _channelRepository.GetAllAsync(cancellationToken);
    }
    
    public async Task<IEnumerable<NotificationChannel>> SearchChannelsAsync(
        string? searchTerm = null, 
        string? type = null, 
        bool? isActive = null, 
        int page = 1, 
        int pageSize = 20, 
        CancellationToken cancellationToken = default)
    {
        return await _channelRepository.SearchChannelsAsync(searchTerm, type, isActive, page, pageSize, cancellationToken);
    }
    
    public async Task<IEnumerable<NotificationChannel>> GetUserChannelsAsync(
        Guid userId, 
        bool activeOnly = true, 
        CancellationToken cancellationToken = default)
    {
        return await _channelRepository.GetUserChannelsAsync(userId, activeOnly, cancellationToken);
    }
    
    public async Task<UserChannel> SubscribeUserAsync(
        Guid userId, 
        Guid channelId, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Subscribing user {UserId} to channel {ChannelId}", userId, channelId);
        
        var channel = await _channelRepository.GetByIdAsync(channelId, cancellationToken);
        if (channel == null)
        {
            throw new KeyNotFoundException($"Channel with ID '{channelId}' not found");
        }
        
        if (!channel.IsActive)
        {
            throw new InvalidOperationException("Cannot subscribe to inactive channel");
        }
        
        var subscription = await _channelRepository.SubscribeUserAsync(userId, channelId, cancellationToken);
        
        // إضافة المستخدم إلى موضوع FCM للقناة
        try
        {
            var fcmTopic = channel.GetFcmTopic();
            // في الإنتاج، يجب الاشتراك من جانب العميل باستخدام FCM SDK
            _logger.LogInformation("User should subscribe to FCM topic: {Topic}", fcmTopic);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error subscribing user to FCM topic");
        }
        
        return subscription;
    }
    
    public async Task<bool> UnsubscribeUserAsync(
        Guid userId, 
        Guid channelId, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Unsubscribing user {UserId} from channel {ChannelId}", userId, channelId);
        
        var result = await _channelRepository.UnsubscribeUserAsync(userId, channelId, cancellationToken);
        
        if (result)
        {
            var channel = await _channelRepository.GetByIdAsync(channelId, cancellationToken);
            if (channel != null)
            {
                try
                {
                    var fcmTopic = channel.GetFcmTopic();
                    // في الإنتاج، يجب إلغاء الاشتراك من جانب العميل باستخدام FCM SDK
                    _logger.LogInformation("User should unsubscribe from FCM topic: {Topic}", fcmTopic);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error unsubscribing user from FCM topic");
                }
            }
        }
        
        return result;
    }
    
    public async Task<int> BulkSubscribeUsersAsync(
        Guid channelId, 
        IEnumerable<Guid> userIds, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Bulk subscribing users to channel {ChannelId}", channelId);
        
        var channel = await _channelRepository.GetByIdAsync(channelId, cancellationToken);
        if (channel == null)
        {
            throw new KeyNotFoundException($"Channel with ID '{channelId}' not found");
        }
        
        if (!channel.IsActive)
        {
            throw new InvalidOperationException("Cannot subscribe to inactive channel");
        }
        
        return await _channelRepository.BulkSubscribeUsersAsync(channelId, userIds, cancellationToken);
    }
    
    public async Task<int> BulkUnsubscribeUsersAsync(
        Guid channelId, 
        IEnumerable<Guid> userIds, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Bulk unsubscribing users from channel {ChannelId}", channelId);
        
        return await _channelRepository.BulkUnsubscribeUsersAsync(channelId, userIds, cancellationToken);
    }
    
    public async Task<UserChannel> ToggleMuteAsync(
        Guid userId, 
        Guid channelId, 
        bool mute, 
        CancellationToken cancellationToken = default)
    {
        var subscription = await _channelRepository.GetUserChannelAsync(userId, channelId, cancellationToken);
        if (subscription == null)
        {
            throw new KeyNotFoundException($"Subscription not found for user {userId} in channel {channelId}");
        }
        
        if (mute)
        {
            subscription.Mute();
        }
        else
        {
            subscription.Unmute();
        }
        
        return await _channelRepository.UpdateUserSubscriptionAsync(subscription, cancellationToken);
    }
    
    public async Task<IEnumerable<UserChannel>> GetChannelSubscribersAsync(
        Guid channelId, 
        bool activeOnly = true, 
        CancellationToken cancellationToken = default)
    {
        return await _channelRepository.GetChannelSubscribersAsync(channelId, activeOnly, cancellationToken);
    }
    
    public async Task<IEnumerable<Guid>> GetChannelSubscriberIdsAsync(
        Guid channelId, 
        bool activeOnly = true, 
        CancellationToken cancellationToken = default)
    {
        return await _channelRepository.GetChannelSubscriberIdsAsync(channelId, activeOnly, cancellationToken);
    }
    
    public async Task<NotificationChannelHistory> SendChannelNotificationAsync(
        Guid channelId, 
        string title, 
        string content, 
        string type = "INFO", 
        Guid? senderId = null, 
        Dictionary<string, string>? data = null, 
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Sending notification to channel {ChannelId}: {Title}", channelId, title);
        
        var channel = await _channelRepository.GetByIdAsync(channelId, cancellationToken);
        if (channel == null)
        {
            throw new KeyNotFoundException($"Channel with ID '{channelId}' not found");
        }
        
        if (!channel.IsActive)
        {
            throw new InvalidOperationException("Cannot send notification to inactive channel");
        }
        
        // الحصول على معرفات المشتركين النشطين
        var subscriberIds = await _channelRepository.GetChannelSubscriberIdsAsync(channelId, true, cancellationToken);
        var subscribersList = subscriberIds.ToList();
        
        // إنشاء سجل الإشعار
        var history = new NotificationChannelHistory
        {
            ChannelId = channelId,
            Title = title,
            Content = content,
            Type = type,
            SenderId = senderId,
            RecipientsCount = subscribersList.Count,
            SentAt = DateTime.UtcNow
        };
        
        // إرسال الإشعار عبر FCM إلى موضوع القناة
        try
        {
            var fcmTopic = channel.GetFcmTopic();
            var fcmData = data ?? new Dictionary<string, string>();
            fcmData["channelId"] = channelId.ToString();
            fcmData["channelName"] = channel.Name;
            fcmData["notificationType"] = type;
            
            var fcmResult = await _firebaseService.SendNotificationAsync(
                fcmTopic,
                title,
                content,
                fcmData,
                cancellationToken
            );
            
            if (fcmResult)
            {
                history.SuccessfulDeliveries = subscribersList.Count;
                _logger.LogInformation("Notification sent successfully to FCM topic: {Topic}", fcmTopic);
            }
            else
            {
                history.FailedDeliveries = subscribersList.Count;
                _logger.LogWarning("Failed to send notification to FCM topic: {Topic}", fcmTopic);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending notification via FCM");
            history.FailedDeliveries = subscribersList.Count;
        }
        
        // إنشاء إشعارات فردية في قاعدة البيانات لكل مشترك
        var batchId = Guid.NewGuid().ToString();
        foreach (var subscriberId in subscribersList)
        {
            try
            {
                var notification = new Notification
                {
                    Type = $"CHANNEL_{type}",
                    Title = title,
                    TitleAr = title,
                    Message = content,
                    MessageAr = content,
                    Priority = type == "URGENT" ? "HIGH" : "MEDIUM",
                    RecipientId = subscriberId,
                    SenderId = senderId,
                    BatchId = batchId,
                    GroupId = $"channel_{channelId}",
                    Channels = new List<string> { "IN_APP", "PUSH" },
                    Data = System.Text.Json.JsonSerializer.Serialize(new
                    {
                        channelId,
                        channelName = channel.Name,
                        customData = data
                    })
                };
                
                await _notificationRepository.AddAsync(notification, cancellationToken);
                
                // تحديث إحصائيات الاشتراك
                var subscription = await _channelRepository.GetUserChannelAsync(subscriberId, channelId, cancellationToken);
                if (subscription != null)
                {
                    subscription.RecordNotificationReceived();
                    await _channelRepository.UpdateUserSubscriptionAsync(subscription, cancellationToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating notification for user {UserId}", subscriberId);
            }
        }
        
        // حفظ سجل الإشعار
        history = await _channelRepository.AddChannelNotificationHistoryAsync(history, cancellationToken);
        
        _logger.LogInformation("Channel notification sent. Recipients: {Recipients}, Successful: {Success}, Failed: {Failed}",
            history.RecipientsCount, history.SuccessfulDeliveries, history.FailedDeliveries);
        
        return history;
    }
    
    public async Task<IEnumerable<NotificationChannelHistory>> GetChannelHistoryAsync(
        Guid channelId, 
        int page = 1, 
        int pageSize = 20, 
        CancellationToken cancellationToken = default)
    {
        return await _channelRepository.GetChannelNotificationHistoryAsync(channelId, page, pageSize, cancellationToken);
    }
    
    public async Task<Dictionary<string, object>> GetChannelsStatisticsAsync(CancellationToken cancellationToken = default)
    {
        return await _channelRepository.GetChannelsStatisticsAsync(cancellationToken);
    }
    
    public async Task<Dictionary<string, object>> GetChannelStatisticsAsync(Guid channelId, CancellationToken cancellationToken = default)
    {
        var channel = await _channelRepository.GetChannelWithSubscribersAsync(channelId, cancellationToken);
        if (channel == null)
        {
            throw new KeyNotFoundException($"Channel with ID '{channelId}' not found");
        }
        
        var stats = new Dictionary<string, object>
        {
            ["channel_id"] = channel.Id,
            ["channel_name"] = channel.Name,
            ["channel_type"] = channel.Type,
            ["is_active"] = channel.IsActive,
            ["subscribers_count"] = channel.SubscribersCount,
            ["active_subscribers"] = channel.UserChannels.Count(uc => uc.IsActive),
            ["muted_subscribers"] = channel.UserChannels.Count(uc => uc.IsActive && uc.IsMuted),
            ["notifications_sent"] = channel.NotificationsSentCount,
            ["last_notification_at"] = channel.LastNotificationAt,
            ["created_at"] = channel.CreatedAt
        };
        
        // إحصائيات الإشعارات الأخيرة
        var recentHistory = await _channelRepository.GetChannelNotificationHistoryAsync(channelId, 1, 10, cancellationToken);
        stats["recent_notifications"] = recentHistory.Select(h => new
        {
            h.Title,
            h.Type,
            h.SentAt,
            h.RecipientsCount,
            h.SuccessfulDeliveries,
            h.FailedDeliveries
        });
        
        return stats;
    }
    
    public async Task CreateDefaultSystemChannelsAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Creating default system channels");
        
        var defaultChannels = new[]
        {
            ("عام", "general", "قناة عامة لجميع المستخدمين"),
            ("العروض والخصومات", "offers", "قناة للعروض والخصومات الخاصة"),
            ("التحديثات", "updates", "قناة تحديثات النظام والمميزات الجديدة"),
            ("الحجوزات", "bookings", "قناة إشعارات الحجوزات"),
            ("المدفوعات", "payments", "قناة إشعارات المدفوعات"),
            ("الطوارئ", "emergency", "قناة الإشعارات العاجلة والطارئة")
        };
        
        foreach (var (name, identifier, description) in defaultChannels)
        {
            try
            {
                var existing = await _channelRepository.GetByIdentifierAsync(identifier, cancellationToken);
                if (existing == null)
                {
                    await CreateChannelAsync(name, identifier, description, "SYSTEM", null, null, null, cancellationToken);
                    _logger.LogInformation("Created default channel: {Name}", name);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating default channel: {Name}", name);
            }
        }
    }
}
