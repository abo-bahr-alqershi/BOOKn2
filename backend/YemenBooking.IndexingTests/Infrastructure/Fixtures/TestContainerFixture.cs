using System;
using System.Threading.Tasks;
using Testcontainers.PostgreSql;
using Testcontainers.Redis;
using Xunit;
using Microsoft.Extensions.Logging;

namespace YemenBooking.IndexingTests.Infrastructure.Fixtures
{
    /// <summary>
    /// إدارة Docker containers للاختبارات
    /// يستخدم Testcontainers لإنشاء بيئة معزولة تماماً
    /// </summary>
    public class TestContainerFixture : IAsyncLifetime, IDisposable
    {
        private PostgreSqlContainer _postgresContainer;
        private RedisContainer _redisContainer;
        private readonly ILogger<TestContainerFixture> _logger;
        
        public string PostgresConnectionString { get; private set; }
        public string RedisConnectionString { get; private set; }
        public bool IsInitialized { get; private set; }
        
        public TestContainerFixture()
        {
            var loggerFactory = LoggerFactory.Create(builder => 
            {
                builder.AddConsole();
                builder.SetMinimumLevel(LogLevel.Information);
            });
            _logger = loggerFactory.CreateLogger<TestContainerFixture>();
        }
        
        /// <summary>
        /// تهيئة الحاويات
        /// </summary>
        public async Task InitializeAsync()
        {
            _logger.LogInformation("🐳 Starting test containers...");
            
            try
            {
                // إنشاء حاوية PostgreSQL
                _postgresContainer = new PostgreSqlBuilder()
                    .WithImage("postgres:15-alpine")
                    .WithDatabase("testdb")
                    .WithUsername("testuser")
                    .WithPassword("testpass")
                    .WithPortBinding(5432, true) // Random port
                    .WithCleanUp(true)
                    .Build();
                
                // إنشاء حاوية Redis
                _redisContainer = new RedisBuilder()
                    .WithImage("redis:7-alpine")
                    .WithPortBinding(6379, true) // Random port
                    .WithCleanUp(true)
                    .Build();
                
                // بدء الحاويات بالتوازي
                var startTasks = new[]
                {
                    _postgresContainer.StartAsync(),
                    _redisContainer.StartAsync()
                };
                
                await Task.WhenAll(startTasks);
                
                // الحصول على connection strings
                PostgresConnectionString = _postgresContainer.GetConnectionString();
                RedisConnectionString = _redisContainer.GetConnectionString();
                
                // التحقق من جاهزية الخدمات
                await WaitForPostgresReadyAsync();
                await WaitForRedisReadyAsync();
                
                IsInitialized = true;
                _logger.LogInformation("✅ Test containers started successfully");
                _logger.LogInformation($"📦 PostgreSQL: {PostgresConnectionString}");
                _logger.LogInformation($"📦 Redis: {RedisConnectionString}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "❌ Failed to start test containers");
                throw;
            }
        }
        
        /// <summary>
        /// إيقاف وتنظيف الحاويات
        /// </summary>
        public async Task DisposeAsync()
        {
            _logger.LogInformation("🛑 Stopping test containers...");
            
            var stopTasks = new List<Task>();
            
            if (_postgresContainer != null)
            {
                stopTasks.Add(_postgresContainer.DisposeAsync().AsTask());
            }
            
            if (_redisContainer != null)
            {
                stopTasks.Add(_redisContainer.DisposeAsync().AsTask());
            }
            
            if (stopTasks.Any())
            {
                await Task.WhenAll(stopTasks);
            }
            
            IsInitialized = false;
            _logger.LogInformation("✅ Test containers stopped");
        }
        
        public void Dispose()
        {
            DisposeAsync().GetAwaiter().GetResult();
        }
        
        /// <summary>
        /// انتظار حتى يصبح PostgreSQL جاهزاً
        /// </summary>
        private async Task WaitForPostgresReadyAsync()
        {
            var maxAttempts = 30;
            var delay = TimeSpan.FromSeconds(1);
            
            for (int i = 0; i < maxAttempts; i++)
            {
                try
                {
                    await _postgresContainer.ExecAsync(new[] { "pg_isready", "-U", "testuser" });
                    _logger.LogInformation("✅ PostgreSQL is ready");
                    return;
                }
                catch
                {
                    if (i == maxAttempts - 1)
                        throw new TimeoutException("PostgreSQL failed to become ready");
                    
                    await Task.Delay(delay);
                }
            }
        }
        
        /// <summary>
        /// انتظار حتى يصبح Redis جاهزاً
        /// </summary>
        private async Task WaitForRedisReadyAsync()
        {
            var maxAttempts = 30;
            var delay = TimeSpan.FromSeconds(1);
            
            for (int i = 0; i < maxAttempts; i++)
            {
                try
                {
                    var result = await _redisContainer.ExecAsync(new[] { "redis-cli", "ping" });
                    if (result.Stdout.Contains("PONG"))
                    {
                        _logger.LogInformation("✅ Redis is ready");
                        return;
                    }
                }
                catch
                {
                    // Continue trying
                }
                
                if (i == maxAttempts - 1)
                    throw new TimeoutException("Redis failed to become ready");
                
                await Task.Delay(delay);
            }
        }
        
        /// <summary>
        /// إعادة تعيين قاعدة البيانات
        /// </summary>
        public async Task ResetDatabaseAsync()
        {
            if (!IsInitialized)
                throw new InvalidOperationException("Containers not initialized");
            
            _logger.LogInformation("🔄 Resetting database...");
            
            // حذف وإعادة إنشاء قاعدة البيانات
            await _postgresContainer.ExecAsync(new[] 
            {
                "psql", "-U", "testuser", "-c",
                "DROP DATABASE IF EXISTS testdb; CREATE DATABASE testdb;"
            });
            
            _logger.LogInformation("✅ Database reset completed");
        }
        
        /// <summary>
        /// مسح Redis
        /// </summary>
        public async Task FlushRedisAsync()
        {
            if (!IsInitialized)
                throw new InvalidOperationException("Containers not initialized");
            
            _logger.LogInformation("🔄 Flushing Redis...");
            
            await _redisContainer.ExecAsync(new[] { "redis-cli", "FLUSHALL" });
            
            _logger.LogInformation("✅ Redis flushed");
        }
    }
    
    /// <summary>
    /// Collection fixture للمشاركة بين الاختبارات
    /// </summary>
    [CollectionDefinition("TestContainers")]
    public class TestContainerCollection : ICollectionFixture<TestContainerFixture>
    {
        // This class has no code, and is never created.
        // Its purpose is simply to be the place to apply [CollectionDefinition]
        // and all the ICollectionFixture<> interfaces.
    }
}
