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
    /// تنفيذ مستودع مرفقات المحادثة
    /// Chat attachment repository implementation
    /// </summary>
    public class ChatAttachmentRepository : BaseRepository<ChatAttachment>, IChatAttachmentRepository
    {
        public ChatAttachmentRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<IEnumerable<ChatAttachment>> GetAttachmentsByConversationAsync(Guid conversationId, int page, int pageSize, CancellationToken cancellationToken = default)
        {
            var query = _context.Set<ChatAttachment>()
                .Where(a => a.ConversationId == conversationId);

            return await query
                .OrderByDescending(a => a.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);
        }
    }
} 