namespace YemenBooking.Core.Interfaces.Repositories
{
    using YemenBooking.Core.Entities;
    using System;
    using System.Threading;
    using System.Threading.Tasks;
    using System.Collections.Generic;

    /// <summary>
    /// واجهة مستودع المحادثات
    /// Chat conversation repository interface
    /// </summary>
    public interface IChatConversationRepository : IRepository<ChatConversation>
    {
        /// <summary>
        /// الحصول على المحادثات المرتبطة بمشارك محدد
        /// Get conversations by participant
        /// </summary>
        Task<(IEnumerable<ChatConversation> Items, int TotalCount)> GetConversationsByParticipantAsync(Guid userId, int page, int pageSize, CancellationToken cancellationToken = default);

        /// <summary>
        /// الحصول على محادثة مباشرة بين مستخدمين إذا كانت موجودة
        /// Get existing direct conversation between two users if any
        /// </summary>
        Task<ChatConversation?> GetDirectConversationAsync(Guid userId1, Guid userId2, CancellationToken cancellationToken = default);

        /// <summary>
        /// جلب محادثة مع جميع التفاصيل (المشاركين والرسائل)
        /// Get conversation by id including participants and messages
        /// </summary>
        Task<ChatConversation?> GetByIdWithDetailsAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// جلب محادثة مع المشاركين فقط للتحقق من الصلاحيات بسرعة
    /// Get conversation by id including only participants for fast access checks
    /// </summary>
    Task<ChatConversation?> GetByIdWithParticipantsAsync(Guid id, CancellationToken cancellationToken = default);

        /// <summary>
        /// الحصول على المحادثات المرتبطة بعقار محدد (حساب المراسلة الخاص بالعقار)
        /// Get conversations associated with a specific property (property-level messaging account)
        /// </summary>
        Task<(IEnumerable<ChatConversation> Items, int TotalCount)> GetConversationsByPropertyAsync(Guid propertyId, int page, int pageSize, CancellationToken cancellationToken = default);

        /// <summary>
        /// التحقق من وجود محادثة سابقة بين عميل وعقار محدد
        /// Check whether a prior conversation exists between a client user and a specific property
        /// </summary>
        Task<bool> ExistsConversationBetweenClientAndPropertyAsync(Guid clientUserId, Guid propertyId, CancellationToken cancellationToken = default);
    }
} 