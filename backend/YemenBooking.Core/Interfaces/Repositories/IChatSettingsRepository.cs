namespace YemenBooking.Core.Interfaces.Repositories
{
    using YemenBooking.Core.Entities;
    using System;
    using System.Threading;
    using System.Threading.Tasks;

    /// <summary>
    /// واجهة مستودع إعدادات الشات
    /// Chat settings repository interface
    /// </summary>
    public interface IChatSettingsRepository : IRepository<ChatSettings>
    {
        /// <summary>
        /// الحصول على إعدادات الشات الخاصة بمستخدم
        /// Get chat settings by user ID
        /// </summary>
        Task<ChatSettings?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);
    }
} 