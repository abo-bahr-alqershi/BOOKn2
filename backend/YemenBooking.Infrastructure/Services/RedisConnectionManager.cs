// RedisConnectionManager.cs
using System;
using System.Linq;
using System.Net;
using System.Net.Sockets;
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
        private readonly bool _enabled = true;

        public RedisConnectionManager(IConfiguration configuration, ILogger<RedisConnectionManager> logger)
        {
            _logger = logger;
            
            var redisConfig = configuration.GetSection("Redis");
            _enabled = redisConfig.GetValue<bool>("Enabled", true);
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
                    AllowAdmin = redisConfig.GetValue<bool>("AllowAdmin", true) // السماح بعمليات admin للاختبارات (KEYS, SCRIPT LOAD)
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
            _logger.LogInformation("✅ RedisConnectionManager created (lazy connection), Enabled={Enabled}", _enabled);
        }

        private async Task<bool> EnsureConnectedAsync()
        {
            if (!_enabled)
            {
                _initialized = false;
                return false;
            }
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
                
                // Fast DNS pre-check to fail early on invalid hosts
                try
                {
                    var ep = _configOptions.EndPoints?.FirstOrDefault();
                    if (ep != null)
                    {
                        var hostPort = ep.ToString(); // e.g., host:port
                        var host = hostPort;
                        var colonIdx = hostPort.LastIndexOf(':');
                        if (colonIdx > 0)
                            host = hostPort.Substring(0, colonIdx);
                        var port = 6379;
                        if (colonIdx > 0)
                        {
                            int.TryParse(hostPort.Substring(colonIdx + 1), out port);
                        }

                        // Skip common local addresses
                        if (!string.Equals(host, "localhost", StringComparison.OrdinalIgnoreCase) &&
                            !string.Equals(host, "127.0.0.1", StringComparison.OrdinalIgnoreCase))
                        {
                            var dnsTask = Dns.GetHostEntryAsync(host);
                            var dnsCompleted = await Task.WhenAny(dnsTask, Task.Delay(1000));
                            if (dnsCompleted != dnsTask)
                            {
                                _logger.LogWarning("DNS resolution timeout for host {Host}", host);
                                _initialized = false;
                                return false;
                            }
                            // If DNS throws, catch below
                            _ = dnsTask.Result;
                        }

                        // Quick TCP connectivity probe (skip for localhost to avoid false negatives)
                        if (!string.Equals(host, "localhost", StringComparison.OrdinalIgnoreCase) &&
                            !string.Equals(host, "127.0.0.1", StringComparison.OrdinalIgnoreCase))
                        {
                            try
                            {
                                using var tcp = new TcpClient();
                                var tcpConnectTask = tcp.ConnectAsync(host, port);
                                var delayTask = Task.Delay(500);
                                var completed = await Task.WhenAny(tcpConnectTask, delayTask);
                                if (completed == delayTask)
                                {
                                    _logger.LogWarning("TCP connectivity probe timeout for {Host}:{Port}", host, port);
                                    _initialized = false;
                                    return false;
                                }
                                if (tcpConnectTask.IsFaulted || !tcp.Connected)
                                {
                                    _logger.LogWarning("TCP connectivity probe failed for {Host}:{Port}", host, port);
                                    _initialized = false;
                                    return false;
                                }
                            }
                            catch (Exception tcpEx)
                            {
                                _logger.LogWarning(tcpEx, "TCP connectivity probe threw for {Host}:{Port}", host, port);
                                _initialized = false;
                                return false;
                            }
                        }
                    }
                }
                catch (Exception dnsEx)
                {
                    _logger.LogWarning(dnsEx, "DNS resolution failed for configured Redis endpoint");
                    _initialized = false;
                    return false;
                }
                
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

                // Validate actual connectivity: with AbortOnConnectFail=false ConnectAsync may succeed while not connected
                if (_connection == null || !_connection.IsConnected)
                {
                    _logger.LogWarning("Redis multiplexer created but not connected");
                    _initialized = false;
                    try
                    {
                        _connection?.Dispose();
                    }
                    catch { }
                    return false;
                }

                // Optional quick ping validation to ensure connectivity is working
                try
                {
                    var db = _connection.GetDatabase();
                    var ping = await db.PingAsync();
                    _logger.LogDebug("Redis ping: {PingMs}ms", ping.TotalMilliseconds);

                    // Ensure we have at least one reachable server endpoint and it responds
                    var endpoints = _connection.GetEndPoints();
                    if (endpoints == null || endpoints.Length == 0)
                    {
                        _logger.LogWarning("No endpoints returned by multiplexer");
                        _initialized = false;
                        try { _connection?.Dispose(); } catch { }
                        return false;
                    }

                    try
                    {
                        var server = _connection.GetServer(endpoints[0]);
                        await server.PingAsync();
                    }
                    catch (Exception serverPingEx)
                    {
                        _logger.LogWarning(serverPingEx, "Redis server ping failed after connect");
                        _initialized = false;
                        try { _connection?.Dispose(); } catch { }
                        return false;
                    }
                }
                catch (Exception pingEx)
                {
                    _logger.LogWarning(pingEx, "Redis ping failed after connect");
                    _initialized = false;
                    try { _connection?.Dispose(); } catch { }
                    return false;
                }

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
            if (!_enabled)
                throw new InvalidOperationException("Redis is disabled by configuration");
            // التحقق من الاتصال بشكل آمن دون حجب
            if (_initialized && _connection != null && _connection.IsConnected)
            {
                return _connection.GetDatabase(db);
            }
            
            // محاولة الاتصال بشكل غير متزامن مع timeout قصير
            var task = Task.Run(async () => await EnsureConnectedAsync());
            if (task.Wait(TimeSpan.FromSeconds(5)))
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
            if (!_enabled)
                throw new InvalidOperationException("Redis is disabled by configuration");
            // التحقق من الاتصال بشكل آمن دون حجب
            if (_initialized && _connection != null && _connection.IsConnected)
            {
                return _connection.GetSubscriber();
            }
            
            // محاولة الاتصال بشكل غير متزامن مع timeout قصير
            var task = Task.Run(async () => await EnsureConnectedAsync());
            if (task.Wait(TimeSpan.FromSeconds(5)))
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
            if (!_enabled)
                throw new InvalidOperationException("Redis is disabled by configuration");
            // التحقق من الاتصال بشكل آمن دون حجب
            if (_initialized && _connection != null && _connection.IsConnected)
            {
                var endpoints = _connection.GetEndPoints();
                return _connection.GetServer(endpoints[0]);
            }
            
            // محاولة الاتصال بشكل غير متزامن مع timeout قصير
            var task = Task.Run(async () => await EnsureConnectedAsync());
            if (task.Wait(TimeSpan.FromSeconds(5)))
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
                // Ensure connection is initialized
                var ok = await EnsureConnectedAsync();
                if (!ok || _connection == null || !_connection.IsConnected)
                    return false;

                // Quick ping to validate actual connectivity
                try
                {
                    var db = _connection.GetDatabase();
                    var ping = await db.PingAsync();
                    _logger.LogDebug("IsConnected check ping: {Ms}ms", ping.TotalMilliseconds);
                    return true;
                }
                catch
                {
                    return false;
                }
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