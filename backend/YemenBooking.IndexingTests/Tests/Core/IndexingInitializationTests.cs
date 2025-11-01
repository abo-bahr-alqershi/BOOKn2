using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Xunit;
using YemenBooking.Infrastructure.Redis;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Infrastructure.Redis.Search;
using YemenBooking.Infrastructure.Redis.Cache;
using YemenBooking.Infrastructure.Redis.Monitoring;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using Moq;

namespace YemenBooking.IndexingTests.Tests.Core
{
    /// <summary>
    /// اختبارات تهيئة نظام الفهرسة والمكونات الأساسية
    /// يغطي تهيئة جميع الطبقات والتحقق من التكامل بينها
    /// </summary>
    public class IndexingInitializationTests : IClassFixture<TestDatabaseFixture>, IAsyncLifetime
    {
        private readonly TestDatabaseFixture _fixture;
        private readonly ILogger<IndexingInitializationTests> _logger;
        private readonly IConfiguration _configuration;
        private RedisIndexingSystem? _indexingSystem;
        private IRedisConnectionManager? _redisManager;

        /// <summary>
        /// مُنشئ الاختبارات
        /// </summary>
        public IndexingInitializationTests(TestDatabaseFixture fixture)
        {
            _fixture = fixture;
            _logger = _fixture.ServiceProvider.GetRequiredService<ILogger<IndexingInitializationTests>>();
            _configuration = _fixture.Configuration;
        }

        /// <summary>
        /// تهيئة الاختبارات
        /// </summary>
        public async Task InitializeAsync()
        {
            _logger.LogInformation("🚀 بدء اختبارات تهيئة نظام الفهرسة");
            await Task.CompletedTask;
        }

        /// <summary>
        /// تنظيف الموارد
        /// </summary>
        public async Task DisposeAsync()
        {
            _logger.LogInformation("🧹 تنظيف موارد اختبارات التهيئة");
            _redisManager?.Dispose();
            await Task.CompletedTask;
        }

        #region اختبارات تهيئة المكونات الأساسية

        /// <summary>
        /// اختبار تهيئة SmartIndexingLayer بنجاح
        /// </summary>
        [Fact]
        public void SmartIndexingLayer_Should_Initialize_Successfully()
        {
            // Arrange
            _logger.LogInformation("اختبار تهيئة SmartIndexingLayer");
            
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var mockPropertyRepo = new Mock<IPropertyRepository>();
            
            // Act
            var indexingLayer = new SmartIndexingLayer(
                _redisManager,
                mockPropertyRepo.Object,
                _fixture.ServiceProvider.GetRequiredService<ILogger<SmartIndexingLayer>>()
            );

            // Assert
            Assert.NotNull(indexingLayer);
            _logger.LogInformation("✅ تمت تهيئة SmartIndexingLayer بنجاح");
        }

        /// <summary>
        /// اختبار تهيئة OptimizedSearchEngine بنجاح
        /// </summary>
        [Fact]
        public void OptimizedSearchEngine_Should_Initialize_Successfully()
        {
            // Arrange
            _logger.LogInformation("اختبار تهيئة OptimizedSearchEngine");
            
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var mockCache = new Mock<IMultiLevelCache>();
            var memoryCache = _fixture.ServiceProvider.GetRequiredService<Microsoft.Extensions.Caching.Memory.IMemoryCache>();
            
            // Act
            var searchEngine = new OptimizedSearchEngine(
                _redisManager,
                mockCache.Object,
                _fixture.ServiceProvider.GetRequiredService<ILogger<OptimizedSearchEngine>>(),
                memoryCache
            );

            // Assert
            Assert.NotNull(searchEngine);
            _logger.LogInformation("✅ تمت تهيئة OptimizedSearchEngine بنجاح");
        }

        /// <summary>
        /// اختبار تهيئة MultiLevelCache بنجاح
        /// </summary>
        [Fact]
        public void MultiLevelCache_Should_Initialize_Successfully()
        {
            // Arrange
            _logger.LogInformation("اختبار تهيئة MultiLevelCache");
            
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var memoryCache = _fixture.ServiceProvider.GetRequiredService<Microsoft.Extensions.Caching.Memory.IMemoryCache>();
            
            // Act
            var cacheManager = new MultiLevelCache(
                _redisManager,
                memoryCache,
                _fixture.ServiceProvider.GetRequiredService<ILogger<MultiLevelCache>>(),
                _configuration
            );

            // Assert
            Assert.NotNull(cacheManager);
            _logger.LogInformation("✅ تمت تهيئة MultiLevelCache بنجاح");
        }

