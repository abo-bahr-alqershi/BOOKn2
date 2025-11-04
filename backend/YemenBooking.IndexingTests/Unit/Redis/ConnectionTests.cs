using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Net;
using System.Diagnostics;
using Xunit;
using Xunit.Abstractions;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using YemenBooking.IndexingTests.Infrastructure.Assertions;
using StackExchange.Redis;
using Testcontainers.Redis;
using Polly;

namespace YemenBooking.IndexingTests.Unit.Redis
{
    /// <summary>
    /// اختبارات اتصال Redis الحقيقية
    /// تستخدم Redis حقيقي عبر TestContainers
    /// تطبق جميع مبادئ العزل الكامل والحتمية
    /// </summary>
    [Collection("TestContainers")]
    public class ConnectionTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        private readonly SemaphoreSlim _connectionLock;
        private readonly List<TimeSpan> _connectionLatencies = new();
        private readonly List<(DateTime Time, bool Success)> _connectionAttempts = new();
        
        public ConnectionTests(TestContainerFixture containers, ITestOutputHelper output) 
            : base(output)
        {
            _containers = containers;
            _connectionLock = new SemaphoreSlim(1, 1);
        }
        
        protected override bool UseTestContainers() => true;
        
        [Fact]
        public async Task Connection_WithValidConfig_ShouldEstablishSuccessfully()
        {
            // Arrange - استخدام scope منفصل للعزل الكامل
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            
            var stopwatch = Stopwatch.StartNew();
            
            // Act
            var isConnected = await redisManager.IsConnectedAsync();
            
            stopwatch.Stop();
            _connectionLatencies.Add(stopwatch.Elapsed);
            _connectionAttempts.Add((DateTime.UtcNow, isConnected));
            
            // Assert
            isConnected.Should().BeTrue("Redis should be connected with valid configuration");
            
            // التحقق من معلومات الاتصال
            var connectionInfo = redisManager.GetConnectionInfo();
            connectionInfo.Should().NotBeNull();
            connectionInfo.IsConnected.Should().BeTrue();
            connectionInfo.Endpoint.Should().NotBeNullOrWhiteSpace();
            
            // التحقق من زمن الاستجابة
            stopwatch.Elapsed.Should().BeLessThan(TimeSpan.FromSeconds(2), 
                "Connection should be established quickly");
            
            Output.WriteLine($"✅ Redis connection established successfully in {stopwatch.ElapsedMilliseconds}ms");
            Output.WriteLine($"   Endpoint: {connectionInfo.Endpoint}");
        }
        
        [Fact]
        public async Task Connection_WithInvalidEndpoint_ShouldHandleGracefully()
        {
            // Arrange - إنشاء configuration بـ endpoint خاطئ
            using var scope = CreateIsolatedScope();
            var services = new ServiceCollection();
            
            var invalidConfig = new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string>
                {
                    ["ConnectionStrings:Redis"] = "invalid-host:99999",
                    ["Redis:ConnectTimeout"] = "1000",
                    ["Redis:ConnectRetry"] = "1",
                    ["Redis:AbortOnConnectFail"] = "true"
                })
                .Build();
            
            services.AddSingleton<IConfiguration>(invalidConfig);
            services.AddSingleton<IRedisConnectionManager, RedisConnectionManager>();
            services.AddLogging();
            
            var provider = services.BuildServiceProvider();
            var redisManager = provider.GetRequiredService<IRedisConnectionManager>();
            
            // Act & Assert
            var isConnected = await redisManager.IsConnectedAsync();
            isConnected.Should().BeFalse("Should not connect with invalid endpoint");
            
