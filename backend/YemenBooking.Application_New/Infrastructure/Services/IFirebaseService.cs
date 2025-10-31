using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;

namespace YemenBooking.Application.Infrastructure.Services
{
    /// <summary>
    /// واجهة خدمة Firebase للإشعارات
    /// Firebase notification service interface
    /// </summary>
    public interface IFirebaseService
    {
        /// <summary>
        /// إرسال إشعار عبر Firebase
        /// Send notification via Firebase to a specified topic or token
        /// </summary>
        Task<bool> SendNotificationAsync(
            string topicOrToken,
            string title,
            string body,
            IReadOnlyDictionary<string, string>? data = null,
            CancellationToken cancellationToken = default);
    }
} 