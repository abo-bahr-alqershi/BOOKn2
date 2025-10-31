namespace YemenBooking.Core.Interfaces.Repositories
{
    using YemenBooking.Core.Entities;

    /// <summary>
    /// واجهة مستودع تفاعلات الرسائل
    /// Message reaction repository interface
    /// </summary>
    public interface IMessageReactionRepository : IRepository<MessageReaction>
    {
        // يمكن إضافة طرق مخصصة إذا لزم الأمر
    }
} 