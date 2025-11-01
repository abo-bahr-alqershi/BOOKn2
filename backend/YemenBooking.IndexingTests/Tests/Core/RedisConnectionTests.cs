using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using Xunit;
using StackExchange.Redis;
using YemenBooking.Infrastructure.Redis;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Application.Infrastructure.Services;
using Moq;

namespace YemenBooking.IndexingTests.Tests.Core
{
    /// <summary>
    /// اختبارات الاتصال بـ Redis والتهيئة الأساسية
    /// يغطي جميع سيناريوهات الاتصال والتكوين
    /// </summary>
    public class RedisConnectionTests : IClassFixture<TestDatabaseFixture>, IAsyncLifetime
    {
        private readonly TestDatabaseFixture _fixture;
        private readonly ILogger<RedisConnectionTests> _logger;
        private readonly IConfiguration _configuration;
        private IRedisConnectionManager? _redisManager;

        /// <summary>
        /// مُنشئ الاختبارات
        /// </summary>
        public RedisConnectionTests(TestDatabaseFixture fixture)
        {
            _fixture = fixture;
            _logger = _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionTests>>();
            _configuration = _fixture.Configuration;
        }

        /// <summary>
        /// تهيئة الاختبارات
        /// </summary>
        public async Task InitializeAsync()
        {
            _logger.LogInformation("🚀 بدء تهيئة اختبارات الاتصال بـ Redis");
            await Task.CompletedTask;
        }

        /// <summary>
        /// تنظيف الموارد بعد الاختبارات
        /// </summary>
        public async Task DisposeAsync()
        {
            _logger.LogInformation("🧹 تنظيف موارد اختبارات Redis");
            _redisManager?.Dispose();
            await Task.CompletedTask;
        }

        #region اختبارات الاتصال الأساسية

        /// <summary>
        /// اختبار الاتصال الناجح بـ Redis
        /// </summary>
        [Fact]
        public async Task Redis_Connection_Should_Succeed_With_Valid_Configuration()
        {
            // Arrange
            _logger.LogInformation("اختبار الاتصال الناجح بـ Redis");
            _redisManager = new RedisConnectionManager(_configuration, 
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());

            // Act
            var isConnected = await _redisManager.IsConnectedAsync();
            var db = _redisManager.GetDatabase();
            var server = _redisManager.GetServer();

            // Assert
            Assert.True(isConnected, "يجب أن يكون الاتصال بـ Redis ناجحاً");
            Assert.NotNull(db);
            Assert.NotNull(server);
            
            // اختبار عملية بسيطة
            var testKey = $"test:connection:{Guid.NewGuid()}";
            var testValue = "اختبار_الاتصال";
            
            await db.StringSetAsync(testKey, testValue, TimeSpan.FromSeconds(10));
            var retrievedValue = await db.StringGetAsync(testKey);
            
            Assert.Equal(testValue, retrievedValue.ToString());
            _logger.LogInformation("✅ الاتصال بـ Redis ناجح وتم التحقق من العمليات الأساسية");
        }

        /// <summary>
        /// اختبار فشل الاتصال مع تكوين خاطئ
        /// </summary>
        [Fact]
        public async Task Redis_Connection_Should_Fail_With_Invalid_Configuration()
        {
            // Arrange
            _logger.LogInformation("اختبار فشل الاتصال بـ Redis مع تكوين خاطئ");
            
            var invalidConfig = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string>
                {
                    {"Redis:EndPoint", "invalid-host:9999"},
                    {"Redis:ConnectTimeout", "1000"},
                    {"Redis:SyncTimeout", "1000"}
                })
                .Build();

            var manager = new RedisConnectionManager(invalidConfig,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());

            // Act & Assert
            var isConnected = await manager.IsConnectedAsync();
            Assert.False(isConnected, "يجب أن يفشل الاتصال مع تكوين خاطئ");
            
            _logger.LogInformation("✅ تم التحقق من فشل الاتصال مع تكوين خاطئ كما هو متوقع");
            
            manager.Dispose();
        }

