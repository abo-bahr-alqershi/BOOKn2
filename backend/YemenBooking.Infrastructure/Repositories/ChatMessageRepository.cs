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
    /// تنفيذ مستودع رسائل المحادثة
    /// Chat message repository implementation
    /// </summary>
    public class ChatMessageRepository : BaseRepository<ChatMessage>, IChatMessageRepository
    {
        public ChatMessageRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<(IEnumerable<ChatMessage> Items, int TotalCount)> GetMessagesByConversationAsync(Guid conversationId, int page, int pageSize, string? beforeMessageId = null, CancellationToken cancellationToken = default)
        {
            var query = _context.Set<ChatMessage>()
                .Include(m => m.Reactions)
                .Include(m => m.Attachments)
                .Where(m => m.ConversationId == conversationId);

            if (!string.IsNullOrEmpty(beforeMessageId) && Guid.TryParse(beforeMessageId, out var beforeId))
            {
                var beforeMsg = await GetByIdAsync(beforeId, cancellationToken);
                if (beforeMsg != null)
                {
                    query = query.Where(m => m.CreatedAt < beforeMsg.CreatedAt);
                }
            }

            var total = await query.CountAsync(cancellationToken);
            var items = await query
                .OrderByDescending(m => m.CreatedAt)
                .ThenByDescending(m => m.Id)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            return (items, total);
        }
    }
} 