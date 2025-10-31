namespace YemenBooking.Core.Interfaces.Repositories
{
    using YemenBooking.Core.Entities;
    using System;
    using System.Threading;
    using System.Threading.Tasks;
    using System.Collections.Generic;

    /// <summary>
    /// واجهة مستودع مرفقات المحادثة
    /// Chat attachments repository interface
    /// </summary>
    public interface IChatAttachmentRepository : IRepository<ChatAttachment>
    {
        /// <summary>
        /// الحصول على المرفقات في محادثة معينة
        /// Get attachments by conversation
        /// </summary>
        Task<IEnumerable<ChatAttachment>> GetAttachmentsByConversationAsync(Guid conversationId, int page, int pageSize, CancellationToken cancellationToken = default);
    }
} 