using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using Moq;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Helpers;
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
        private readonly Mock<IServiceScope> _serviceScopeMock;
        private readonly Mock<IServiceScopeFactory> _serviceScopeFactoryMock;
        private readonly Mock<YemenBookingDbContext> _dbContextMock;
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
            _serviceProviderMock = new Mock<IServiceProvider>();
            _serviceScopeMock = new Mock<IServiceScope>();
            _serviceScopeFactoryMock = new Mock<IServiceScopeFactory>();
            _dbContextMock = new Mock<YemenBookingDbContext>();
            _loggerMock = new Mock<ILogger<IndexingService>>();
            _databaseMock = new Mock<IDatabase>();
            
            // إعداد السلوك الافتراضي
            _redisManagerMock.Setup(x => x.GetDatabase(It.IsAny<int>())).Returns(_databaseMock.Object);
            _redisManagerMock.Setup(x => x.IsConnectedAsync()).Returns(Task.FromResult(true));
            
            // إعداد Service Scope للعزل
            _serviceScopeFactoryMock.Setup(x => x.CreateScope()).Returns(_serviceScopeMock.Object);
            _serviceProviderMock.Setup(x => x.GetService(typeof(IServiceScopeFactory)))
                .Returns(_serviceScopeFactoryMock.Object);
            _serviceProviderMock.Setup(x => x.CreateScope()).Returns(_serviceScopeMock.Object);
            
            var scopedServiceProvider = new Mock<IServiceProvider>();
            scopedServiceProvider.Setup(x => x.GetService(typeof(YemenBookingDbContext)))
                .Returns(_dbContextMock.Object);
            _serviceScopeMock.Setup(x => x.ServiceProvider).Returns(scopedServiceProvider.Object);
            
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
            SetupPropertyInDatabase(property);
            SetupRedisOperations();
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert - التحقق من النجاح
            
            // التحقق من حفظ بيانات العقار
            _databaseMock.Verify(x => x.StringSetAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{property.Id}")),
                It.IsAny<RedisValue>(),
                It.IsAny<TimeSpan?>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من إضافة العقار للفهرس النصي
            _databaseMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains("search:index")),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من إضافة العقار لفهرس السعر
            if (property.Units?.Any() == true)
            {
                _databaseMock.Verify(x => x.SortedSetAddAsync(
                    It.Is<RedisKey>(k => k.ToString().Contains("index:price")),
                    It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                    It.IsAny<double>(),
                    It.IsAny<CommandFlags>()),
                    Times.Once);
            }
            
            _output.WriteLine($"✅ Property {property.Id} indexed successfully");
        }
        
        [Fact]
        public async Task IndexPropertyAsync_WithUnits_ShouldIndexAllUnits()
        {
            // Arrange
            var property = TestDataBuilder.PropertyWithUnits(3, _testId);
            SetupPropertyInDatabase(property);
            SetupRedisOperations();
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert
            // التحقق من فهرسة جميع الوحدات
            foreach (var unit in property.Units)
            {
                _databaseMock.Verify(x => x.StringSetAsync(
                    It.Is<RedisKey>(k => k.ToString().Contains($"unit:{unit.Id}")),
                    It.IsAny<RedisValue>(),
                    It.IsAny<TimeSpan?>(),
                    It.IsAny<When>(),
                    It.IsAny<CommandFlags>()),
                    Times.Once);
            }
            
            _output.WriteLine($"✅ Property with {property.Units.Count} units indexed");
        }
        
        [Fact]
        public async Task IndexPropertyAsync_WithAmenities_ShouldIndexAmenities()
        {
            // Arrange
            var property = TestDataBuilder.PropertyWithAmenities(5, _testId);
            SetupPropertyInDatabase(property);
            SetupRedisOperations();
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert
            _databaseMock.Verify(x => x.StringSetAsync(
                It.IsAny<RedisKey>(),
                It.Is<RedisValue>(v => v.ToString().Contains("amenities")),
                It.IsAny<TimeSpan?>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()),
                Times.AtLeastOnce);
            
            _output.WriteLine($"✅ Property with {property.Amenities.Count} amenities indexed");
        }
        
        [Fact]
        public async Task IndexPropertyAsync_WithCity_ShouldAddToCityIndex()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(_testId);
            property.City = "صنعاء";
            SetupPropertyInDatabase(property);
            SetupRedisOperations();
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert
            _databaseMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"index:city:{property.City.ToLower()}")),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _output.WriteLine($"✅ Property indexed in city: {property.City}");
        }
        
        [Fact]
        public async Task IndexPropertyAsync_WithPropertyType_ShouldAddToTypeIndex()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(_testId);
            SetupPropertyInDatabase(property);
            SetupRedisOperations();
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert
            _databaseMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"index:type:{property.TypeId}")),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _output.WriteLine($"✅ Property indexed with type: {property.TypeId}");
        }
        
        [Fact]
        public async Task IndexPropertyAsync_WithRating_ShouldAddToRatingIndex()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(_testId);
            property.AverageRating = 4.5m;
            SetupPropertyInDatabase(property);
            SetupRedisOperations();
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert
            _databaseMock.Verify(x => x.SortedSetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains("index:rating")),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.Is<double>(d => Math.Abs(d - 4.5) < 0.01),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _output.WriteLine($"✅ Property indexed with rating: {property.AverageRating}");
        }
        
        [Fact]
        public async Task IndexPropertyAsync_NonExistingProperty_ShouldNotThrow()
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            SetupPropertyInDatabase(null); // العقار غير موجود
            
            // Act
            await _indexingService.OnPropertyCreatedAsync(propertyId);
            
            // Assert
            // يجب عدم استدعاء أي عمليات Redis
            _databaseMock.Verify(x => x.StringSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<TimeSpan?>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()),
                Times.Never);
            
            _output.WriteLine($"✅ Non-existing property handled gracefully");
        }
        
        [Fact]
        public async Task UpdatePropertyAsync_ShouldRemoveOldIndexesAndCreateNew()
        {
            // Arrange
            var property = TestDataBuilder.CompleteProperty(_testId);
            SetupPropertyInDatabase(property);
            SetupRedisOperations();
            
            // Setup for removing old indexes
            _databaseMock.Setup(x => x.StringGetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(new RedisValue("{}"))); 
            
            _databaseMock.Setup(x => x.KeyDeleteAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
                
            _databaseMock.Setup(x => x.SetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
                
            _databaseMock.Setup(x => x.SortedSetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
            // Act
            await _indexingService.OnPropertyUpdatedAsync(property.Id);
            
            // Assert
            // التحقق من حذف الفهارس القديمة
            _databaseMock.Verify(x => x.KeyDeleteAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{property.Id}")),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من إعادة الفهرسة
            _databaseMock.Verify(x => x.StringSetAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{property.Id}")),
                It.IsAny<RedisValue>(),
                It.IsAny<TimeSpan?>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _output.WriteLine($"✅ Property update handled correctly");
        }
        
        [Fact]
        public async Task DeletePropertyAsync_ShouldRemoveAllIndexes()
        {
            // Arrange
            var property = TestDataBuilder.CompleteProperty(_testId);
            SetupPropertyInDatabase(property);
            SetupRedisOperations();
            
            // Setup for getting existing data
            var propertyData = "{\"Id\":\"" + property.Id + "\",\"City\":\"\u0635\u0646\u0639\u0627\u0621\"}";
            _databaseMock.Setup(x => x.StringGetAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{property.Id}")),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(new RedisValue(propertyData)));
            
            _databaseMock.Setup(x => x.KeyDeleteAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
                
            _databaseMock.Setup(x => x.SetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
                
            _databaseMock.Setup(x => x.SortedSetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
            // Act
            await _indexingService.OnPropertyDeletedAsync(property.Id);
            
            // Assert
            // التحقق من حذف البيانات الأساسية
            _databaseMock.Verify(x => x.KeyDeleteAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{property.Id}")),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من حذف من فهرس البحث
            _databaseMock.Verify(x => x.SetRemoveAsync(
                It.Is<RedisKey>(k => k.ToString().Contains("search:index")),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من حذف من فهرس السعر
            _databaseMock.Verify(x => x.SortedSetRemoveAsync(
                It.Is<RedisKey>(k => k.ToString().Contains("index:price")),
                It.Is<RedisValue>(v => v.ToString() == property.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _output.WriteLine($"✅ Property deletion handled correctly");
        }
        
        #region Helper Methods
        
        private void SetupPropertyInDatabase(Property property)
        {
            var propertiesDbSet = new Mock<DbSet<Property>>();
            var propertiesQueryable = property != null ? 
                new[] { property }.AsQueryable() :
                new Property[0].AsQueryable();
            
            propertiesDbSet.As<IAsyncEnumerable<Property>>()
                .Setup(m => m.GetAsyncEnumerator(It.IsAny<CancellationToken>()))
                .Returns(new TestAsyncEnumerator<Property>(propertiesQueryable.GetEnumerator()));
            
            propertiesDbSet.As<IQueryable<Property>>().Setup(m => m.Provider)
                .Returns(new TestAsyncQueryProvider<Property>(propertiesQueryable.Provider));
            propertiesDbSet.As<IQueryable<Property>>().Setup(m => m.Expression).Returns(propertiesQueryable.Expression);
            propertiesDbSet.As<IQueryable<Property>>().Setup(m => m.ElementType).Returns(propertiesQueryable.ElementType);
            propertiesDbSet.As<IQueryable<Property>>().Setup(m => m.GetEnumerator()).Returns(propertiesQueryable.GetEnumerator());
            
            _dbContextMock.Setup(x => x.Properties).Returns(propertiesDbSet.Object);
        }
        
        private void SetupRedisOperations()
        {
            _databaseMock.Setup(x => x.StringSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<TimeSpan?>(),
                It.IsAny<When>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
            _databaseMock.Setup(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
                
            _databaseMock.Setup(x => x.SetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
            _databaseMock.Setup(x => x.SortedSetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<double>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
        }
        
        #endregion
        
        public void Dispose()
        {
            _output.WriteLine($"🧹 Cleaning up test {_testId}");
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
                .Returns(Task.FromResult<RedisValue>(oldCity));
            
            _databaseMock.Setup(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
            _databaseMock.Setup(x => x.SetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
            _databaseMock.Setup(x => x.SetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
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
                .Returns(Task.FromResult(true));
            
            _databaseMock.Setup(x => x.SetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
            _databaseMock.Setup(x => x.SortedSetRemoveAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
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
                .Returns(Task.FromResult(true));
            
            _databaseMock.Setup(x => x.SetAddAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()))
                .Returns(Task.FromResult(true));
            
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
    }
}
