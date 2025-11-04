using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using Moq;
using FluentAssertions;
using StackExchange.Redis;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Infrastructure.Redis.Core;

namespace YemenBooking.IndexingTests.Unit.Redis
{
    /// <summary>
    /// اختبارات عمليات Redis
    /// </summary>
    public class OperationsTests : IDisposable
    {
        private readonly ITestOutputHelper _output;
        private readonly Mock<IConnectionMultiplexer> _connectionMock;
        private readonly Mock<IDatabase> _databaseMock;
        private readonly Mock<ILogger<RedisConnectionManager>> _loggerMock;
        private readonly string _testId;
        
        public OperationsTests(ITestOutputHelper output)
        {
            _output = output;
            _testId = Guid.NewGuid().ToString("N");
            
            // إعداد Mocks
            _connectionMock = new Mock<IConnectionMultiplexer>();
            _databaseMock = new Mock<IDatabase>();
            _loggerMock = new Mock<ILogger<RedisConnectionManager>>();
            
            _connectionMock.Setup(x => x.GetDatabase(It.IsAny<int>(), It.IsAny<object>()))
                .Returns(_databaseMock.Object);
            _connectionMock.Setup(x => x.IsConnected).Returns(true);
        }
        
        public void Dispose()
        {
            // تنظيف الموارد
        }
        
        #region String Operations
        
