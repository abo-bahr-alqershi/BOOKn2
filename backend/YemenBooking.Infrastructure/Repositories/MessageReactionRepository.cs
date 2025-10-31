using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع تفاعلات الرسائل
    /// Message reaction repository implementation
    /// </summary>
    public class MessageReactionRepository : BaseRepository<MessageReaction>, IMessageReactionRepository
    {
        public MessageReactionRepository(YemenBookingDbContext context) : base(context) { }
    }
} 