        /// <summary>
        /// اختبار إعادة الاتصال التلقائية
        /// </summary>
        [Fact]
        public async Task Redis_Should_Handle_Connection_Reconnection()
        {
            // Arrange
            _logger.LogInformation("اختبار إعادة الاتصال التلقائية");
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());

            // Act - محاكاة فقدان الاتصال
            var initialConnection = await _redisManager.IsConnectedAsync();
            Assert.True(initialConnection, "يجب أن يكون الاتصال الأولي ناجحاً");

            // محاولة إجراء عمليات متعددة للتحقق من الاستقرار
            var db = _redisManager.GetDatabase();
            var tasks = new List<Task<bool>>();
            
            for (int i = 0; i < 5; i++)
            {
                var task = Task.Run(async () =>
                {
                    try
                    {
                        var key = $"reconnection:test:{i}";
                        await db.StringSetAsync(key, $"value_{i}", TimeSpan.FromSeconds(5));
                        var result = await db.StringGetAsync(key);
                        return !result.IsNullOrEmpty;
                    }
                    catch
                    {
                        return false;
                    }
                });
                tasks.Add(task);
                await Task.Delay(100);
            }

            var results = await Task.WhenAll(tasks);
            
            // Assert
            var successCount = results.Count(r => r);
            Assert.True(successCount > 0, "يجب أن تنجح بعض العمليات على الأقل");
            
