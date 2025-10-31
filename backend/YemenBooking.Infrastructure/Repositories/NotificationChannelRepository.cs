using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories;

/// <summary>
/// تنفيذ مستودع قنوات الإشعارات
/// Notification channels repository implementation
/// </summary>
public class NotificationChannelRepository : BaseRepository<NotificationChannel>, INotificationChannelRepository
{
    public NotificationChannelRepository(YemenBookingDbContext context) : base(context)
    {
    }
    
    public async Task<IEnumerable<NotificationChannel>> GetActiveChannelsAsync(CancellationToken cancellationToken = default)
    {
        return await _context.NotificationChannels
            .Where(c => c.IsActive)
            .Include(c => c.UserChannels)
            .OrderBy(c => c.Name)
            .ToListAsync(cancellationToken);
    }
    
    public async Task<NotificationChannel?> GetByIdentifierAsync(string identifier, CancellationToken cancellationToken = default)
    {
        return await _context.NotificationChannels
            .FirstOrDefaultAsync(c => c.Identifier == identifier, cancellationToken);
    }
    
    public async Task<IEnumerable<NotificationChannel>> GetChannelsWithSubscribersAsync(CancellationToken cancellationToken = default)
    {
        return await _context.NotificationChannels
            .Include(c => c.UserChannels)
                .ThenInclude(uc => uc.User)
            .OrderBy(c => c.Name)
            .ToListAsync(cancellationToken);
    }
    
    public async Task<IEnumerable<NotificationChannel>> GetUserChannelsAsync(Guid userId, bool activeOnly = true, CancellationToken cancellationToken = default)
    {
        var query = _context.UserChannels
            .Where(uc => uc.UserId == userId);
            
        if (activeOnly)
        {
            query = query.Where(uc => uc.IsActive && uc.Channel.IsActive);
        }
        
        return await query
            .Include(uc => uc.Channel)
            .Select(uc => uc.Channel)
            .Distinct()
            .OrderBy(c => c.Name)
            .ToListAsync(cancellationToken);
    }
    
    public async Task<IEnumerable<NotificationChannel>> GetAvailableChannelsForUserAsync(Guid userId, string? userRole = null, CancellationToken cancellationToken = default)
    {
        // الحصول على القنوات التي لم يشترك بها المستخدم بعد
        var subscribedChannelIds = await _context.UserChannels
            .Where(uc => uc.UserId == userId && uc.IsActive)
            .Select(uc => uc.ChannelId)
            .ToListAsync(cancellationToken);
            
        var query = _context.NotificationChannels
            .Where(c => c.IsActive && !subscribedChannelIds.Contains(c.Id));
            
        // تصفية بناءً على نوع القناة والأدوار المسموحة
        if (!string.IsNullOrEmpty(userRole))
        {
            query = query.Where(c => 
                !c.IsPrivate || 
                (c.Type == "ROLE_BASED" && c.AllowedRoles.Contains(userRole))
            );
        }
        else
        {
            query = query.Where(c => !c.IsPrivate);
        }
        
        return await query
            .OrderBy(c => c.Name)
            .ToListAsync(cancellationToken);
    }
    
    public async Task<NotificationChannel?> GetChannelWithSubscribersAsync(Guid channelId, CancellationToken cancellationToken = default)
    {
        return await _context.NotificationChannels
            .Include(c => c.UserChannels)
                .ThenInclude(uc => uc.User)
            .FirstOrDefaultAsync(c => c.Id == channelId, cancellationToken);
    }
    