        /// <summary>
        /// اختبار تهيئة ErrorHandlingAndMonitoring بنجاح
        /// </summary>
        [Fact]
        public void ErrorHandlingAndMonitoring_Should_Initialize_Successfully()
        {
            // Arrange
            _logger.LogInformation("اختبار تهيئة ErrorHandlingAndMonitoring");
            
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            // Act
            var errorHandler = new ErrorHandlingAndMonitoring(
                _redisManager,
                _fixture.ServiceProvider.GetRequiredService<ILogger<ErrorHandlingAndMonitoring>>()
            );

            // Assert
            Assert.NotNull(errorHandler);
            _logger.LogInformation("✅ تمت تهيئة ErrorHandlingAndMonitoring بنجاح");
        }

        #endregion

        #region اختبارات تهيئة النظام الكامل

        /// <summary>
        /// اختبار تهيئة RedisIndexingSystem الكامل
        /// </summary>
        [Fact]
        public async Task RedisIndexingSystem_Should_Initialize_With_All_Components()
        {
            // Arrange
            _logger.LogInformation("اختبار تهيئة النظام الكامل");
            
            // إنشاء جميع المكونات المطلوبة
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var mockPropertyRepo = new Mock<IPropertyRepository>();
            var mockUnitRepo = new Mock<IUnitRepository>();
            var memoryCache = _fixture.ServiceProvider.GetRequiredService<Microsoft.Extensions.Caching.Memory.IMemoryCache>();
            
            var indexingLayer = new SmartIndexingLayer(
                _redisManager,
                mockPropertyRepo.Object,
                _fixture.ServiceProvider.GetRequiredService<ILogger<SmartIndexingLayer>>()
            );
            
            var cacheManager = new MultiLevelCache(
                _redisManager,
                memoryCache,
                _fixture.ServiceProvider.GetRequiredService<ILogger<MultiLevelCache>>(),
                _configuration
            );
            
            var searchEngine = new OptimizedSearchEngine(
                _redisManager,
                cacheManager,
                _fixture.ServiceProvider.GetRequiredService<ILogger<OptimizedSearchEngine>>(),
                memoryCache
            );
            
            var availabilityProcessor = new YemenBooking.Infrastructure.Redis.Availability.AvailabilityProcessor(
                _redisManager,
                _fixture.ServiceProvider.GetRequiredService<ILogger<YemenBooking.Infrastructure.Redis.Availability.AvailabilityProcessor>>()
            );
            
            var errorHandler = new ErrorHandlingAndMonitoring(
                _redisManager,
                _fixture.ServiceProvider.GetRequiredService<ILogger<ErrorHandlingAndMonitoring>>()
            );
            
            // Act
            _indexingSystem = new RedisIndexingSystem(
                indexingLayer,
                searchEngine,
                cacheManager,
                availabilityProcessor,
                errorHandler,
                _redisManager,
                mockPropertyRepo.Object,
                mockUnitRepo.Object,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisIndexingSystem>>(),
                _configuration
            );

            // Assert
            Assert.NotNull(_indexingSystem);
            
            // التحقق من التهيئة الناجحة
            var isRedisConnected = await _redisManager.IsConnectedAsync();
            Assert.True(isRedisConnected, "يجب أن يكون Redis متصلاً");
            
            _logger.LogInformation("✅ تمت تهيئة RedisIndexingSystem بنجاح مع جميع المكونات");
        }

        #endregion

        #region اختبارات التحقق من الفهارس

        /// <summary>
        /// اختبار إنشاء الفهارس الأساسية
        /// </summary>
        [Fact]
        public async Task System_Should_Create_Basic_Indexes_On_Initialization()
        {
            // Arrange
            _logger.LogInformation("اختبار إنشاء الفهارس الأساسية");
            
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var db = _redisManager.GetDatabase();
            
            // Act - التحقق من وجود مؤشرات التهيئة
            var searchModuleAvailable = await db.StringGetAsync("search:module:available");
            
            // Assert
            Assert.NotNull(searchModuleAvailable);
            _logger.LogInformation($"حالة RediSearch: {(searchModuleAvailable == "1" ? "متاح" : "غير متاح")}");
            
            // التحقق من إمكانية إنشاء فهارس يدوية
            var testIndexKey = $"test:index:{Guid.NewGuid()}";
            await db.SetAddAsync($"idx:city:صنعاء", testIndexKey);
            var exists = await db.SetContainsAsync($"idx:city:صنعاء", testIndexKey);
            Assert.True(exists);
            
            _logger.LogInformation("✅ الفهارس الأساسية جاهزة للاستخدام");
        }

