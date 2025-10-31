using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع الإشعارات
    /// Notification repository implementation
    /// </summary>
    public class NotificationRepository : BaseRepository<Notification>, INotificationRepository
    {
        public NotificationRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<bool> CreateNotificationAsync(Guid userId, string title, string message, string type = "INFO", CancellationToken cancellationToken = default)
        {
            var notif = new Notification { RecipientId = userId, Title = title, Message = message, Type = type, CreatedAt = DateTime.UtcNow };
            await _dbSet.AddAsync(notif, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<Notification>> GetUserNotificationsAsync(Guid userId, bool? isRead = null, int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
        {
            var query = _dbSet.Where(n => n.RecipientId == userId && !n.IsDismissed);
            if (isRead.HasValue) query = query.Where(n => n.IsRead == isRead.Value);
            var items = await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page-1)*pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);
            return items;
        }

        public async Task<IEnumerable<Notification>> GetSystemNotificationsAsync(string? notificationType = null, DateTime? fromDate = null, DateTime? toDate = null, int page = 1, int pageSize = 50, CancellationToken cancellationToken = default)
        {
            var query = _dbSet.AsQueryable();
            if (!string.IsNullOrEmpty(notificationType)) query = query.Where(n => n.Type == notificationType);
            if (fromDate.HasValue) query = query.Where(n => n.CreatedAt >= fromDate.Value);
            if (toDate.HasValue) query = query.Where(n => n.CreatedAt <= toDate.Value);
            var items = await query
                .OrderByDescending(n => n.CreatedAt)
                .Skip((page-1)*pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);
            return items;
        }

        public async Task<bool> MarkNotificationAsReadAsync(Guid notificationId, CancellationToken cancellationToken = default)
        {
            var notif = await GetByIdAsync(notificationId, cancellationToken);
            if (notif == null) return false;
            notif.IsRead = true;
            _dbSet.Update(notif);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> MarkAllUserNotificationsAsReadAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            var list = await _dbSet.Where(n => n.RecipientId == userId && !n.IsRead).ToListAsync(cancellationToken);
            if (!list.Any()) return false;
            list.ForEach(n => n.IsRead = true);
            _dbSet.UpdateRange(list);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> DeleteNotificationAsync(Guid notificationId, CancellationToken cancellationToken = default)
        {
            var notif = await GetByIdAsync(notificationId, cancellationToken);
            if (notif == null) return false;
            _dbSet.Remove(notif);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<int> GetUnreadNotificationsCountAsync(Guid userId, CancellationToken cancellationToken = default)
            => await _dbSet.CountAsync(n => n.RecipientId == userId && !n.IsRead && !n.IsDismissed, cancellationToken);
    }
} 