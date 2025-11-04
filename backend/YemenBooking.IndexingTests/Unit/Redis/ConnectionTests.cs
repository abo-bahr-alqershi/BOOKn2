using System;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using Moq;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using StackExchange.Redis;

namespace YemenBooking.IndexingTests.Unit.Redis
{
    /// <summary>
    /// اختبارات اتصال Redis
    /// </summary>
    public class ConnectionTests : IDisposable
    {
        private readonly ITestOutputHelper _output;
        private readonly Mock<ILogger> _loggerMock;
        private readonly Mock<IConfiguration> _configMock;
        private readonly Mock<IConnectionMultiplexer> _multiplexerMock;
        private readonly Mock<IDatabase> _databaseMock;
        private readonly Mock<IServer> _serverMock;
        private readonly string _testId;
        
        public ConnectionTests(ITestOutputHelper output)
        {
            _output = output;
            _testId = Guid.NewGuid().ToString("N");
            
            _loggerMock = new Mock<ILogger>();
            _configMock = new Mock<IConfiguration>();
            _multiplexerMock = new Mock<IConnectionMultiplexer>();
            _databaseMock = new Mock<IDatabase>();
            _serverMock = new Mock<IServer>();
            
            SetupDefaultConfiguration();
        }
        
        private void SetupDefaultConfiguration()
        {
            _configMock.Setup(x => x["Redis:EndPoint"]).Returns("localhost:6379");
            _configMock.Setup(x => x["Redis:Password"]).Returns("");
            _configMock.Setup(x => x["Redis:Database"]).Returns("0");
            _configMock.Setup(x => x["Redis:ConnectTimeout"]).Returns("5000");
            _configMock.Setup(x => x["Redis:SyncTimeout"]).Returns("5000");
            _configMock.Setup(x => x["Redis:AsyncTimeout"]).Returns("5000");
            _configMock.Setup(x => x["Redis:KeepAlive"]).Returns("60");
            _configMock.Setup(x => x["Redis:ConnectRetry"]).Returns("3");
            _configMock.Setup(x => x["Redis:AbortOnConnectFail"]).Returns("false");
            _configMock.Setup(x => x["Redis:AllowAdmin"]).Returns("true");
        }
        
        [Fact]
        public async Task InitializeAsync_WithValidConfig_ShouldConnect()
        {
            // Arrange
            _multiplexerMock.Setup(x => x.IsConnected).Returns(true);
            _multiplexerMock.Setup(x => x.GetDatabase(It.IsAny<int>(), It.IsAny<object>()))
                .Returns(_databaseMock.Object);
            _multiplexerMock.Setup(x => x.GetEndPoints(It.IsAny<bool>()))
                .Returns(new[] { System.Net.IPEndPoint.Parse("127.0.0.1:6379") });
            _multiplexerMock.Setup(x => x.GetServer(It.IsAny<System.Net.EndPoint>(), It.IsAny<object>()))
                .Returns(_serverMock.Object);
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                _multiplexerMock.Object
            );
            
            // Act
            await manager.InitializeAsync();
            var isConnected = await manager.IsConnectedAsync();
            
            // Assert
            isConnected.Should().BeTrue();
            _output.WriteLine($"✅ Redis connection initialized successfully");
        }
        
        [Fact]
        public async Task InitializeAsync_WithInvalidEndpoint_ShouldHandleGracefully()
        {
            // Arrange
            _configMock.Setup(x => x["Redis:EndPoint"]).Returns("invalid:endpoint:format");
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                null
            );
            
            // Act
            await manager.InitializeAsync();
            var isConnected = await manager.IsConnectedAsync();
            
            // Assert
            isConnected.Should().BeFalse();
            
            _loggerMock.Verify(
                x => x.Log(
                    LogLevel.Error,
                    It.IsAny<EventId>(),
                    It.IsAny<It.IsAnyType>(),
                    It.IsAny<Exception>(),
                    It.IsAny<Func<It.IsAnyType, Exception, string>>()),
                Times.AtLeastOnce);
            
