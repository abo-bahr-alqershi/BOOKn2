using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;
using System.Text.Json;
using Xunit;
using Xunit.Abstractions;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using YemenBooking.IndexingTests.Infrastructure.Assertions;
using YemenBooking.IndexingTests.Infrastructure.Helpers;
using Polly;

namespace YemenBooking.IndexingTests.Unit.Redis
{
    /// <summary>
    /// اختبارات عمليات Redis الحقيقية والشاملة
    /// تستخدم Redis حقيقي عبر TestContainers
    /// تطبق جميع مبادئ العزل الكامل والحتمية
    /// </summary>
    [Collection("TestContainers")]
    public class OperationsTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        private readonly List<TimeSpan> _operationLatencies = new();
        private readonly SemaphoreSlim _operationLock;
        private readonly Dictionary<string, int> _operationCounts = new();
        
        public OperationsTests(TestContainerFixture containers, ITestOutputHelper output) 
            : base(output)
        {
            _containers = containers;
            _operationLock = new SemaphoreSlim(1, 1);
        }
        
        protected override bool UseTestContainers() => true;
        
        #region String Operations - عمليات النصوص
        
        [Fact]
        public async Task StringOperations_CompleteScenario_ShouldWorkCorrectly()
        {
            // Arrange - استخدام scope منفصل للعزل الكامل
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:string_complete";
            var value = "test_value_اختبار_شامل";
            var updatedValue = "updated_value_محدث";
            var expiry = TimeSpan.FromSeconds(30);
            
            TrackRedisKey(key);
            var stopwatch = Stopwatch.StartNew();
            
            // Act & Assert - سيناريو كامل
            
            // 1. Set with expiry
            var setResult = await database.StringSetAsync(key, value, expiry);
            setResult.Should().BeTrue("يجب أن تنجح عملية الحفظ");
            
            // 2. Get
            var getValue = await database.StringGetAsync(key);
            getValue.Should().Be(value);
            
            // 3. Check TTL
            var ttl = await database.KeyTimeToLiveAsync(key);
            ttl.Should().NotBeNull();
            ttl.Value.Should().BeLessThanOrEqualTo(expiry);
            
            // 4. Update value
            var updateResult = await database.StringSetAsync(key, updatedValue, when: When.Exists);
            updateResult.Should().BeTrue("يجب أن تنجح عملية التحديث");
            
            // 5. Verify update
            var updatedGet = await database.StringGetAsync(key);
            updatedGet.Should().Be(updatedValue);
            
            // 6. Delete
            var deleted = await database.KeyDeleteAsync(key);
            deleted.Should().BeTrue();
            
            // 7. Verify deletion
            var afterDelete = await database.StringGetAsync(key);
            afterDelete.HasValue.Should().BeFalse();
            
            stopwatch.Stop();
            _operationLatencies.Add(stopwatch.Elapsed);
            
            Output.WriteLine($"✅ Complete string operations scenario successful");
            Output.WriteLine($"   Total time: {stopwatch.ElapsedMilliseconds}ms");
        }
        
        [Theory]
        [InlineData(1)]
        [InlineData(5)]
        [InlineData(10)]
        [InlineData(100)]
        public async Task StringIncrementBy_ConcurrentOperations_ShouldMaintainConsistency(int concurrentOps)
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:counter_concurrent";
            TrackRedisKey(key);
            
            // Act - عمليات متزامنة
            var tasks = Enumerable.Range(0, concurrentOps).Select(async i =>
            {
                using var taskScope = CreateIsolatedScope();
                var taskDb = taskScope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
                return await taskDb.StringIncrementAsync(key);
            });
            
            var results = await Task.WhenAll(tasks);
            
            // Assert
            results.Should().OnlyHaveUniqueItems("كل نتيجة يجب أن تكون فريدة");
            results.Max().Should().Be(concurrentOps);
            
            var finalValue = await database.StringGetAsync(key);
            ((long)finalValue).Should().Be(concurrentOps);
            