    public async Task<Dictionary<string, object>> GetChannelsStatisticsAsync(CancellationToken cancellationToken = default)
    {
        var stats = new Dictionary<string, object>();
        
        stats["total_channels"] = await _context.NotificationChannels.CountAsync(cancellationToken);
        stats["active_channels"] = await _context.NotificationChannels.CountAsync(c => c.IsActive, cancellationToken);
        stats["total_subscriptions"] = await _context.UserChannels.CountAsync(cancellationToken);
        stats["active_subscriptions"] = await _context.UserChannels.CountAsync(uc => uc.IsActive, cancellationToken);
        stats["total_notifications_sent"] = await _context.NotificationChannelHistories.CountAsync(cancellationToken);
        
        // إحصائيات حسب نوع القناة
        var channelsByType = await _context.NotificationChannels
            .GroupBy(c => c.Type)
            .Select(g => new { Type = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Type, x => x.Count, cancellationToken);
        stats["channels_by_type"] = channelsByType;
        
        // أكثر القنوات نشاطًا
        var topChannels = await _context.NotificationChannels
            .OrderByDescending(c => c.NotificationsSentCount)
            .Take(5)
            .Select(c => new { c.Id, c.Name, c.NotificationsSentCount, c.SubscribersCount })
            .ToListAsync(cancellationToken);
        stats["top_active_channels"] = topChannels;
        
        return stats;
    }
    
    public async Task<bool> IsUserSubscribedAsync(Guid userId, Guid channelId, CancellationToken cancellationToken = default)
    {
        return await _context.UserChannels
            .AnyAsync(uc => uc.UserId == userId && uc.ChannelId == channelId && uc.IsActive, cancellationToken);
    }
    
    public async Task<UserChannel> SubscribeUserAsync(Guid userId, Guid channelId, CancellationToken cancellationToken = default)
    {
        // التحقق من وجود اشتراك سابق
        var existingSubscription = await _context.UserChannels
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.ChannelId == channelId, cancellationToken);
            
        if (existingSubscription != null)
        {
            // إعادة تفعيل الاشتراك إذا كان موجودًا
            existingSubscription.Activate();
            await _context.SaveChangesAsync(cancellationToken);
            
            // تحديث عدد المشتركين
            var channel = await _context.NotificationChannels.FindAsync(new object[] { channelId }, cancellationToken);
            if (channel != null && !existingSubscription.IsActive)
            {
                channel.AddSubscriber();
                await _context.SaveChangesAsync(cancellationToken);
            }
            
            return existingSubscription;
        }
        
        // إنشاء اشتراك جديد
        var subscription = new UserChannel
        {
            UserId = userId,
            ChannelId = channelId,
            IsActive = true,
            SubscribedAt = DateTime.UtcNow
        };
        
        _context.UserChannels.Add(subscription);
        
        // تحديث عدد المشتركين
        var channelEntity = await _context.NotificationChannels.FindAsync(new object[] { channelId }, cancellationToken);
        if (channelEntity != null)
        {
            channelEntity.AddSubscriber();
        }
        
        await _context.SaveChangesAsync(cancellationToken);
        
        return subscription;
    }
    
    public async Task<bool> UnsubscribeUserAsync(Guid userId, Guid channelId, CancellationToken cancellationToken = default)
    {
        var subscription = await _context.UserChannels
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.ChannelId == channelId, cancellationToken);
            
        if (subscription == null)
        {
            return false;
        }
        
        subscription.Deactivate();
        
        // تحديث عدد المشتركين
        var channel = await _context.NotificationChannels.FindAsync(new object[] { channelId }, cancellationToken);
        if (channel != null)
        {
            channel.RemoveSubscriber();
        }
        
        await _context.SaveChangesAsync(cancellationToken);
        
