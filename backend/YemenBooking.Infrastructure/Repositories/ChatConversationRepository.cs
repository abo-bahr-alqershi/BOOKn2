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
    /// تنفيذ مستودع المحادثات
    /// Chat conversation repository implementation
    /// </summary>
    public class ChatConversationRepository : BaseRepository<ChatConversation>, IChatConversationRepository
    {
        public ChatConversationRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<(IEnumerable<ChatConversation> Items, int TotalCount)> GetConversationsByParticipantAsync(Guid userId, int page, int pageSize, CancellationToken cancellationToken = default)
        {
            var query = _context.Set<ChatConversation>()
                .Include(c => c.Participants)
                .Include(c => c.Messages)
                .Where(c => c.Participants.Any(p => p.Id == userId));

            var total = await query.CountAsync(cancellationToken);
            // Sort by last activity time: prefer last message time if available
            var items = await query
                .OrderByDescending(c => c.Messages.Max(m => (DateTime?)m.CreatedAt) ?? c.UpdatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            return (items, total);
        }

        public async Task<ChatConversation?> GetDirectConversationAsync(Guid userId1, Guid userId2, CancellationToken cancellationToken = default)
        {
            return await _context.Set<ChatConversation>()
                .Include(c => c.Participants)
                .Include(c => c.Messages)
                .ThenInclude(m => m.Sender)
                .Where(c => c.ConversationType == "direct"
                            && c.Participants.Any(p => p.Id == userId1)
                            && c.Participants.Any(p => p.Id == userId2))
                .OrderByDescending(c => c.UpdatedAt)
                .FirstOrDefaultAsync(cancellationToken);
        }

        public async Task<ChatConversation?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return await _context.Set<ChatConversation>()
                .Include(c => c.Participants)
                .ThenInclude(p => p.Properties) // إضافة خصائص المستخدم إذا لزم
                .Include(c => c.Messages)
                .ThenInclude(m => m.Sender) // إضافة معلومات المرسل
                .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
        }

        public async Task<ChatConversation?> GetByIdWithParticipantsAsync(Guid id, CancellationToken cancellationToken = default)
        {
            return await _context.Set<ChatConversation>()
                .Include(c => c.Participants)
                .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
        }

        public async Task<(IEnumerable<ChatConversation> Items, int TotalCount)> GetConversationsByPropertyAsync(Guid propertyId, int page, int pageSize, CancellationToken cancellationToken = default)
        {
            var query = _context.Set<ChatConversation>()
                .Include(c => c.Participants)
                .Include(c => c.Messages)
                .Where(c => c.PropertyId.HasValue && c.PropertyId.Value == propertyId);

            var total = await query.CountAsync(cancellationToken);
            var items = await query
                .OrderByDescending(c => c.UpdatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            return (items, total);
        }

        public async Task<bool> ExistsConversationBetweenClientAndPropertyAsync(Guid clientUserId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<ChatConversation>()
                .AsNoTracking()
                .AnyAsync(c => c.PropertyId.HasValue && c.PropertyId.Value == propertyId
                               && c.Participants.Any(p => p.Id == clientUserId), cancellationToken);
        }
    }
} 