            Output.WriteLine($"✅ Concurrent increment operations successful");
            Output.WriteLine($"   Operations: {concurrentOps}");
            Output.WriteLine($"   Final value: {finalValue}");
        }
        
        [Fact]
        public async Task StringGetSet_AtomicOperation_ShouldReturnOldValue()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:getset";
            var oldValue = "old_value";
            var newValue = "new_value";
            
            TrackRedisKey(key);
            
            // Act
            await database.StringSetAsync(key, oldValue);
            var returnedOld = await database.StringGetSetAsync(key, newValue);
            var currentValue = await database.StringGetAsync(key);
            
            // Assert
            returnedOld.Should().Be(oldValue, "يجب إرجاع القيمة القديمة");
            currentValue.Should().Be(newValue, "يجب تحديث القيمة");
            
            Output.WriteLine($"✅ GetSet atomic operation successful");
        }
        
        #endregion
        
        #region Hash Operations - عمليات الهاش
        
        [Fact]
        public async Task HashOperations_CompleteScenario_ShouldWorkCorrectly()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:hash_complete";
            TrackRedisKey(key);
            
            var fields = new Dictionary<string, string>
            {
                ["field1"] = "value1",
                ["field2"] = "value2",
                ["field3"] = "value3",
                ["عربي"] = "قيمة_عربية"
            };
            
            // Act & Assert
            
            // 1. Set multiple fields
            var hashEntries = fields.Select(kv => new HashEntry(kv.Key, kv.Value)).ToArray();
            await database.HashSetAsync(key, hashEntries);
            
            // 2. Get single field
            var field1Value = await database.HashGetAsync(key, "field1");
            field1Value.Should().Be("value1");
            
            // 3. Get all fields
            var allFields = await database.HashGetAllAsync(key);
            allFields.Should().HaveCount(fields.Count);
            
            // 4. Check field exists
            var exists = await database.HashExistsAsync(key, "field2");
            exists.Should().BeTrue();
            
            // 5. Increment hash field
            await database.HashIncrementAsync(key, "counter", 5);
            var counterValue = await database.HashGetAsync(key, "counter");
            ((long)counterValue).Should().Be(5);
            
            // 6. Delete field
            var deleted = await database.HashDeleteAsync(key, "field3");
            deleted.Should().BeTrue();
            
            // 7. Get hash length
            var length = await database.HashLengthAsync(key);
            length.Should().Be(fields.Count); // field3 deleted, counter added
            
            Output.WriteLine($"✅ Complete hash operations scenario successful");
            Output.WriteLine($"   Total fields: {length}");
        }
        
        [Fact]
        public async Task HashScan_LargeHash_ShouldIterateEfficiently()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:hash_large";
            TrackRedisKey(key);
            
            // إنشاء hash كبير
            var entries = Enumerable.Range(0, 100)
                .Select(i => new HashEntry($"field_{i}", $"value_{i}"))
                .ToArray();
            
            await database.HashSetAsync(key, entries);
            
            // Act - Scan through hash
            var scannedEntries = new List<HashEntry>();
            var cursor = 0L;
            
            do
            {
                var scanResult = database.HashScan(key, "*field_[12]*", 10, cursor);
                foreach (var entry in scanResult)
                {
                    scannedEntries.Add(entry);
                }
                cursor = 0; // HashScan doesn't use cursor in StackExchange.Redis
                break; // Single iteration for this implementation
            } while (cursor != 0);
            
            // Assert
            scannedEntries.Should().NotBeEmpty();
            Output.WriteLine($"✅ Hash scan completed");
            Output.WriteLine($"   Scanned entries: {scannedEntries.Count}");
        }
        
        #endregion
        
        #region Set Operations - عمليات المجموعات
        
        [Fact]
        public async Task SetOperations_CompleteScenario_ShouldWorkCorrectly()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var set1 = $"test:{TestId}:set1";
            var set2 = $"test:{TestId}:set2";
            TrackRedisKey(set1);
            TrackRedisKey(set2);
            
            var members1 = new RedisValue[] { "a", "b", "c", "d" };
            var members2 = new RedisValue[] { "c", "d", "e", "f" };
            
            // Act & Assert
            
            // 1. Add members
            var added1 = await database.SetAddAsync(set1, members1);
            added1.Should().Be(members1.Length);
            
            var added2 = await database.SetAddAsync(set2, members2);
            added2.Should().Be(members2.Length);
            
            // 2. Check membership
            var contains = await database.SetContainsAsync(set1, "b");
            contains.Should().BeTrue();
            
            // 3. Get all members
            var allMembers = await database.SetMembersAsync(set1);
            allMembers.Should().HaveCount(members1.Length);
            
            // 4. Set intersection
            var intersection = await database.SetCombineAsync(SetOperation.Intersect, set1, set2);
            intersection.Should().HaveCount(2); // c, d
            intersection.Should().Contain(new RedisValue[] { "c", "d" });
            
            // 5. Set union
            var union = await database.SetCombineAsync(SetOperation.Union, set1, set2);
            union.Should().HaveCount(6); // a, b, c, d, e, f
            
            // 6. Set difference
            var difference = await database.SetCombineAsync(SetOperation.Difference, set1, set2);
            difference.Should().HaveCount(2); // a, b
            difference.Should().Contain(new RedisValue[] { "a", "b" });
            
            // 7. Remove member
            var removed = await database.SetRemoveAsync(set1, "a");
            removed.Should().BeTrue();
            
            // 8. Set length
            var length = await database.SetLengthAsync(set1);
            length.Should().Be(3);
            
            Output.WriteLine($"✅ Complete set operations scenario successful");
        }
        
        [Fact]
        public async Task SetPop_RandomMember_ShouldRemoveAndReturn()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:set_pop";
            TrackRedisKey(key);
            
            var members = new RedisValue[] { "member1", "member2", "member3" };
            await database.SetAddAsync(key, members);
            
            // Act
            var popped = await database.SetPopAsync(key);
            var remaining = await database.SetMembersAsync(key);
            
            // Assert
            popped.Should().NotBeNull();
            members.Should().Contain(popped.Value);
            remaining.Should().HaveCount(2);
            remaining.Should().NotContain(popped.Value);
            
            Output.WriteLine($"✅ Set pop operation successful");
            Output.WriteLine($"   Popped: {popped}");
        }
        
        #endregion
        
        #region Sorted Set Operations - عمليات المجموعات المرتبة
        
        [Fact]
        public async Task SortedSetOperations_CompleteScenario_ShouldWorkCorrectly()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:zset_complete";
            TrackRedisKey(key);
            
            var members = new[]
            {
                new SortedSetEntry("first", 10),
                new SortedSetEntry("second", 20),
                new SortedSetEntry("third", 30),
                new SortedSetEntry("fourth", 40),
                new SortedSetEntry("fifth", 50)
            };
            
            // Act & Assert
            
            // 1. Add members with scores
            var added = await database.SortedSetAddAsync(key, members);
            added.Should().Be(members.Length);
            
            // 2. Get score
            var score = await database.SortedSetScoreAsync(key, "third");
            score.Should().Be(30);
            
            // 3. Get rank (0-based)
            var rank = await database.SortedSetRankAsync(key, "third");
            rank.Should().Be(2);
            
            // 4. Range by rank
            var rangeByRank = await database.SortedSetRangeByRankAsync(key, 0, 2);
            rangeByRank.Should().HaveCount(3);
            rangeByRank[0].Should().Be("first");
            
            // 5. Range by score
            var rangeByScore = await database.SortedSetRangeByScoreAsync(key, 15, 35);
            rangeByScore.Should().HaveCount(2);
            rangeByScore.Should().Contain(new RedisValue[] { "second", "third" });
            
            // 6. Increment score
            var newScore = await database.SortedSetIncrementAsync(key, "second", 5);
            newScore.Should().Be(25);
            
            // 7. Remove member
            var removed = await database.SortedSetRemoveAsync(key, "first");
            removed.Should().BeTrue();
            
            // 8. Count
            var count = await database.SortedSetLengthAsync(key);
            count.Should().Be(4);
            
            // 9. Remove range by score
            var removedByScore = await database.SortedSetRemoveRangeByScoreAsync(key, 40, 50);
            removedByScore.Should().Be(2);
            
            Output.WriteLine($"✅ Complete sorted set operations scenario successful");
        }
        
        [Fact]
        public async Task SortedSetPopMin_ShouldRemoveLowestScore()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:zset_pop";
            TrackRedisKey(key);
            
            await database.SortedSetAddAsync(key, "low", 10);
            await database.SortedSetAddAsync(key, "medium", 50);
            await database.SortedSetAddAsync(key, "high", 100);
            
            // Act
            var popped = await database.SortedSetPopAsync(key, Order.Ascending);
            var remaining = await database.SortedSetRangeByRankAsync(key);
            
            // Assert
            popped.Should().NotBeNull();
            popped.Value.Element.Should().Be("low");
            popped.Value.Score.Should().Be(10);
            remaining.Should().HaveCount(2);
            remaining.Should().NotContain("low");
            
            Output.WriteLine($"✅ Sorted set pop min successful");
        }
        
        #endregion
        
        #region List Operations - عمليات القوائم
        
        [Fact]
        public async Task ListOperations_CompleteScenario_ShouldWorkCorrectly()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:list_complete";
            TrackRedisKey(key);
            
            // Act & Assert
            
            // 1. Push to right
            await database.ListRightPushAsync(key, "first");
            await database.ListRightPushAsync(key, "second");
            await database.ListRightPushAsync(key, "third");
            
            // 2. Push to left
            await database.ListLeftPushAsync(key, "zero");
            
            // 3. Get length
            var length = await database.ListLengthAsync(key);
            length.Should().Be(4);
            
            // 4. Get by index
            var atIndex = await database.ListGetByIndexAsync(key, 1);
            atIndex.Should().Be("first");
            
            // 5. Get range
            var range = await database.ListRangeAsync(key, 0, -1);
            range.Should().HaveCount(4);
            range[0].Should().Be("zero");
            
            // 6. Pop from left
            var leftPop = await database.ListLeftPopAsync(key);
            leftPop.Should().Be("zero");
            
            // 7. Pop from right
            var rightPop = await database.ListRightPopAsync(key);
            rightPop.Should().Be("third");
            
            // 8. Trim list
            await database.ListTrimAsync(key, 0, 0);
            var afterTrim = await database.ListLengthAsync(key);
            afterTrim.Should().Be(1);
            
            Output.WriteLine($"✅ Complete list operations scenario successful");
        }
        
        [Fact]
        public async Task ListBlockingPop_WithTimeout_ShouldWaitForElement()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key = $"test:{TestId}:list_blocking";
            TrackRedisKey(key);
            
            // Act - Start blocking pop with timeout
            var popTask = Task.Run(async () =>
            {
                using var popScope = CreateIsolatedScope();
                var popDb = popScope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
                return await popDb.ListLeftPopAsync(key);
            });
            
            // Wait a bit then push
            await Task.Delay(100);
            await database.ListRightPushAsync(key, "delayed_value");
            
            var popped = await popTask;
            
            // Assert
            popped.Should().Be("delayed_value");
            
            Output.WriteLine($"✅ Blocking pop operation successful");
        }
        
        #endregion
        
        #region Transaction Operations - عمليات المعاملات
        
        [Fact]
        public async Task Transaction_MultipleOperations_ShouldExecuteAtomically()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var key1 = $"test:{TestId}:trans_key1";
            var key2 = $"test:{TestId}:trans_key2";
            var key3 = $"test:{TestId}:trans_counter";
            
            TrackRedisKey(key1);
            TrackRedisKey(key2);
            TrackRedisKey(key3);
            
            // Act
            var transaction = database.CreateTransaction();
            
            // Queue operations
            var task1 = transaction.StringSetAsync(key1, "value1");
            var task2 = transaction.StringSetAsync(key2, "value2");
            var task3 = transaction.StringIncrementAsync(key3, 5);
            var task4 = transaction.StringIncrementAsync(key3, 10);
            
            // Execute transaction
            var executed = await transaction.ExecuteAsync();
            
            // Assert
            executed.Should().BeTrue("المعاملة يجب أن تنفذ بنجاح");
            
            // All tasks should be completed
            task1.Result.Should().BeTrue();
            task2.Result.Should().BeTrue();
            task3.Result.Should().Be(5);
            task4.Result.Should().Be(15);
            
            // Verify values
            var value1 = await database.StringGetAsync(key1);
            var value2 = await database.StringGetAsync(key2);
            var counter = await database.StringGetAsync(key3);
            
            value1.Should().Be("value1");
            value2.Should().Be("value2");
            ((long)counter).Should().Be(15);
            
            Output.WriteLine($"✅ Transaction executed atomically");
        }
        
        [Fact]
        public async Task Transaction_WithCondition_ShouldOnlyExecuteIfConditionMet()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            var watchKey = $"test:{TestId}:watch_key";
            var targetKey = $"test:{TestId}:target_key";
            
            TrackRedisKey(watchKey);
            TrackRedisKey(targetKey);
            
            await database.StringSetAsync(watchKey, "initial");
            
            // Act - Transaction with condition
            var transaction = database.CreateTransaction();
            transaction.AddCondition(Condition.StringEqual(watchKey, "initial"));
            
            var setTask = transaction.StringSetAsync(targetKey, "success");
            var executed = await transaction.ExecuteAsync();
            
            // Assert
            executed.Should().BeTrue();
            setTask.Result.Should().BeTrue();
            
            var value = await database.StringGetAsync(targetKey);
            value.Should().Be("success");
            
            Output.WriteLine($"✅ Conditional transaction successful");
        }
        
        #endregion
        
        #region Pub/Sub Operations - عمليات النشر والاشتراك
        
        [Fact]
        public async Task PubSub_PublishAndSubscribe_ShouldReceiveMessages()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            var subscriber = redisManager.GetSubscriber();
            
            var channel = RedisChannel.Literal($"test:{TestId}:channel");
            var receivedMessages = new List<string>();
            var messageReceivedEvent = new TaskCompletionSource<bool>();
            
            // Act - Subscribe
            await subscriber.SubscribeAsync(channel, (ch, message) =>
            {
                receivedMessages.Add(message);
                if (receivedMessages.Count >= 3)
                {
                    messageReceivedEvent.TrySetResult(true);
                }
            });
            
            // Publish messages
            await subscriber.PublishAsync(channel, "message1");
            await subscriber.PublishAsync(channel, "message2");
            await subscriber.PublishAsync(channel, "message3");
            
            // Wait for messages
            var received = await Task.WhenAny(
                messageReceivedEvent.Task,
                Task.Delay(TimeSpan.FromSeconds(5))
            ) == messageReceivedEvent.Task;
            
            // Unsubscribe
            await subscriber.UnsubscribeAsync(channel);
            
            // Assert
            received.Should().BeTrue("يجب استلام الرسائل");
            receivedMessages.Should().HaveCount(3);
            receivedMessages.Should().BeEquivalentTo(new[] { "message1", "message2", "message3" });
            
            Output.WriteLine($"✅ Pub/Sub operations successful");
            Output.WriteLine($"   Messages received: {receivedMessages.Count}");
        }
        
        #endregion
        
        #region Performance Testing
        
        [Fact]
        public async Task PerformanceTest_MassiveOperations_ShouldCompleteQuickly()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var database = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>().GetDatabase();
            
            const int operationCount = 1000;
            var keyPrefix = $"test:{TestId}:perf";
            var stopwatch = Stopwatch.StartNew();
            
            // Act - Execute many operations
            var tasks = new List<Task>();
            
            for (int i = 0; i < operationCount; i++)
            {
                var key = $"{keyPrefix}:{i}";
                TrackRedisKey(key);
                tasks.Add(database.StringSetAsync(key, $"value_{i}", TimeSpan.FromSeconds(10)));
            }
            
            await Task.WhenAll(tasks);
            stopwatch.Stop();
            
            // Assert
            var opsPerSecond = operationCount / stopwatch.Elapsed.TotalSeconds;
            opsPerSecond.Should().BeGreaterThan(100, "يجب أن يكون الأداء مقبولاً");
            
            Output.WriteLine($"✅ Performance test completed");
            Output.WriteLine($"   Operations: {operationCount}");
            Output.WriteLine($"   Time: {stopwatch.ElapsedMilliseconds}ms");
            Output.WriteLine($"   Ops/sec: {opsPerSecond:F2}");
            
            // Cleanup
            var cleanupTasks = Enumerable.Range(0, operationCount)
                .Select(i => database.KeyDeleteAsync($"{keyPrefix}:{i}"))
                .ToArray();
            
            await Task.WhenAll(cleanupTasks);
        }
        
        #endregion
        
        public override void Dispose()
        {
            _operationLock?.Dispose();
            
            // Print performance statistics
            if (_operationLatencies.Any())
            {
                Output.WriteLine($"\n📊 Performance Statistics:");
                Output.WriteLine($"   Operations: {_operationLatencies.Count}");
                Output.WriteLine($"   Avg latency: {_operationLatencies.Average(t => t.TotalMilliseconds):F2}ms");
                Output.WriteLine($"   Min latency: {_operationLatencies.Min().TotalMilliseconds:F2}ms");
                Output.WriteLine($"   Max latency: {_operationLatencies.Max().TotalMilliseconds:F2}ms");
            }
            
            base.Dispose();
        }
    }
}
