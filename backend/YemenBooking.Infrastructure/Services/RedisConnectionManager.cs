// RedisConnectionManager.cs
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using Polly;
using Polly.CircuitBreaker;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services
{

    public class RedisConnectionManager : IRedisConnectionManager, IDisposable
    {
        private readonly ILogger<RedisConnectionManager> _logger;
        private readonly ConfigurationOptions _configOptions;
        private readonly SemaphoreSlim _connectionLock = new(1, 1);
        private IConnectionMultiplexer _connection;
        private readonly IAsyncPolicy _retryPolicy;
        private bool _disposed;

        public RedisConnectionManager(IConfiguration configuration, ILogger<RedisConnectionManager> logger)
        {
            _logger = logger;
            
            var redisConfig = configuration.GetSection("Redis");
            _configOptions = new ConfigurationOptions
            {
                EndPoints = { redisConfig["EndPoint"] ?? "localhost:6379" },
                Password = redisConfig["Password"],
                DefaultDatabase = int.Parse(redisConfig["Database"] ?? "0"),
                ConnectTimeout = 5000,
                SyncTimeout = 5000,
                AsyncTimeout = 5000,
                KeepAlive = 60,
                ConnectRetry = 3,
                ReconnectRetryPolicy = new ExponentialRetry(5000),
                AbortOnConnectFail = false,
                AllowAdmin = true
            };

            // إعداد سياسة إعادة المحاولة مع Circuit Breaker
            _retryPolicy = Policy
                .Handle<RedisConnectionException>()
                .Or<RedisTimeoutException>()
                .Or<RedisCommandException>()
                .WaitAndRetryAsync(
                    3,
                    retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                    onRetry: (outcome, timespan, retryCount, context) =>
                    {
                        _logger.LogWarning(
                            "محاولة إعادة الاتصال بـ Redis #{RetryCount} بعد {Timespan}ms",
                            retryCount, timespan.TotalMilliseconds);
                    })
                .WrapAsync(
                    Policy.Handle<Exception>()
                        .CircuitBreakerAsync(
                            3, 
                            TimeSpan.FromMinutes(1),
                            onBreak: (exception, duration) =>
                            {
                                _logger.LogError(exception,
                                    "فتح دائرة القاطع لـ Redis لمدة {Duration}",
                                    duration);
                            },
                            onReset: () =>
                            {
                                _logger.LogInformation("إعادة تعيين دائرة القاطع لـ Redis");
                            }));

            InitializeConnection();
        }

        private void InitializeConnection()
        {
            try
            {
                _connection = ConnectionMultiplexer.Connect(_configOptions);
                
                _connection.ConnectionFailed += (sender, args) =>
                {
                    _logger.LogError("فشل اتصال Redis: {FailureType}", args.FailureType);
                };

                _connection.ConnectionRestored += (sender, args) =>
                {
                    _logger.LogInformation("تم استعادة اتصال Redis");
                };

                _connection.ErrorMessage += (sender, args) =>
                {
                    var msg = args.Message ?? string.Empty;
                    if (msg.Contains("Another child process is active", StringComparison.OrdinalIgnoreCase)
                        || msg.Contains("can't BGSAVE right now", StringComparison.OrdinalIgnoreCase))
                    {
                        // هذه رسالة متوقعة عند جدولة الحفظ أثناء عمليات AOF/حفظ أخرى
                        _logger.LogDebug("Redis notice: {Message}", args.Message);
                    }
                    else
                    {
                        _logger.LogError("خطأ Redis: {Message}", args.Message);
                    }
                };

                _logger.LogInformation("تم تأسيس اتصال Redis بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "فشل في تأسيس اتصال Redis");
                throw;
            }
        }

        public IDatabase GetDatabase(int db = -1)
        {
            EnsureConnection();
            return _connection.GetDatabase(db);
        }

        public ISubscriber GetSubscriber()
        {
            EnsureConnection();
            return _connection.GetSubscriber();
        }

        public IServer GetServer()
        {
            EnsureConnection();
            var endpoints = _connection.GetEndPoints();
            return _connection.GetServer(endpoints[0]);
        }

        public async Task<bool> IsConnectedAsync()
        {
            try
            {
                if (_connection == null || !_connection.IsConnected)
                    return false;

                var db = GetDatabase();
                await db.PingAsync();
                return true;
            }
            catch
            {
                return false;
            }
        }

        public async Task FlushDatabaseAsync(int db = -1)
        {
            var server = GetServer();
            await server.FlushDatabaseAsync(db == -1 ? _configOptions.DefaultDatabase ?? 0 : db);
            _logger.LogInformation("تم مسح قاعدة بيانات Redis {Database}", db);
        }

        private void EnsureConnection()
        {
            if (_connection != null && _connection.IsConnected)
                return;

            _connectionLock.Wait();
            try
            {
                if (_connection == null || !_connection.IsConnected)
                {
                    _connection?.Dispose();
                    InitializeConnection();
                }
            }
            finally
            {
                _connectionLock.Release();
            }
        }

        public void Dispose()
        {
            if (_disposed)
                return;

            _connection?.Dispose();
            _connectionLock?.Dispose();
            _disposed = true;
        }
    }
}