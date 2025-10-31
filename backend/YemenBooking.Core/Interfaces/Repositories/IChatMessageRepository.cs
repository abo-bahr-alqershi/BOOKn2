namespace YemenBooking.Core.Interfaces.Repositories
{
    using YemenBooking.Core.Entities;
    using System;
    using System.Threading;
    using System.Threading.Tasks;
    using System.Collections.Generic;

    /// <summary>
    /// واجهة مستودع رسائل المحادثة
    /// Chat message repository interface
    /// </summary>
    public interface IChatMessageRepository : IRepository<ChatMessage>
    {
        /// <summary>
        /// الحصول على الرسائل في محادثة معينة
        /// Get messages by conversation
        /// </summary>
        Task<(IEnumerable<ChatMessage> Items, int TotalCount)> GetMessagesByConversationAsync(Guid conversationId, int page, int pageSize, string? beforeMessageId = null, CancellationToken cancellationToken = default);
    }
} 