            _output.WriteLine($"✅ Invalid endpoint handled gracefully");
        }
        
        [Fact]
        public void GetDatabase_WhenConnected_ShouldReturnDatabase()
        {
            // Arrange
            _multiplexerMock.Setup(x => x.IsConnected).Returns(true);
            _multiplexerMock.Setup(x => x.GetDatabase(It.IsAny<int>(), It.IsAny<object>()))
                .Returns(_databaseMock.Object);
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                _multiplexerMock.Object
            );
            
            // Act
            var database = manager.GetDatabase();
            
            // Assert
            database.Should().NotBeNull();
            database.Should().BeSameAs(_databaseMock.Object);
            
            _output.WriteLine($"✅ Database retrieved successfully");
        }
        
        [Fact]
        public void GetDatabase_WhenNotConnected_ShouldThrowException()
        {
            // Arrange
            _multiplexerMock.Setup(x => x.IsConnected).Returns(false);
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                _multiplexerMock.Object
            );
            
            // Act & Assert
            var action = () => manager.GetDatabase();
            action.Should().Throw<InvalidOperationException>()
                .WithMessage("*not connected*");
            
            _output.WriteLine($"✅ Disconnected state handled correctly");
        }
        
        [Fact]
        public void GetServer_WhenConnected_ShouldReturnServer()
        {
            // Arrange
            var endpoint = System.Net.IPEndPoint.Parse("127.0.0.1:6379");
            
            _multiplexerMock.Setup(x => x.IsConnected).Returns(true);
            _multiplexerMock.Setup(x => x.GetEndPoints(It.IsAny<bool>()))
                .Returns(new[] { endpoint });
            _multiplexerMock.Setup(x => x.GetServer(It.IsAny<System.Net.EndPoint>(), It.IsAny<object>()))
                .Returns(_serverMock.Object);
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                _multiplexerMock.Object
            );
            
            // Act
            var server = manager.GetServer();
            
            // Assert
            server.Should().NotBeNull();
            server.Should().BeSameAs(_serverMock.Object);
            
            _output.WriteLine($"✅ Server retrieved successfully");
        }
        
        [Fact]
        public async Task IsConnectedAsync_WithActiveConnection_ShouldReturnTrue()
        {
            // Arrange
            _multiplexerMock.Setup(x => x.IsConnected).Returns(true);
            _databaseMock.Setup(x => x.PingAsync(It.IsAny<CommandFlags>()))
                .ReturnsAsync(TimeSpan.FromMilliseconds(10));
            _multiplexerMock.Setup(x => x.GetDatabase(It.IsAny<int>(), It.IsAny<object>()))
                .Returns(_databaseMock.Object);
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                _multiplexerMock.Object
            );
            
            // Act
            var isConnected = await manager.IsConnectedAsync();
            
            // Assert
            isConnected.Should().BeTrue();
            
            _output.WriteLine($"✅ Connection status checked successfully");
        }
        
        [Fact]
        public async Task IsConnectedAsync_WithPingFailure_ShouldReturnFalse()
        {
            // Arrange
            _multiplexerMock.Setup(x => x.IsConnected).Returns(true);
            _databaseMock.Setup(x => x.PingAsync(It.IsAny<CommandFlags>()))
                .ThrowsAsync(new RedisException("Ping failed"));
            _multiplexerMock.Setup(x => x.GetDatabase(It.IsAny<int>(), It.IsAny<object>()))
                .Returns(_databaseMock.Object);
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                _multiplexerMock.Object
            );
            
            // Act
            var isConnected = await manager.IsConnectedAsync();
            
            // Assert
            isConnected.Should().BeFalse();
            
            _output.WriteLine($"✅ Ping failure handled correctly");
        }
        
        [Theory]
        [InlineData("localhost:6379", "localhost", 6379)]
        [InlineData("127.0.0.1:6380", "127.0.0.1", 6380)]
        [InlineData("redis.example.com:6379", "redis.example.com", 6379)]
        public void ParseEndpoint_WithValidFormats_ShouldParseCorrectly(
            string endpoint, string expectedHost, int expectedPort)
        {
            // Arrange
            _configMock.Setup(x => x["Redis:EndPoint"]).Returns(endpoint);
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                null
            );
            
            // Act
            var (host, port) = manager.ParseEndpoint(endpoint);
            
            // Assert
            host.Should().Be(expectedHost);
            port.Should().Be(expectedPort);
            
            _output.WriteLine($"✅ Endpoint '{endpoint}' parsed correctly");
        }
        
        [Fact]
        public async Task ReconnectAsync_AfterDisconnection_ShouldReestablishConnection()
        {
            // Arrange
            var isConnectedSequence = new Queue<bool>(new[] { false, false, true });
            
            _multiplexerMock.Setup(x => x.IsConnected)
                .Returns(() => isConnectedSequence.Dequeue());
            
            _multiplexerMock.Setup(x => x.GetDatabase(It.IsAny<int>(), It.IsAny<object>()))
                .Returns(_databaseMock.Object);
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                _multiplexerMock.Object
            );
            
            // Act
            var result1 = await manager.IsConnectedAsync();
            await manager.ReconnectAsync();
            var result2 = await manager.IsConnectedAsync();
            
            // Assert
            result1.Should().BeFalse();
            result2.Should().BeTrue();
            
            _output.WriteLine($"✅ Reconnection successful");
        }
        
        [Fact]
        public void Dispose_ShouldCloseConnection()
        {
            // Arrange
            _multiplexerMock.Setup(x => x.IsConnected).Returns(true);
            
            var manager = new TestableRedisConnectionManager(
                _configMock.Object,
                _loggerMock.Object,
                _multiplexerMock.Object
            );
            
            // Act
            manager.Dispose();
            
            // Assert
            _multiplexerMock.Verify(x => x.Close(It.IsAny<bool>()), Times.Once);
            _multiplexerMock.Verify(x => x.Dispose(), Times.Once);
            
            _output.WriteLine($"✅ Connection disposed properly");
        }
        
        public void Dispose()
        {
            _output.WriteLine($"🧹 Cleaning up test {_testId}");
        }
    }
    
    /// <summary>
    /// Testable version of RedisConnectionManager for unit testing
    /// </summary>
    internal class TestableRedisConnectionManager : IRedisConnectionManager
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger _logger;
        private readonly IConnectionMultiplexer _multiplexer;
        
        public TestableRedisConnectionManager(
            IConfiguration configuration,
            ILogger logger,
            IConnectionMultiplexer multiplexer)
        {
            _configuration = configuration;
            _logger = logger;
            _multiplexer = multiplexer;
        }
        
        public async Task InitializeAsync()
        {
            try
            {
                if (_multiplexer != null && _multiplexer.IsConnected)
                {
                    _logger.LogInformation("Redis connected successfully");
                }
                await Task.CompletedTask;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to initialize Redis connection");
            }
        }
        
        public async Task<bool> IsConnectedAsync()
        {
            try
            {
                if (_multiplexer == null || !_multiplexer.IsConnected)
                    return false;
                
                var db = _multiplexer.GetDatabase();
                await db.PingAsync();
                return true;
            }
            catch
            {
                return false;
            }
        }
        
        public IDatabase GetDatabase()
        {
            if (_multiplexer == null || !_multiplexer.IsConnected)
                throw new InvalidOperationException("Redis is not connected");
            
            return _multiplexer.GetDatabase();
        }
        
        public IDatabase GetDatabase(int db)
        {
            if (_multiplexer == null || !_multiplexer.IsConnected)
                throw new InvalidOperationException("Redis is not connected");
            
            return _multiplexer.GetDatabase(db);
        }
        
        public ISubscriber GetSubscriber()
        {
            if (_multiplexer == null || !_multiplexer.IsConnected)
                throw new InvalidOperationException("Redis is not connected");
            
            return _multiplexer.GetSubscriber();
        }
        
        public IServer GetServer()
        {
            if (_multiplexer == null || !_multiplexer.IsConnected)
                throw new InvalidOperationException("Redis is not connected");
            
            var endpoint = _multiplexer.GetEndPoints().FirstOrDefault();
            return endpoint != null ? _multiplexer.GetServer(endpoint) : null;
        }
        
        public async Task ReconnectAsync()
        {
            await InitializeAsync();
        }
        
        public async Task FlushDatabaseAsync(int database = 0)
        {
            var server = GetServer();
            if (server != null)
            {
                await server.FlushDatabaseAsync(database);
            }
        }
        
        public ConnectionInfo GetConnectionInfo()
        {
            return new ConnectionInfo
            {
                IsConnected = _multiplexer?.IsConnected ?? false,
                Endpoint = _configuration.GetConnectionString("Redis") ?? "localhost:6379",
                ResponseTime = TimeSpan.Zero,
                TotalConnections = 1,
                FailedConnections = 0,
                LastReconnectTime = DateTime.UtcNow
            };
        }
        
        public (string Host, int Port) ParseEndpoint(string endpoint)
        {
            var parts = endpoint.Split(':');
            var host = parts[0];
            var port = parts.Length > 1 && int.TryParse(parts[1], out var p) ? p : 6379;
            return (host, port);
        }
        
        public void Dispose()
        {
            _multiplexer?.Close(true);
            _multiplexer?.Dispose();
        }
    }
}
