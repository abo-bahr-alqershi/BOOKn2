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
        private bool _initialized = false;
        private Task<bool> _initializationTask = null;
        private readonly object _initLock = new object();

        public RedisConnectionManager(IConfiguration configuration, ILogger<RedisConnectionManager> logger)
        {
            _logger = logger;
            
            var redisConfig = configuration.GetSection("Redis");
            // استخدام Connection string إذا كان موجوداً
            var connectionString = redisConfig["Connection"];
            if (!string.IsNullOrEmpty(connectionString))
            {
                _configOptions = ConfigurationOptions.Parse(connectionString);
                _configOptions.DefaultDatabase = int.Parse(redisConfig["Database"] ?? "0");
            }
            else
            {
                _configOptions = new ConfigurationOptions
                {
                    EndPoints = { redisConfig["EndPoint"] ?? "localhost:6379" },
                    Password = redisConfig["Password"],
                    DefaultDatabase = int.Parse(redisConfig["Database"] ?? "0"),
                    ConnectTimeout = 1000, // 1 ثانية فقط
                    SyncTimeout = 1000,
                    AsyncTimeout = 1000,
                    KeepAlive = 60,
                    ConnectRetry = 1, // محاولة واحدة فقط
                    ReconnectRetryPolicy = new LinearRetry(1000), // فترة قصيرة
                    AbortOnConnectFail = false,
                    AllowAdmin = false // لا حاجة لصلاحيات admin في الاختبارات
                };
            }

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

            // لا نقوم بالاتصال في المُنشئ
            _logger.LogInformation("✅ RedisConnectionManager created (lazy connection)");
        }

        private async Task<bool> EnsureConnectedAsync()
        {
            if (_initialized && _connection != null && _connection.IsConnected)
                return true;

            // استخدام lock للتأكد من أن مهمة التهيئة تبدأ مرة واحدة فقط
            lock (_initLock)
            {
                if (_initializationTask == null)
                {
                    _initializationTask = InitializeConnectionWithLockAsync();
                }
            }

            return await _initializationTask;
        }

        private async Task<bool> InitializeConnectionWithLockAsync()
        {
            await _connectionLock.WaitAsync();
            try
            {
                if (_initialized && _connection != null && _connection.IsConnected)
                    return true;

                return await InitializeConnectionAsync();
            }
            finally
            {
                _connectionLock.Release();
            }
        }

        private async Task<bool> InitializeConnectionAsync()
        {
            try
            {
                _logger.LogInformation("🔌 محاولة الاتصال بـ Redis...");
                
                // محاولة الاتصال بشكل غير متزامن مع timeout
                var connectTask = ConnectionMultiplexer.ConnectAsync(_configOptions);
                var timeoutTask = Task.Delay(3000);
                
                var completedTask = await Task.WhenAny(connectTask, timeoutTask);
                
                if (completedTask == timeoutTask)
                {
                    _logger.LogWarning("⚠️ انتهى وقت الاتصال بـ Redis (3 ثواني)");
                    _initialized = false;
                    return false;
                }
                
                _connection = await connectTask;
                
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

                _logger.LogInformation("✅ تم إنشاء اتصال Redis بنجاح");
                _initialized = true;
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "⚠️ فشل في إنشاء اتصال Redis");
                _initialized = false;
                return false;
            }
        }

        public IDatabase GetDatabase(int db = -1)
        {
            // التحقق من الاتصال بشكل آمن دون حجب
            if (_initialized && _connection != null && _connection.IsConnected)
            {
                return _connection.GetDatabase(db);
            }
            
            // محاولة الاتصال بشكل غير متزامن مع timeout قصير
            var task = Task.Run(async () => await EnsureConnectedAsync());
            if (task.Wait(TimeSpan.FromSeconds(2)))
            {
                if (task.Result && _connection != null)
                {
                    return _connection.GetDatabase(db);
                }
            }
            
            throw new InvalidOperationException("Unable to connect to Redis within timeout");
        }

        public ISubscriber GetSubscriber()
        {
            // التحقق من الاتصال بشكل آمن دون حجب
            if (_initialized && _connection != null && _connection.IsConnected)
            {
                return _connection.GetSubscriber();
            }
            
            // محاولة الاتصال بشكل غير متزامن مع timeout قصير
            var task = Task.Run(async () => await EnsureConnectedAsync());
            if (task.Wait(TimeSpan.FromSeconds(2)))
            {
                if (task.Result && _connection != null)
                {
                    return _connection.GetSubscriber();
                }
            }
            
            throw new InvalidOperationException("Unable to connect to Redis within timeout");
        }

        public IServer GetServer()
        {
            // التحقق من الاتصال بشكل آمن دون حجب
            if (_initialized && _connection != null && _connection.IsConnected)
            {
                var endpoints = _connection.GetEndPoints();
                return _connection.GetServer(endpoints[0]);
            }
            
            // محاولة الاتصال بشكل غير متزامن مع timeout قصير
            var task = Task.Run(async () => await EnsureConnectedAsync());
            if (task.Wait(TimeSpan.FromSeconds(2)))
            {
                if (task.Result && _connection != null)
                {
                    var endpoints = _connection.GetEndPoints();
                    return _connection.GetServer(endpoints[0]);
                }
            }
            
            throw new InvalidOperationException("Unable to connect to Redis within timeout");
        }

        public async Task<bool> IsConnectedAsync()
        {
            try
            {
                // محاولة الاتصال إذا لم يكن متصلاً
                return await EnsureConnectedAsync();
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

        // حذفت EnsureConnection القديمة واستبدلت بـ EnsureConnectedAsync

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