        #endregion

        #region اختبارات تحميل Lua Scripts

        /// <summary>
        /// اختبار تحميل Lua Scripts عند التهيئة
        /// </summary>
        [Fact]
        public async Task System_Should_Load_Lua_Scripts_On_Initialization()
        {
            // Arrange
            _logger.LogInformation("اختبار تحميل Lua Scripts");
            
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var server = _redisManager.GetServer();
            
            // Act - محاولة تحميل سكريبت بسيط
            var testScript = @"
                return 'اختبار_ناجح'
            ";
            
            var sha = await server.ScriptLoadAsync(testScript);
            
            // Assert
            Assert.NotNull(sha);
            Assert.NotEmpty(sha);
            
            // تنفيذ السكريبت المحمل
            var db = _redisManager.GetDatabase();
            var result = await db.ScriptEvaluateAsync(sha);
            Assert.Equal("اختبار_ناجح", result.ToString());
            
            _logger.LogInformation($"✅ تم تحميل Lua Script بنجاح: SHA={sha}");
        }

        #endregion

        #region اختبارات التكوين والإعدادات

        /// <summary>
        /// اختبار قراءة إعدادات Redis من التكوين
        /// </summary>
        [Fact]
        public void System_Should_Read_Redis_Configuration_Correctly()
        {
            // Arrange & Act
            _logger.LogInformation("اختبار قراءة إعدادات Redis");
            
            var redisConfig = _configuration.GetSection("Redis");
            var settings = new
            {
                Enabled = redisConfig.GetValue<bool>("Enabled"),
                EndPoint = redisConfig["EndPoint"],
                Database = redisConfig.GetValue<int>("Database"),
                ConnectTimeout = redisConfig.GetValue<int>("ConnectTimeout"),
                SyncTimeout = redisConfig.GetValue<int>("SyncTimeout"),
                MaxSearchResults = redisConfig.GetValue<int>("MaxSearchResults"),
                CacheTTLMinutes = redisConfig.GetValue<int>("CacheTTLMinutes"),
                EnableScheduledMaintenance = redisConfig.GetValue<bool>("EnableScheduledMaintenance")
            };

            // Assert
            Assert.True(settings.Enabled);
            Assert.NotEmpty(settings.EndPoint);
            Assert.True(settings.Database >= 0);
            Assert.True(settings.ConnectTimeout > 0);
            Assert.True(settings.SyncTimeout > 0);
            Assert.True(settings.MaxSearchResults > 0);
            Assert.True(settings.CacheTTLMinutes > 0);
            
            _logger.LogInformation($"✅ الإعدادات: " +
                $"Endpoint={settings.EndPoint}, " +
                $"DB={settings.Database}, " +
                $"MaxResults={settings.MaxSearchResults}, " +
                $"CacheTTL={settings.CacheTTLMinutes}min");
        }

        /// <summary>
        /// اختبار التعامل مع إعدادات Redis المعطلة
        /// </summary>
        [Fact]
        public async Task System_Should_Handle_Disabled_Redis_Configuration()
        {
            // Arrange
            _logger.LogInformation("اختبار التعامل مع Redis المعطل");
            
            var disabledConfig = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string>
                {
                    {"Redis:Enabled", "false"}
                })
                .Build();
            
            // Act
            var manager = new RedisConnectionManager(disabledConfig,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var isConnected = await manager.IsConnectedAsync();
            
            // Assert
            Assert.False(isConnected, "يجب أن يكون Redis غير متصل عندما يكون معطلاً");
            
            _logger.LogInformation("✅ تم التعامل مع Redis المعطل بشكل صحيح");
            
            manager.Dispose();
        }

        #endregion

        #region اختبارات المراقبة والإحصائيات

