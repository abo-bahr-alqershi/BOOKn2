using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using Polly;
using Polly.CircuitBreaker;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;

namespace YemenBooking.Infrastructure.Redis.Core
{
    /// <summary>
    /// مدير اتصال Redis مع تطبيق مبادئ العزل والمرونة
    /// </summary>
    public sealed class RedisConnectionManager : IRedisConnectionManager
    {
        private readonly ILogger<RedisConnectionManager> _logger;
        private readonly IConfiguration _configuration;
        private readonly SemaphoreSlim _connectionLock;
        private readonly IAsyncPolicy<IConnectionMultiplexer> _reconnectPolicy;
        private IConnectionMultiplexer _connection;
        private readonly ConnectionInfo _connectionInfo;
        private bool _disposed;

        public RedisConnectionManager(
            ILogger<RedisConnectionManager> logger,
            IConfiguration configuration)
        {
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            _configuration = configuration ?? throw new ArgumentNullException(nameof(configuration));
            _connectionLock = new SemaphoreSlim(1, 1);
            _connectionInfo = new ConnectionInfo();
            
            // إعداد سياسة إعادة الاتصال
            _reconnectPolicy = Policy<IConnectionMultiplexer>
                .Handle<RedisConnectionException>()
                .Or<RedisTimeoutException>()
                .Or<ObjectDisposedException>()
                .WaitAndRetryAsync(
                    3,
                    retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                    onRetry: (outcome, timespan, retryCount, context) =>
                    {
                        _logger.LogWarning(
                            "Retry {RetryCount} after {TimeSpan}ms to connect to Redis",
                            retryCount, timespan.TotalMilliseconds);
                    });
        }

        /// <summary>
        /// الحصول على قاعدة بيانات Redis
        /// </summary>
        public IDatabase GetDatabase(int db = -1)
        {
            EnsureConnected();
            return _connection.GetDatabase(db);
        }

        /// <summary>
        /// الحصول على Subscriber
        /// </summary>
        public ISubscriber GetSubscriber()
        {
            EnsureConnected();
            return _connection.GetSubscriber();
        }

        /// <summary>
        /// الحصول على Server
        /// </summary>
        public IServer GetServer()
        {
            EnsureConnected();
            var endpoints = _connection.GetEndPoints();
            if (endpoints.Length == 0)
            {
                throw new InvalidOperationException("No Redis endpoints configured");
            }
            return _connection.GetServer(endpoints[0]);
        }

        /// <summary>
        /// التحقق من الاتصال
        /// </summary>
        public async Task<bool> IsConnectedAsync()
        {
            try
            {
                if (_connection == null || !_connection.IsConnected)
                {
                    return false;
                }

                // اختبار الاتصال الفعلي
                var db = GetDatabase();
                await db.PingAsync();
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Redis connection check failed");
                return false;
            }
        }

        /// <summary>
        /// إعادة الاتصال
        /// </summary>
        public async Task ReconnectAsync()
        {
            await _connectionLock.WaitAsync();
            try
            {
                _logger.LogInformation("Attempting to reconnect to Redis");
                
                // إغلاق الاتصال القديم
                if (_connection != null)
                {
                    try
                    {
                        await _connection.CloseAsync();
                        _connection.Dispose();
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning(ex, "Error closing old Redis connection");
                    }
                }

                // إنشاء اتصال جديد
                _connection = await ConnectAsync();
                _connectionInfo.LastReconnectTime = DateTime.UtcNow;
                _connectionInfo.IsConnected = true;
                
                _logger.LogInformation("Successfully reconnected to Redis");
            }
            catch (Exception ex)
            {
                _connectionInfo.FailedConnections++;
                _connectionInfo.IsConnected = false;
                _logger.LogError(ex, "Failed to reconnect to Redis");
                throw;
            }
            finally
            {
                _connectionLock.Release();
            }
        }

        /// <summary>
        /// الحصول على معلومات الاتصال
        /// </summary>
        public ConnectionInfo GetConnectionInfo()
        {
            return new ConnectionInfo
            {
                IsConnected = _connection?.IsConnected ?? false,
                Endpoint = _connectionInfo.Endpoint,
                ResponseTime = _connectionInfo.ResponseTime,
                TotalConnections = _connectionInfo.TotalConnections,
                FailedConnections = _connectionInfo.FailedConnections,
                LastReconnectTime = _connectionInfo.LastReconnectTime
            };
        }

