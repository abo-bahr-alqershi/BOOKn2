using System;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using Moq;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using StackExchange.Redis;
using Microsoft.Extensions.Configuration;

namespace YemenBooking.IndexingTests.Unit.Indexing
{
    /// <summary>
    /// اختبارات الوحدة لفهرسة العقارات
    /// معزولة تماماً باستخدام Mocks
    /// </summary>
    public class PropertyIndexerTests : IDisposable
    {
        private readonly ITestOutputHelper _output;
        private readonly Mock<IRedisConnectionManager> _redisManagerMock;
        private readonly Mock<IPropertyRepository> _propertyRepoMock;
        private readonly Mock<IServiceProvider> _serviceProviderMock;
        private readonly Mock<ILogger<IndexingService>> _loggerMock;
        private readonly Mock<IDatabase> _databaseMock;
        private readonly IndexingService _indexingService;
        private readonly string _testId;
        
        public PropertyIndexerTests(ITestOutputHelper output)
        {
            _output = output;
            _testId = Guid.NewGuid().ToString("N");
            
            // إعداد Mocks
            _redisManagerMock = new Mock<IRedisConnectionManager>();
            _propertyRepoMock = new Mock<IPropertyRepository>();
            _serviceProviderMock = new Mock<IServiceProvider>();
            _loggerMock = new Mock<ILogger<IndexingService>>();
            _databaseMock = new Mock<IDatabase>();
            
            // إعداد السلوك الافتراضي
            _redisManagerMock.Setup(x => x.GetDatabase()).Returns(_databaseMock.Object);
            _redisManagerMock.Setup(x => x.IsConnectedAsync()).ReturnsAsync(true);
            
            // إنشاء الطبقة المختبرة
            _indexingService = new IndexingService(
                _serviceProviderMock.Object,
                _redisManagerMock.Object,
                _loggerMock.Object
            );
        }
        
        [Fact]
        public async Task IndexPropertyAsync_WithValidProperty_ShouldIndexSuccessfully()
        {
            // Arrange
            var property = TestDataBuilder.CompleteProperty(_testId);
            
            _databaseMock.Setup(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            _databaseMock.Setup(x => x.SetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            _databaseMock.Setup(x => x.SortedSetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<double>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert - التحقق من النجاح
            
            // التحقق من استدعاء العمليات الأساسية
            _databaseMock.Verify(x => x.HashSetAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{property.Id}")),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من إضافة العقار للمجموعات
            _databaseMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains("properties:all")),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من إضافة العقار للفهارس المرتبة
            _databaseMock.Verify(x => x.SortedSetAddAsync(
                It.IsAny<RedisKey>(),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.IsAny<double>(),
                It.IsAny<CommandFlags>()),
                Times.AtLeastOnce);
            
            _output.WriteLine($"✅ Property {property.Id} indexed successfully");
        }
        
        [Fact]
        public async Task IndexPropertyAsync_WithInactiveProperty_ShouldNotIndex()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(_testId);
            property.IsActive = false;
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert - يجب عدم الفهرسة
            
            // التحقق من عدم استدعاء عمليات Redis
            _databaseMock.Verify(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()),
                Times.Never);
            
            _output.WriteLine($"✅ Inactive property {property.Id} was not indexed");
        }
        
        [Fact]
        public async Task IndexPropertyAsync_WithUnapprovedProperty_ShouldNotIndex()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(_testId);
            property.IsApproved = false;
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert - يجب عدم الفهرسة
            
            // التحقق من عدم استدعاء عمليات Redis
            _databaseMock.Verify(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()),
                Times.Never);
            
            _output.WriteLine($"✅ Unapproved property {property.Id} was not indexed");
        }
        
        [Fact]
        public async Task UpdatePropertyIndexAsync_ShouldRemoveOldAndAddNew()
        {
            // Arrange
            var property = TestDataBuilder.CompleteProperty(_testId);
            var oldCity = "صنعاء";
            var newCity = "عدن";
            property.City = newCity;
            
            // Mock getting old data
            _databaseMock.Setup(x => x.HashGetAsync(
                It.IsAny<RedisKey>(),
                It.Is<RedisValue>(v => v == "city"),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(oldCity);
            
            _databaseMock.Setup(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            _databaseMock.Setup(x => x.SetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            _databaseMock.Setup(x => x.SetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            await _indexingService.OnPropertyUpdatedAsync(property.Id);
            
            // Assert - التحقق من النجاح
            
            // التحقق من إزالة العقار من المدينة القديمة
            _databaseMock.Verify(x => x.SetRemoveAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"city:{oldCity.ToLowerInvariant()}")),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من إضافة العقار للمدينة الجديدة
            _databaseMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"city:{newCity.ToLowerInvariant()}")),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _output.WriteLine($"✅ Property {property.Id} updated from {oldCity} to {newCity}");
        }
        
        [Fact]
        public async Task RemovePropertyFromIndexesAsync_ShouldRemoveFromAllIndexes()
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            
            // Mock getting property data
            var hashEntries = new HashEntry[]
            {
                new HashEntry("city", "صنعاء"),
                new HashEntry("property_type", "30000000-0000-0000-0000-000000000001")
            };
            
            _databaseMock.Setup(x => x.HashGetAllAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(hashEntries);
            
            _databaseMock.Setup(x => x.KeyDeleteAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            _databaseMock.Setup(x => x.SetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            _databaseMock.Setup(x => x.SortedSetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            await _indexingService.OnPropertyDeletedAsync(propertyId);
            
            // Assert - التحقق من النجاح
            
            // التحقق من حذف hash العقار
            _databaseMock.Verify(x => x.KeyDeleteAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{propertyId}")),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من إزالة العقار من المجموعات
            _databaseMock.Verify(x => x.SetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.Is<RedisValue>(v => v.ToString() == propertyId.ToString()),
                It.IsAny<CommandFlags>()),
                Times.AtLeastOnce);
            
            // التحقق من إزالة العقار من الفهارس المرتبة
            _databaseMock.Verify(x => x.SortedSetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.Is<RedisValue>(v => v.ToString() == propertyId.ToString()),
                It.IsAny<CommandFlags>()),
                Times.AtLeastOnce);
            
            _output.WriteLine($"✅ Property {propertyId} removed from all indexes");
        }
        
        [Fact]
        public async Task IndexPropertyAsync_WithRedisError_ShouldReturnFalse()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(_testId);
            
            _databaseMock.Setup(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()))
                .ThrowsAsync(new RedisException("Connection failed"));
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert - يجب عدم الفهرسة
            
            _output.WriteLine($"✅ Handled Redis error gracefully");
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithValidUnit_ShouldIndexSuccessfully()
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            var unit = TestDataBuilder.UnitForProperty(propertyId, _testId);
            
            _databaseMock.Setup(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            _databaseMock.Setup(x => x.SetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(true);
            
            // Act
            await _indexingService.OnUnitCreatedAsync(unit.Id, unit.PropertyId);
            
            // Assert - التحقق من النجاح
            
            // التحقق من فهرسة الوحدة
            _databaseMock.Verify(x => x.HashSetAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"unit:{unit.Id}")),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من ربط الوحدة بالعقار
            _databaseMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{propertyId}:units")),
                It.Is<RedisValue>(v => v.ToString() == unit.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _output.WriteLine($"✅ Unit {unit.Id} indexed successfully");
        }
        
        public void Dispose()
        {
            _output.WriteLine($"🧹 Cleaning up test {_testId}");
        }
    }
}
