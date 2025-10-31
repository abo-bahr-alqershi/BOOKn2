using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع إعدادات الشات
    /// Chat settings repository implementation
    /// </summary>
    public class ChatSettingsRepository : BaseRepository<ChatSettings>, IChatSettingsRepository
    {
        public ChatSettingsRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<ChatSettings?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
            => await _context.Set<ChatSettings>().FirstOrDefaultAsync(s => s.UserId == userId, cancellationToken);
    }
} 