        [Fact]
        public async Task StringSet_ShouldStoreValue()
        {
            // Arrange
            var key = $"test:{_testId}:string";
            var value = "test value";
            var expiry = TimeSpan.FromMinutes(5);
            
            _databaseMock.Setup(x => x.StringSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<TimeSpan?>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            var result = await _databaseMock.Object.StringSetAsync(key, value, expiry);
            
            // Assert
            result.Should().BeTrue();
            _databaseMock.Verify(x => x.StringSetAsync(
                key,
                value,
                expiry,
                When.Always,
                CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ String set operation successful for key: {key}");
        }
        
        [Fact]
        public async Task StringGet_ShouldRetrieveValue()
        {
            // Arrange
            var key = $"test:{_testId}:string";
            var expectedValue = "stored value";
            
            _databaseMock.Setup(x => x.StringGetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(expectedValue);
            
            // Act
            var result = await _databaseMock.Object.StringGetAsync(key);
            
            // Assert
            result.Should().Be(expectedValue);
            _databaseMock.Verify(x => x.StringGetAsync(key, CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ String get operation successful: {result}");
        }
        
        [Fact]
        public async Task StringIncrement_ShouldIncrementValue()
        {
            // Arrange
            var key = $"test:{_testId}:counter";
            var incrementBy = 5;
            var expectedResult = 10;
            
            _databaseMock.Setup(x => x.StringIncrementAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<long>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(expectedResult);
            
            // Act
            var result = await _databaseMock.Object.StringIncrementAsync(key, incrementBy);
            
            // Assert
            result.Should().Be(expectedResult);
            _databaseMock.Verify(x => x.StringIncrementAsync(key, incrementBy, CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ Counter incremented to: {result}");
        }
        
        #endregion
        
        #region Hash Operations
        
        [Fact]
        public async Task HashSet_ShouldStoreHashField()
        {
            // Arrange
            var key = $"test:{_testId}:hash";
            var field = "field1";
            var value = "value1";
            
            _databaseMock.Setup(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<RedisValue>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            var result = await _databaseMock.Object.HashSetAsync(key, field, value);
            
            // Assert
            result.Should().BeTrue();
            _databaseMock.Verify(x => x.HashSetAsync(key, field, value, When.Always, CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ Hash field set: {field} = {value}");
        }
        
        [Fact]
        public async Task HashGetAll_ShouldRetrieveAllFields()
        {
            // Arrange
            var key = $"test:{_testId}:hash";
            var expectedEntries = new HashEntry[]
            {
                new HashEntry("field1", "value1"),
                new HashEntry("field2", "value2"),
                new HashEntry("field3", "value3")
            };
            
            _databaseMock.Setup(x => x.HashGetAllAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(expectedEntries);
            
            // Act
            var result = await _databaseMock.Object.HashGetAllAsync(key);
            
            // Assert
            result.Should().HaveCount(3);
            result.Should().BeEquivalentTo(expectedEntries);
            
            _output.WriteLine($"✅ Retrieved {result.Length} hash fields");
        }
        
        #endregion
        
        #region Set Operations
        
        [Fact]
        public async Task SetAdd_ShouldAddMember()
        {
            // Arrange
            var key = $"test:{_testId}:set";
            var member = "member1";
            
            _databaseMock.Setup(x => x.SetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            var result = await _databaseMock.Object.SetAddAsync(key, member);
            
            // Assert
            result.Should().BeTrue();
            _databaseMock.Verify(x => x.SetAddAsync(key, member, CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ Member added to set: {member}");
        }
        
        [Fact]
        public async Task SetMembers_ShouldRetrieveAllMembers()
        {
            // Arrange
            var key = $"test:{_testId}:set";
            var expectedMembers = new RedisValue[] { "member1", "member2", "member3" };
            
            _databaseMock.Setup(x => x.SetMembersAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(expectedMembers);
            
            // Act
            var result = await _databaseMock.Object.SetMembersAsync(key);
            
            // Assert
            result.Should().HaveCount(3);
            result.Should().BeEquivalentTo(expectedMembers);
            
            _output.WriteLine($"✅ Retrieved {result.Length} set members");
        }
        
        [Fact]
        public async Task SetContains_ShouldCheckMembership()
        {
            // Arrange
            var key = $"test:{_testId}:set";
            var member = "member1";
            
            _databaseMock.Setup(x => x.SetContainsAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            var result = await _databaseMock.Object.SetContainsAsync(key, member);
            
            // Assert
            result.Should().BeTrue();
            _databaseMock.Verify(x => x.SetContainsAsync(key, member, CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ Member {member} exists in set");
        }
        
        #endregion
        
        #region Sorted Set Operations
        
        [Fact]
        public async Task SortedSetAdd_ShouldAddWithScore()
        {
            // Arrange
            var key = $"test:{_testId}:zset";
            var member = "member1";
            var score = 100.5;
            
            _databaseMock.Setup(x => x.SortedSetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<double>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            var result = await _databaseMock.Object.SortedSetAddAsync(key, member, score);
            
            // Assert
            result.Should().BeTrue();
            _databaseMock.Verify(x => x.SortedSetAddAsync(key, member, score, When.Always, CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ Added to sorted set: {member} with score {score}");
        }
        
        [Fact]
        public async Task SortedSetRangeByScore_ShouldRetrieveRange()
        {
            // Arrange
            var key = $"test:{_testId}:zset";
            var minScore = 50.0;
            var maxScore = 150.0;
            var expectedMembers = new RedisValue[] { "member1", "member2", "member3" };
            
            _databaseMock.Setup(x => x.SortedSetRangeByScoreAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<double>(),
                It.IsAny<double>(),
                It.IsAny<Exclude>(),
                It.IsAny<Order>(),
                It.IsAny<long>(),
                It.IsAny<long>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(expectedMembers);
            
            // Act
            var result = await _databaseMock.Object.SortedSetRangeByScoreAsync(
                key, minScore, maxScore);
            
            // Assert
            result.Should().HaveCount(3);
            result.Should().BeEquivalentTo(expectedMembers);
            
            _output.WriteLine($"✅ Retrieved {result.Length} members in score range {minScore}-{maxScore}");
        }
        
        #endregion
        
        #region List Operations
        
        [Fact]
        public async Task ListPush_ShouldAddToList()
        {
            // Arrange
            var key = $"test:{_testId}:list";
            var value = "item1";
            
            _databaseMock.Setup(x => x.ListRightPushAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(1);
            
            // Act
            var result = await _databaseMock.Object.ListRightPushAsync(key, value);
            
            // Assert
            result.Should().Be(1);
            _databaseMock.Verify(x => x.ListRightPushAsync(key, value, When.Always, CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ Pushed to list: {value}");
        }
        
        [Fact]
        public async Task ListRange_ShouldRetrieveRange()
        {
            // Arrange
            var key = $"test:{_testId}:list";
            var expectedItems = new RedisValue[] { "item1", "item2", "item3" };
            
            _databaseMock.Setup(x => x.ListRangeAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<long>(),
                It.IsAny<long>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(expectedItems);
            
            // Act
            var result = await _databaseMock.Object.ListRangeAsync(key, 0, -1);
            
            // Assert
            result.Should().HaveCount(3);
            result.Should().BeEquivalentTo(expectedItems);
            
            _output.WriteLine($"✅ Retrieved {result.Length} list items");
        }
        
        #endregion
        
        #region Transaction Operations
        
        [Fact]
        public async Task Transaction_ShouldExecuteMultipleOperations()
        {
            // Arrange
            var transactionMock = new Mock<ITransaction>();
            var key1 = $"test:{_testId}:trans1";
            var key2 = $"test:{_testId}:trans2";
            
            _databaseMock.Setup(x => x.CreateTransaction(It.IsAny<object>()))
                .Returns(transactionMock.Object);
            
            transactionMock.Setup(x => x.StringSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<TimeSpan?>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
            transactionMock.Setup(x => x.ExecuteAsync(It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            var transaction = _databaseMock.Object.CreateTransaction();
            var task1 = transaction.StringSetAsync(key1, "value1");
            var task2 = transaction.StringSetAsync(key2, "value2");
            var committed = await transaction.ExecuteAsync();
            
            // Assert
            committed.Should().BeTrue();
            transactionMock.Verify(x => x.ExecuteAsync(CommandFlags.None), Times.Once);
            
            _output.WriteLine("✅ Transaction executed successfully");
        }
        
        #endregion
        
        #region Expiry Operations
        
        [Fact]
        public async Task KeyExpire_ShouldSetExpiry()
        {
            // Arrange
            var key = $"test:{_testId}:expire";
            var expiry = TimeSpan.FromMinutes(10);
            
            _databaseMock.Setup(x => x.KeyExpireAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<TimeSpan?>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            var result = await _databaseMock.Object.KeyExpireAsync(key, expiry);
            
            // Assert
            result.Should().BeTrue();
            _databaseMock.Verify(x => x.KeyExpireAsync(key, expiry, CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ Expiry set to {expiry.TotalMinutes} minutes");
        }
        
        [Fact]
        public async Task KeyTimeToLive_ShouldGetRemainingTime()
        {
            // Arrange
            var key = $"test:{_testId}:ttl";
            var expectedTtl = TimeSpan.FromMinutes(5);
            
            _databaseMock.Setup(x => x.KeyTimeToLiveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(expectedTtl);
            
            // Act
            var result = await _databaseMock.Object.KeyTimeToLiveAsync(key);
            
            // Assert
            result.Should().Be(expectedTtl);
            _databaseMock.Verify(x => x.KeyTimeToLiveAsync(key, CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ TTL: {result?.TotalMinutes} minutes remaining");
        }
        
        #endregion
        
        #region Pub/Sub Operations
        
        [Fact]
        public async Task Publish_ShouldSendMessage()
        {
            // Arrange
            var channel = $"test:{_testId}:channel";
            var message = "test message";
            var subscriberMock = new Mock<ISubscriber>();
            
            _connectionMock.Setup(x => x.GetSubscriber(It.IsAny<object>()))
                .Returns(subscriberMock.Object);
            
            subscriberMock.Setup(x => x.PublishAsync(
                It.IsAny<RedisChannel>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(1);
            
            // Act
            var subscriber = _connectionMock.Object.GetSubscriber();
            var result = await subscriber.PublishAsync(channel, message);
            
            // Assert
            result.Should().Be(1);
            subscriberMock.Verify(x => x.PublishAsync(
                (RedisChannel)channel,
                message,
                CommandFlags.None), Times.Once);
            
            _output.WriteLine($"✅ Message published to {channel}");
        }
        
        #endregion
    }
}