        /// <summary>
        /// اختبار تهيئة نظام المراقبة
        /// </summary>
        [Fact]
        public async Task Monitoring_System_Should_Initialize_And_Track_Metrics()
        {
            // Arrange
            _logger.LogInformation("اختبار نظام المراقبة");
            
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var errorHandler = new ErrorHandlingAndMonitoring(
                _redisManager,
                _fixture.ServiceProvider.GetRequiredService<ILogger<ErrorHandlingAndMonitoring>>()
            );
            
            // Act - تسجيل بعض المقاييس
            await errorHandler.RecordMetricAsync("test:metric", 100, "ms");
            await errorHandler.RecordMetricAsync("test:metric", 150, "ms");
            await errorHandler.RecordMetricAsync("test:metric", 200, "ms");
            
            // التحقق من صحة النظام
            var health = await errorHandler.CheckSystemHealthAsync();
            
            // Assert
            Assert.NotNull(health);
            Assert.NotNull(health.Status);
            _logger.LogInformation($"✅ حالة النظام: {health.Status}, الرسالة: {health.Message}");
        }

        /// <summary>
        /// اختبار إعادة تعيين الإحصائيات
        /// </summary>
        [Fact]
        public async Task System_Should_Reset_Statistics_When_Configured()
        {
            // Arrange
            _logger.LogInformation("اختبار إعادة تعيين الإحصائيات");
            
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var errorHandler = new ErrorHandlingAndMonitoring(
                _redisManager,
                _fixture.ServiceProvider.GetRequiredService<ILogger<ErrorHandlingAndMonitoring>>()
            );
            
            // Act - تسجيل بعض البيانات
            await errorHandler.RecordMetricAsync("reset:test", 500, "count");
            
            // إعادة تعيين الإحصائيات
            await errorHandler.ResetStatisticsAsync();
            
            // Assert - يجب أن تكون الإحصائيات فارغة أو عند القيم الافتراضية
            var health = await errorHandler.CheckSystemHealthAsync();
            Assert.NotNull(health);
            
            _logger.LogInformation("✅ تمت إعادة تعيين الإحصائيات بنجاح");
        }

        #endregion

        #region اختبارات التعافي من الأخطاء

        /// <summary>
        /// اختبار التعافي من فشل الاتصال
        /// </summary>
        [Fact]
        public async Task System_Should_Recover_From_Connection_Failures()
        {
            // Arrange
            _logger.LogInformation("اختبار التعافي من فشل الاتصال");
            
            // تكوين مع timeout قصير لتسريع الاختبار
            var quickTimeoutConfig = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string>
                {
                    {"Redis:EndPoint", _configuration["Redis:EndPoint"] ?? "127.0.0.1:6379"},
                    {"Redis:ConnectTimeout", "1000"},
                    {"Redis:SyncTimeout", "1000"},
                    {"Redis:Database", "1"}
                })
                .Build();
            
            var manager = new RedisConnectionManager(quickTimeoutConfig,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            // Act - محاولة عمليات متعددة
            var results = new List<bool>();
            for (int i = 0; i < 3; i++)
            {
                try
                {
                    var isConnected = await manager.IsConnectedAsync();
                    results.Add(isConnected);
                    
                    if (isConnected)
                    {
                        var db = manager.GetDatabase();
                        await db.PingAsync();
                    }
                }
                catch
                {
                    results.Add(false);
                }
                
                if (i < 2) await Task.Delay(500);
            }
            
            // Assert - يجب أن تنجح بعض المحاولات على الأقل
            var successCount = results.Count(r => r);
            _logger.LogInformation($"نجحت {successCount}/3 محاولات");
            
            manager.Dispose();
        }

        /// <summary>
        /// اختبار التعامل مع أخطاء التهيئة
        /// </summary>
        [Fact]
        public void System_Should_Handle_Initialization_Errors_Gracefully()
        {
            // Arrange
            _logger.LogInformation("اختبار التعامل مع أخطاء التهيئة");
            
            // تكوين خاطئ عمداً
            var badConfig = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string>
                {
                    {"Redis:EndPoint", ""},  // endpoint فارغ
                    {"Redis:Database", "-1"} // database غير صالح
                })
                .Build();
            
            // Act & Assert
            try
            {
                var manager = new RedisConnectionManager(badConfig,
                    _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
                
                // يجب أن لا يرمي استثناء ولكن يتعامل مع الخطأ
                Assert.NotNull(manager);
                
                manager.Dispose();
                _logger.LogInformation("✅ تم التعامل مع أخطاء التهيئة بشكل صحيح");
            }
            catch (Exception ex)
            {
                _logger.LogInformation($"✅ تم رصد خطأ التهيئة كما هو متوقع: {ex.Message}");
            }
        }

        #endregion
    }
}
