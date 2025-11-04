using System;
using System.Threading.Tasks;
using StackExchange.Redis;

namespace YemenBooking.Infrastructure.Redis.Core.Interfaces
{
    /// <summary>
    /// واجهة إدارة اتصال Redis
    /// </summary>
    public interface IRedisConnectionManager : IDisposable
    {
        /// <summary>
        /// الحصول على قاعدة بيانات Redis
        /// </summary>
        IDatabase GetDatabase(int db = -1);

        /// <summary>
        /// الحصول على Subscriber
        /// </summary>
        ISubscriber GetSubscriber();

        /// <summary>
        /// الحصول على Server
        /// </summary>
        IServer GetServer();

        /// <summary>
        /// التحقق من الاتصال
        /// </summary>
        Task<bool> IsConnectedAsync();

        /// <summary>
        /// إعادة الاتصال
        /// </summary>
        Task ReconnectAsync();

        /// <summary>
        /// الحصول على معلومات الاتصال
        /// </summary>
        ConnectionInfo GetConnectionInfo();
    }

    /// <summary>
    /// معلومات الاتصال
    /// </summary>
    public class ConnectionInfo
    {
        public bool IsConnected { get; set; }
        public string Endpoint { get; set; }
        public TimeSpan ResponseTime { get; set; }
        public long TotalConnections { get; set; }
        public long FailedConnections { get; set; }
        public DateTime LastReconnectTime { get; set; }
    }
}