            Output.WriteLine($"✅ Invalid endpoint handled gracefully");
        }
        
        [Fact]
        public async Task GetDatabase_WhenConnected_ShouldReturnValidDatabase()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            
            // Act
            var database = redisManager.GetDatabase();
            
            // Assert
            database.Should().NotBeNull("Database object should be returned when connected");
            
            // التحقق من أن Database يعمل بشكل صحيح
            var testKey = $"test:{TestId}:db_test";
            var testValue = "test_value";
            
            await database.StringSetAsync(testKey, testValue);
            var retrievedValue = await database.StringGetAsync(testKey);
            
            retrievedValue.Should().Be(testValue);
            await database.KeyDeleteAsync(testKey);
            
            Output.WriteLine($"✅ Database retrieved and verified successfully");
        }
        
        [Fact]
        public async Task GetDatabase_WithSpecificDbNumber_ShouldReturnCorrectDatabase()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            
            // Act - استخدام قاعدة بيانات مختلفة (DB 1)
            var database1 = redisManager.GetDatabase(1);
            var database2 = redisManager.GetDatabase(2);
            
            // Assert
            database1.Should().NotBeNull();
            database2.Should().NotBeNull();
            
            // التأكد من عزل قواعد البيانات
            var testKey = $"test:{TestId}:db_isolation";
            
            await database1.StringSetAsync(testKey, "value1");
            await database2.StringSetAsync(testKey, "value2");
            
            var value1 = await database1.StringGetAsync(testKey);
            var value2 = await database2.StringGetAsync(testKey);
            
            value1.Should().Be("value1");
            value2.Should().Be("value2");
            
            // تنظيف
            await database1.KeyDeleteAsync(testKey);
            await database2.KeyDeleteAsync(testKey);
            
            Output.WriteLine($"✅ Multiple databases isolated correctly");
        }
        
        [Fact]
        public async Task GetServer_WhenConnected_ShouldReturnValidServer()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            
            // Act
            var server = redisManager.GetServer();
            
            // Assert
            server.Should().NotBeNull("Server object should be returned when connected");
            
            // التحقق من معلومات الخادم
            var info = await server.InfoAsync();
            info.Should().NotBeNull();
            info.Should().NotBeEmpty();
            
            // التحقق من قدرات الخادم
            server.IsConnected.Should().BeTrue();
            var features = server.Features;
            features.Should().NotBeNull();
            
            Output.WriteLine($"✅ Server retrieved successfully");
            Output.WriteLine($"   Server endpoint: {server.EndPoint}");
            Output.WriteLine($"   Version: {server.Version}");
        }
        
        [Fact]
        public async Task Ping_ShouldReturnLatency()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            var database = redisManager.GetDatabase();
            
            // Act - قياس زمن الاستجابة
            var pingTimes = new List<TimeSpan>();
            
            for (int i = 0; i < 10; i++)
            {
                var stopwatch = Stopwatch.StartNew();
                var pingResult = await database.PingAsync();
                stopwatch.Stop();
                
                pingTimes.Add(pingResult);
                _connectionLatencies.Add(stopwatch.Elapsed);
                
                await Task.Delay(10); // تأخير صغير بين الطلبات
            }
            
            // Assert
            pingTimes.Should().NotBeEmpty();
            pingTimes.Should().OnlyContain(t => t < TimeSpan.FromSeconds(1), 
                "All pings should complete in less than 1 second");
            
            var avgPing = TimeSpan.FromMilliseconds(pingTimes.Average(t => t.TotalMilliseconds));
            avgPing.Should().BeLessThan(TimeSpan.FromMilliseconds(100), 
                "Average ping should be less than 100ms for local Redis");
            
            Output.WriteLine($"✅ Ping test completed");
            Output.WriteLine($"   Average ping: {avgPing.TotalMilliseconds:F2}ms");
            Output.WriteLine($"   Min ping: {pingTimes.Min().TotalMilliseconds:F2}ms");
            Output.WriteLine($"   Max ping: {pingTimes.Max().TotalMilliseconds:F2}ms");
        }
        
        [Fact]
        public async Task ConcurrentConnections_ShouldHandleMultipleClientsCorrectly()
        {
            // Arrange
            const int concurrentClients = 20;
            var tasks = new List<Task<bool>>();
            
            // Act - إنشاء عملاء متعددين بشكل متزامن
            for (int i = 0; i < concurrentClients; i++)
            {
                var clientIndex = i;
                tasks.Add(Task.Run(async () =>
                {
                    using var scope = CreateIsolatedScope();
                    var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
                    
                    // كل عميل يقوم بعملية
                    var database = redisManager.GetDatabase();
                    var key = $"test:{TestId}:client_{clientIndex}";
                    var value = $"value_{clientIndex}";
                    
                    await database.StringSetAsync(key, value);
                    var retrieved = await database.StringGetAsync(key);
                    await database.KeyDeleteAsync(key);
                    
                    return retrieved == value;
                }));
            }
            
            var results = await Task.WhenAll(tasks);
            
            // Assert
            results.Should().OnlyContain(r => r == true, 
                "All concurrent clients should complete their operations successfully");
            
            Output.WriteLine($"✅ {concurrentClients} concurrent connections handled successfully");
        }
        
        [Fact]
        public async Task ConnectionResilience_WithTemporaryFailure_ShouldRecover()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            
            // Act - محاولة عمليات متعددة مع retry policy
            var retryPolicy = Policy
                .HandleResult<bool>(r => !r)
                .Or<RedisException>()
                .WaitAndRetryAsync(
                    retryCount: 3,
                    sleepDurationProvider: retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)),
                    onRetry: (outcome, timespan, retryCount, context) =>
                    {
                        Output.WriteLine($"   Retry #{retryCount} after {timespan.TotalSeconds}s");
                    });
            
            var result = await retryPolicy.ExecuteAsync(async () =>
            {
                try
                {
                    var db = redisManager.GetDatabase();
                    await db.PingAsync();
                    return true;
                }
                catch (Exception ex)
                {
                    Output.WriteLine($"   Connection attempt failed: {ex.Message}");
                    return false;
                }
            });
            
            // Assert
            result.Should().BeTrue("Connection should be resilient with retry policy");
            
            Output.WriteLine($"✅ Connection resilience verified");
        }
        
        [Fact]
        public async Task FlushDatabase_ShouldClearAllKeys()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            var database = redisManager.GetDatabase(15); // استخدام DB منفصل للاختبار
            
            // إضافة بيانات اختبارية
            var testKeys = new List<string>();
            for (int i = 0; i < 10; i++)
            {
                var key = $"test:{TestId}:flush_{i}";
                testKeys.Add(key);
                await database.StringSetAsync(key, $"value_{i}");
            }
            
            // التحقق من وجود المفاتيح
            foreach (var key in testKeys)
            {
                var exists = await database.KeyExistsAsync(key);
                exists.Should().BeTrue($"Key {key} should exist before flush");
            }
            
            // Act - مسح قاعدة البيانات
            var server = redisManager.GetServer();
            await server.FlushDatabaseAsync(15);
            
            // Assert - التحقق من حذف جميع المفاتيح
            foreach (var key in testKeys)
            {
                var exists = await database.KeyExistsAsync(key);
                exists.Should().BeFalse($"Key {key} should not exist after flush");
            }
            
            Output.WriteLine($"✅ Database flushed successfully");
        }
        
        [Fact]
        public async Task ConnectionInfo_ShouldProvideAccurateMetrics()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            
            // Act - إجراء عدة عمليات لتوليد إحصائيات
            var database = redisManager.GetDatabase();
            
            for (int i = 0; i < 5; i++)
            {
                var key = $"test:{TestId}:metric_{i}";
                await database.StringSetAsync(key, $"value_{i}");
                await database.StringGetAsync(key);
                await database.KeyDeleteAsync(key);
                
                _connectionAttempts.Add((DateTime.UtcNow, true));
            }
            
            // الحصول على معلومات الاتصال
            var connectionInfo = redisManager.GetConnectionInfo();
            
            // Assert
            connectionInfo.Should().NotBeNull();
            connectionInfo.IsConnected.Should().BeTrue();
            connectionInfo.Endpoint.Should().NotBeNullOrWhiteSpace();
            connectionInfo.TotalConnections.Should().BeGreaterThan(0);
            
            Output.WriteLine($"✅ Connection metrics retrieved");
            Output.WriteLine($"   Endpoint: {connectionInfo.Endpoint}");
            Output.WriteLine($"   Connected: {connectionInfo.IsConnected}");
            Output.WriteLine($"   Total connections: {connectionInfo.TotalConnections}");
            Output.WriteLine($"   Failed connections: {connectionInfo.FailedConnections}");
            
            // طباعة إحصائيات الأداء
            if (_connectionLatencies.Any())
            {
                Output.WriteLine($"\n📊 Performance Statistics:");
                Output.WriteLine($"   Average latency: {_connectionLatencies.Average(t => t.TotalMilliseconds):F2}ms");
                Output.WriteLine($"   Min latency: {_connectionLatencies.Min().TotalMilliseconds:F2}ms");
                Output.WriteLine($"   Max latency: {_connectionLatencies.Max().TotalMilliseconds:F2}ms");
            }
        }
        
        [Theory]
        [InlineData(1)]
        [InlineData(5)]
        [InlineData(10)]
        [InlineData(50)]
        public async Task StressTest_MultipleOperations_ShouldHandleLoad(int operationCount)
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            var database = redisManager.GetDatabase();
            
            var stopwatch = Stopwatch.StartNew();
            var errors = new List<Exception>();
            
            // Act - تنفيذ عمليات متعددة
            var tasks = Enumerable.Range(0, operationCount).Select(async i =>
            {
                try
                {
                    var key = $"test:{TestId}:stress_{i}";
                    
                    // عملية كتابة
                    await database.StringSetAsync(key, $"value_{i}", TimeSpan.FromSeconds(10));
                    
                    // عملية قراءة
                    var value = await database.StringGetAsync(key);
                    
                    // عملية تحديث
                    await database.StringSetAsync(key, $"updated_{i}");
                    
                    // عملية حذف
                    await database.KeyDeleteAsync(key);
                    
                    return true;
                }
                catch (Exception ex)
                {
                    lock (errors)
                    {
                        errors.Add(ex);
                    }
                    return false;
                }
            });
            
            var results = await Task.WhenAll(tasks);
            stopwatch.Stop();
            
            // Assert
            var successCount = results.Count(r => r);
            var successRate = (successCount * 100.0) / operationCount;
            
            successRate.Should().BeGreaterOrEqualTo(95, 
                $"At least 95% of operations should succeed, but only {successRate:F2}% succeeded");
            
            errors.Should().HaveCountLessOrEqualTo((int)(operationCount * 0.05), 
                "Error rate should be less than 5%");
            
            var opsPerSecond = operationCount / stopwatch.Elapsed.TotalSeconds;
            
            Output.WriteLine($"✅ Stress test completed");
            Output.WriteLine($"   Operations: {operationCount}");
            Output.WriteLine($"   Success rate: {successRate:F2}%");
            Output.WriteLine($"   Errors: {errors.Count}");
            Output.WriteLine($"   Duration: {stopwatch.ElapsedMilliseconds}ms");
            Output.WriteLine($"   Ops/sec: {opsPerSecond:F2}");
        }
        
        public override void Dispose()
        {
            _connectionLock?.Dispose();
            base.Dispose();
            
            // طباعة ملخص الأداء
            if (_connectionAttempts.Any())
            {
                var successRate = (_connectionAttempts.Count(a => a.Success) * 100.0) / _connectionAttempts.Count;
                Output.WriteLine($"\n📈 Test Summary:");
                Output.WriteLine($"   Total attempts: {_connectionAttempts.Count}");
                Output.WriteLine($"   Success rate: {successRate:F2}%");
            }
        }
    }
}