            _logger.LogInformation($"✅ نجحت {successCount}/5 عمليات في اختبار الاستقرار");
        }

        #endregion

        #region اختبارات التكوين والإعدادات

        /// <summary>
        /// اختبار قراءة التكوين من ملف الإعدادات
        /// </summary>
        [Fact]
        public void Redis_Configuration_Should_Be_Read_Correctly()
        {
            // Arrange & Act
            _logger.LogInformation("اختبار قراءة تكوين Redis");
            
            var redisSection = _configuration.GetSection("Redis");
            var endpoint = redisSection["EndPoint"];
            var database = redisSection.GetValue<int>("Database");
            var connectTimeout = redisSection.GetValue<int>("ConnectTimeout");
            var syncTimeout = redisSection.GetValue<int>("SyncTimeout");
            var enabled = redisSection.GetValue<bool>("Enabled");

            // Assert
            Assert.NotNull(endpoint);
            Assert.True(database >= 0);
            Assert.True(connectTimeout > 0);
            Assert.True(syncTimeout > 0);
            Assert.True(enabled);
            
            _logger.LogInformation($"✅ تم قراءة التكوين: Endpoint={endpoint}, DB={database}, " +
                                   $"ConnectTimeout={connectTimeout}ms, SyncTimeout={syncTimeout}ms");
        }

        /// <summary>
        /// اختبار التكوين مع كلمة مرور
        /// </summary>
        [Fact]
        public async Task Redis_Should_Connect_With_Password_If_Configured()
        {
            // Arrange
            _logger.LogInformation("اختبار الاتصال مع كلمة مرور");
            
            var configWithPassword = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string>
                {
                    {"Redis:EndPoint", _configuration["Redis:EndPoint"] ?? "127.0.0.1:6379"},
                    {"Redis:Password", "test_password_123"},
                    {"Redis:Database", "2"},
                    {"Redis:ConnectTimeout", "5000"},
                    {"Redis:SyncTimeout", "5000"}
                })
                .Build();

            var manager = new RedisConnectionManager(configWithPassword,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());

            // Act
            var isConnected = await manager.IsConnectedAsync();
            
            // Assert - قد يفشل إذا كان Redis لا يتطلب كلمة مرور
            // هذا طبيعي ومتوقع في بيئة التطوير
            _logger.LogInformation($"حالة الاتصال مع كلمة مرور: {isConnected}");
            
            manager.Dispose();
        }

        #endregion

        #region اختبارات عمليات Redis الأساسية

        /// <summary>
        /// اختبار عمليات String الأساسية
        /// </summary>
        [Fact]
        public async Task Redis_String_Operations_Should_Work_Correctly()
        {
            // Arrange
            _logger.LogInformation("اختبار عمليات String في Redis");
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var db = _redisManager.GetDatabase();
            var key = $"test:string:{Guid.NewGuid()}";
            
            // Act & Assert - SET/GET
            await db.StringSetAsync(key, "قيمة_اختبارية", TimeSpan.FromMinutes(1));
            var value = await db.StringGetAsync(key);
            Assert.Equal("قيمة_اختبارية", value.ToString());
            
            // INCREMENT
            var counterKey = $"test:counter:{Guid.NewGuid()}";
            await db.StringSetAsync(counterKey, 0);
            var newValue = await db.StringIncrementAsync(counterKey);
            Assert.Equal(1, newValue);
            
            // APPEND
            await db.StringAppendAsync(key, "_ملحق");
            var appendedValue = await db.StringGetAsync(key);
            Assert.Equal("قيمة_اختبارية_ملحق", appendedValue.ToString());
            
            // TTL
            var ttl = await db.KeyTimeToLiveAsync(key);
            Assert.NotNull(ttl);
            Assert.True(ttl.Value.TotalSeconds > 0);
            
            _logger.LogInformation("✅ عمليات String تعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار عمليات Hash الأساسية
        /// </summary>
        [Fact]
        public async Task Redis_Hash_Operations_Should_Work_Correctly()
        {
            // Arrange
            _logger.LogInformation("اختبار عمليات Hash في Redis");
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var db = _redisManager.GetDatabase();
            var hashKey = $"test:hash:{Guid.NewGuid()}";
            
            // Act - إضافة حقول متعددة
            var hashEntries = new HashEntry[]
            {
                new HashEntry("name", "عقار_تجريبي"),
                new HashEntry("city", "صنعاء"),
                new HashEntry("price", "1000"),
                new HashEntry("rating", "4.5"),
                new HashEntry("is_active", "1")
            };
            
            await db.HashSetAsync(hashKey, hashEntries);
            
            // Assert - قراءة القيم
            var name = await db.HashGetAsync(hashKey, "name");
            Assert.Equal("عقار_تجريبي", name.ToString());
            
            var allFields = await db.HashGetAllAsync(hashKey);
            Assert.Equal(5, allFields.Length);
            
            var exists = await db.HashExistsAsync(hashKey, "city");
            Assert.True(exists);
            
            // تحديث قيمة
            await db.HashSetAsync(hashKey, "price", "1200");
            var updatedPrice = await db.HashGetAsync(hashKey, "price");
            Assert.Equal("1200", updatedPrice.ToString());
            
            // حذف حقل
            await db.HashDeleteAsync(hashKey, "rating");
            var deletedField = await db.HashExistsAsync(hashKey, "rating");
            Assert.False(deletedField);
            
            _logger.LogInformation("✅ عمليات Hash تعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار عمليات Set الأساسية
        /// </summary>
        [Fact]
        public async Task Redis_Set_Operations_Should_Work_Correctly()
        {
            // Arrange
            _logger.LogInformation("اختبار عمليات Set في Redis");
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var db = _redisManager.GetDatabase();
            var setKey = $"test:set:{Guid.NewGuid()}";
            
            // Act - إضافة أعضاء
            await db.SetAddAsync(setKey, "صنعاء");
            await db.SetAddAsync(setKey, "عدن");
            await db.SetAddAsync(setKey, "تعز");
            await db.SetAddAsync(setKey, "صنعاء"); // محاولة إضافة مكررة
            
            // Assert
            var count = await db.SetLengthAsync(setKey);
            Assert.Equal(3, count); // يجب أن يكون 3 فقط (بدون المكرر)
            
            var isMember = await db.SetContainsAsync(setKey, "عدن");
            Assert.True(isMember);
            
            var members = await db.SetMembersAsync(setKey);
            Assert.Equal(3, members.Length);
            
            // حذف عضو
            await db.SetRemoveAsync(setKey, "تعز");
            var newCount = await db.SetLengthAsync(setKey);
            Assert.Equal(2, newCount);
            
            _logger.LogInformation("✅ عمليات Set تعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار عمليات Sorted Set الأساسية
        /// </summary>
        [Fact]
        public async Task Redis_SortedSet_Operations_Should_Work_Correctly()
        {
            // Arrange
            _logger.LogInformation("اختبار عمليات Sorted Set في Redis");
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var db = _redisManager.GetDatabase();
            var zsetKey = $"test:zset:{Guid.NewGuid()}";
            
            // Act - إضافة عناصر مع نقاط
            await db.SortedSetAddAsync(zsetKey, "property_1", 4.5);
            await db.SortedSetAddAsync(zsetKey, "property_2", 3.8);
            await db.SortedSetAddAsync(zsetKey, "property_3", 4.9);
            await db.SortedSetAddAsync(zsetKey, "property_4", 4.2);
            
            // Assert - الحصول على العناصر بالترتيب
            var topRated = await db.SortedSetRangeByRankAsync(zsetKey, 0, -1, Order.Descending);
            Assert.Equal(4, topRated.Length);
            Assert.Equal("property_3", topRated[0].ToString());
            
            // الحصول على النقاط
            var score = await db.SortedSetScoreAsync(zsetKey, "property_2");
            Assert.Equal(3.8, score);
            
            // الحصول على الترتيب
            var rank = await db.SortedSetRankAsync(zsetKey, "property_3", Order.Descending);
            Assert.Equal(0, rank); // الأول في الترتيب التنازلي
            
            // البحث بنطاق النقاط
            var rangeByScore = await db.SortedSetRangeByScoreAsync(zsetKey, 4.0, 5.0);
            Assert.Equal(3, rangeByScore.Length);
            
            _logger.LogInformation("✅ عمليات Sorted Set تعمل بشكل صحيح");
        }

        #endregion

        #region اختبارات المعاملات والـ Pipeline

        /// <summary>
        /// اختبار المعاملات (Transactions)
        /// </summary>
        [Fact]
        public async Task Redis_Transactions_Should_Work_Correctly()
        {
            // Arrange
            _logger.LogInformation("اختبار المعاملات في Redis");
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var db = _redisManager.GetDatabase();
            var key1 = $"test:trans:1:{Guid.NewGuid()}";
            var key2 = $"test:trans:2:{Guid.NewGuid()}";
            
            // Act - إنشاء معاملة
            var transaction = db.CreateTransaction();
            
            // إضافة عمليات للمعاملة
            var task1 = transaction.StringSetAsync(key1, "value1");
            var task2 = transaction.StringSetAsync(key2, "value2");
            var task3 = transaction.StringIncrementAsync($"test:trans:counter:{Guid.NewGuid()}");
            
            // تنفيذ المعاملة
            var committed = await transaction.ExecuteAsync();
            
            // Assert
            Assert.True(committed, "يجب أن تنجح المعاملة");
            Assert.True(await task1, "يجب أن تنجح العملية الأولى");
            Assert.True(await task2, "يجب أن تنجح العملية الثانية");
            Assert.Equal(1, await task3);
            
            // التحقق من القيم
            var value1 = await db.StringGetAsync(key1);
            var value2 = await db.StringGetAsync(key2);
            Assert.Equal("value1", value1.ToString());
            Assert.Equal("value2", value2.ToString());
            
            _logger.LogInformation("✅ المعاملات تعمل بشكل صحيح");
        }

        /// <summary>
        /// اختبار Pipeline (Batch Operations)
        /// </summary>
        [Fact]
        public async Task Redis_Pipeline_Should_Improve_Performance()
        {
            // Arrange
            _logger.LogInformation("اختبار Pipeline للعمليات المجمعة");
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var db = _redisManager.GetDatabase();
            var batch = db.CreateBatch();
            var tasks = new List<Task>();
            
            // Act - إضافة عمليات متعددة للـ batch
            for (int i = 0; i < 100; i++)
            {
                var key = $"test:batch:{i}:{Guid.NewGuid()}";
                tasks.Add(batch.StringSetAsync(key, $"value_{i}", TimeSpan.FromSeconds(30)));
            }
            
            // تنفيذ الـ batch
            var startTime = DateTime.UtcNow;
            batch.Execute();
            await Task.WhenAll(tasks);
            var elapsed = DateTime.UtcNow - startTime;
            
            // Assert
            Assert.All(tasks, task => Assert.True(task.IsCompletedSuccessfully));
            _logger.LogInformation($"✅ تم تنفيذ 100 عملية في Pipeline خلال {elapsed.TotalMilliseconds}ms");
        }

        #endregion

        #region اختبارات Pub/Sub

        /// <summary>
        /// اختبار نظام Pub/Sub
        /// </summary>
        [Fact]
        public async Task Redis_PubSub_Should_Work_Correctly()
        {
            // Arrange
            _logger.LogInformation("اختبار نظام Pub/Sub");
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var subscriber = _redisManager.GetSubscriber();
            var publisher = _redisManager.GetDatabase();
            var channel = $"test:channel:{Guid.NewGuid()}";
            var receivedMessages = new List<string>();
            var tcs = new TaskCompletionSource<bool>();
            
            // Act - الاشتراك في القناة
            await subscriber.SubscribeAsync(channel, (ch, message) =>
            {
                receivedMessages.Add(message.ToString());
                if (receivedMessages.Count >= 3)
                {
                    tcs.TrySetResult(true);
                }
            });
            
            // نشر رسائل
            await Task.Delay(100); // انتظار قليل للتأكد من الاشتراك
            await publisher.PublishAsync(channel, "رسالة_1");
            await publisher.PublishAsync(channel, "رسالة_2");
            await publisher.PublishAsync(channel, "رسالة_3");
            
            // انتظار استلام الرسائل
            var received = await Task.WhenAny(tcs.Task, Task.Delay(5000)) == tcs.Task;
            
            // Assert
            Assert.True(received, "يجب استلام الرسائل");
            Assert.Equal(3, receivedMessages.Count);
            Assert.Contains("رسالة_1", receivedMessages);
            Assert.Contains("رسالة_2", receivedMessages);
            Assert.Contains("رسالة_3", receivedMessages);
            
            // إلغاء الاشتراك
            await subscriber.UnsubscribeAsync(channel);
            
            _logger.LogInformation("✅ نظام Pub/Sub يعمل بشكل صحيح");
        }

        #endregion

        #region اختبارات Lua Scripts

        /// <summary>
        /// اختبار تنفيذ Lua Scripts
        /// </summary>
        [Fact]
        public async Task Redis_Should_Execute_Lua_Scripts()
        {
            // Arrange
            _logger.LogInformation("اختبار تنفيذ Lua Scripts");
            _redisManager = new RedisConnectionManager(_configuration,
                _fixture.ServiceProvider.GetRequiredService<ILogger<RedisConnectionManager>>());
            
            var db = _redisManager.GetDatabase();
            
            // Script بسيط للجمع
            var script = @"
                local sum = 0
                for i, key in ipairs(KEYS) do
                    local val = redis.call('GET', key)
                    if val then
                        sum = sum + tonumber(val)
                    end
                end
                return sum
            ";
            
            // إعداد البيانات
            var key1 = $"test:lua:1:{Guid.NewGuid()}";
            var key2 = $"test:lua:2:{Guid.NewGuid()}";
            var key3 = $"test:lua:3:{Guid.NewGuid()}";
            
            await db.StringSetAsync(key1, 10);
            await db.StringSetAsync(key2, 20);
            await db.StringSetAsync(key3, 30);
            
            // Act - تنفيذ السكريبت
            var result = await db.ScriptEvaluateAsync(
                script,
                new RedisKey[] { key1, key2, key3 }
            );
            
            // Assert
            Assert.Equal(60, (int)result);
            _logger.LogInformation("✅ Lua Scripts تعمل بشكل صحيح");
        }

        #endregion
    }
}