        return true;
    }
    
    public async Task<UserChannel?> GetUserChannelAsync(Guid userId, Guid channelId, CancellationToken cancellationToken = default)
    {
        return await _context.UserChannels
            .Include(uc => uc.Channel)
            .Include(uc => uc.User)
            .FirstOrDefaultAsync(uc => uc.UserId == userId && uc.ChannelId == channelId, cancellationToken);
    }
    
    public async Task<IEnumerable<UserChannel>> GetUserSubscriptionsAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return await _context.UserChannels
            .Include(uc => uc.Channel)
            .Where(uc => uc.UserId == userId)
            .OrderBy(uc => uc.Channel.Name)
            .ToListAsync(cancellationToken);
    }
    
    public async Task<IEnumerable<UserChannel>> GetChannelSubscribersAsync(Guid channelId, bool activeOnly = true, CancellationToken cancellationToken = default)
    {
        var query = _context.UserChannels
            .Include(uc => uc.User)
            .Where(uc => uc.ChannelId == channelId);
            
        if (activeOnly)
        {
            query = query.Where(uc => uc.IsActive);
        }
        
        return await query
            .OrderBy(uc => uc.User.Name)
            .ToListAsync(cancellationToken);
    }
    
    public async Task<UserChannel> UpdateUserSubscriptionAsync(UserChannel subscription, CancellationToken cancellationToken = default)
    {
        _context.UserChannels.Update(subscription);
        await _context.SaveChangesAsync(cancellationToken);
        return subscription;
    }
    
    public async Task<NotificationChannelHistory> AddChannelNotificationHistoryAsync(NotificationChannelHistory history, CancellationToken cancellationToken = default)
    {
        _context.NotificationChannelHistories.Add(history);
        
        // تحديث إحصائيات القناة
        var channel = await _context.NotificationChannels.FindAsync(new object[] { history.ChannelId }, cancellationToken);
        if (channel != null)
        {
            channel.RecordNotificationSent();
        }
        
        await _context.SaveChangesAsync(cancellationToken);
        
        return history;
    }
    
    public async Task<IEnumerable<NotificationChannelHistory>> GetChannelNotificationHistoryAsync(Guid channelId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default)
    {
        return await _context.NotificationChannelHistories
            .Where(h => h.ChannelId == channelId)
            .Include(h => h.Sender)
            .OrderByDescending(h => h.SentAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }
    
    public async Task<IEnumerable<Guid>> GetChannelSubscriberIdsAsync(Guid channelId, bool activeOnly = true, CancellationToken cancellationToken = default)
    {
        var query = _context.UserChannels
            .Where(uc => uc.ChannelId == channelId);
            
        if (activeOnly)
        {
            query = query.Where(uc => uc.IsActive && !uc.IsMuted);
        }
        
        return await query
            .Select(uc => uc.UserId)
            .Distinct()
            .ToListAsync(cancellationToken);
    }
    
    public async Task<IEnumerable<NotificationChannel>> SearchChannelsAsync(string? searchTerm = null, string? type = null, bool? isActive = null, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default)
    {
        var query = _context.NotificationChannels.AsQueryable();
        
        if (!string.IsNullOrWhiteSpace(searchTerm))
        {
            query = query.Where(c => 
                c.Name.Contains(searchTerm) || 
                c.Description!.Contains(searchTerm) ||
                c.Identifier.Contains(searchTerm)
            );
        }
        
        if (!string.IsNullOrWhiteSpace(type))
        {
            query = query.Where(c => c.Type == type);
        }
        
        if (isActive.HasValue)
        {
            query = query.Where(c => c.IsActive == isActive.Value);
        }
        
        return await query
            .OrderBy(c => c.Name)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }
    
    public async Task<int> BulkSubscribeUsersAsync(Guid channelId, IEnumerable<Guid> userIds, CancellationToken cancellationToken = default)
    {
        var count = 0;
        var channel = await _context.NotificationChannels.FindAsync(new object[] { channelId }, cancellationToken);
        
        if (channel == null)
        {
            return 0;
        }
        
        foreach (var userId in userIds)
        {
            // التحقق من عدم وجود اشتراك
            var exists = await _context.UserChannels
                .AnyAsync(uc => uc.UserId == userId && uc.ChannelId == channelId, cancellationToken);
                
            if (!exists)
            {
                var subscription = new UserChannel
                {
                    UserId = userId,
                    ChannelId = channelId,
                    IsActive = true,
                    SubscribedAt = DateTime.UtcNow
                };
                
                _context.UserChannels.Add(subscription);
                count++;
            }
        }
        
        if (count > 0)
        {
            channel.SubscribersCount += count;
            await _context.SaveChangesAsync(cancellationToken);
        }
        
        return count;
    }
    
    public async Task<int> BulkUnsubscribeUsersAsync(Guid channelId, IEnumerable<Guid> userIds, CancellationToken cancellationToken = default)
    {
        var subscriptions = await _context.UserChannels
            .Where(uc => uc.ChannelId == channelId && userIds.Contains(uc.UserId) && uc.IsActive)
            .ToListAsync(cancellationToken);
            
        var count = subscriptions.Count;
        
        if (count > 0)
        {
            foreach (var subscription in subscriptions)
            {
                subscription.Deactivate();
            }
            
            var channel = await _context.NotificationChannels.FindAsync(new object[] { channelId }, cancellationToken);
            if (channel != null)
            {
                channel.SubscribersCount = Math.Max(0, channel.SubscribersCount - count);
            }
            
            await _context.SaveChangesAsync(cancellationToken);
        }
        
        return count;
    }
    
    public async Task UpdateChannelStatisticsAsync(Guid channelId, CancellationToken cancellationToken = default)
    {
        var channel = await _context.NotificationChannels.FindAsync(new object[] { channelId }, cancellationToken);
        
        if (channel != null)
        {
            // تحديث عدد المشتركين
            channel.SubscribersCount = await _context.UserChannels
                .CountAsync(uc => uc.ChannelId == channelId && uc.IsActive, cancellationToken);
                
            // تحديث عدد الإشعارات المرسلة
            channel.NotificationsSentCount = await _context.NotificationChannelHistories
                .CountAsync(h => h.ChannelId == channelId, cancellationToken);
                
            // تحديث آخر وقت إرسال
            var lastNotification = await _context.NotificationChannelHistories
                .Where(h => h.ChannelId == channelId)
                .OrderByDescending(h => h.SentAt)
                .FirstOrDefaultAsync(cancellationToken);
                
            if (lastNotification != null)
            {
                channel.LastNotificationAt = lastNotification.SentAt;
            }
            
            await _context.SaveChangesAsync(cancellationToken);
        }
    }
}