        /// <summary>
        /// التأكد من وجود اتصال
        /// </summary>
        private void EnsureConnected()
        {
            if (_disposed)
            {
                throw new ObjectDisposedException(nameof(RedisConnectionManager));
            }

            if (_connection == null || !_connection.IsConnected)
            {
                _connectionLock.Wait();
                try
                {
                    if (_connection == null || !_connection.IsConnected)
                    {
                        _connection = ConnectAsync().GetAwaiter().GetResult();
                    }
                }
                finally
                {
                    _connectionLock.Release();
                }
            }
        }

        /// <summary>
        /// إنشاء اتصال جديد
        /// </summary>
        private async Task<IConnectionMultiplexer> ConnectAsync()
        {
            var connectionString = _configuration.GetConnectionString("Redis") 
                ?? "localhost:6379";

            var options = ConfigurationOptions.Parse(connectionString);
            
            // تكوين خيارات الاتصال
            options.AbortOnConnectFail = false;
            options.ConnectRetry = 3;
            options.ConnectTimeout = 5000;
            options.SyncTimeout = 5000;
            options.AsyncTimeout = 5000;
            options.KeepAlive = 60;
            options.ReconnectRetryPolicy = new ExponentialRetry(5000);
            
            // إضافة معالجات الأحداث
            var connection = await _reconnectPolicy.ExecuteAsync(async () =>
            {
                _logger.LogInformation("Connecting to Redis at {Endpoint}", connectionString);
                
                var conn = await ConnectionMultiplexer.ConnectAsync(options);
                
                // تسجيل الأحداث
                conn.ConnectionFailed += OnConnectionFailed;
                conn.ConnectionRestored += OnConnectionRestored;
                conn.ErrorMessage += OnErrorMessage;
                conn.InternalError += OnInternalError;
                
                _connectionInfo.TotalConnections++;
                _connectionInfo.Endpoint = connectionString;
                
                return conn;
            });

            _logger.LogInformation("Successfully connected to Redis");
            return connection;
        }

        /// <summary>
        /// معالج فشل الاتصال
        /// </summary>
        private void OnConnectionFailed(object sender, ConnectionFailedEventArgs e)
        {
            _connectionInfo.FailedConnections++;
            _connectionInfo.IsConnected = false;
            _logger.LogError(e.Exception, 
                "Redis connection failed. Endpoint: {Endpoint}, FailureType: {FailureType}", 
                e.EndPoint, e.FailureType);
        }

        /// <summary>
        /// معالج استعادة الاتصال
        /// </summary>
        private void OnConnectionRestored(object sender, ConnectionFailedEventArgs e)
        {
            _connectionInfo.IsConnected = true;
            _logger.LogInformation(
                "Redis connection restored. Endpoint: {Endpoint}", 
                e.EndPoint);
        }

        /// <summary>
        /// معالج رسائل الخطأ
        /// </summary>
        private void OnErrorMessage(object sender, RedisErrorEventArgs e)
        {
            _logger.LogError("Redis error: {Message} from {EndPoint}", 
                e.Message, e.EndPoint);
        }

        /// <summary>
        /// معالج الأخطاء الداخلية
        /// </summary>
        private void OnInternalError(object sender, InternalErrorEventArgs e)
        {
            _logger.LogError(e.Exception, 
                "Redis internal error: {Origin}", e.Origin);
        }

        /// <summary>
        /// التخلص من الموارد
        /// </summary>
        public void Dispose()
        {
            if (_disposed) return;

            _disposed = true;

            try
            {
                if (_connection != null)
                {
                    _connection.ConnectionFailed -= OnConnectionFailed;
                    _connection.ConnectionRestored -= OnConnectionRestored;
                    _connection.ErrorMessage -= OnErrorMessage;
                    _connection.InternalError -= OnInternalError;
                    
                    _connection.Close();
                    _connection.Dispose();
                }

                _connectionLock?.Dispose();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error disposing Redis connection manager");
            }
        }
    }
}
