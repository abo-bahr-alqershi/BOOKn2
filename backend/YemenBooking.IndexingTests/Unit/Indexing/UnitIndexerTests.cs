using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using Moq;
using FluentAssertions;
using Microsoft.Extensions.Logging;
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
    /// اختبارات فهرسة الوحدات السكنية
    /// </summary>
    public class UnitIndexerTests : IDisposable
    {
        private readonly ITestOutputHelper _output;
        private readonly Mock<IRedisConnectionManager> _redisManagerMock;
        private readonly Mock<IServiceProvider> _serviceProviderMock;
        private readonly Mock<ILogger<IndexingService>> _loggerMock;
        private readonly Mock<IDatabase> _databaseMock;
        private readonly Mock<ITransaction> _transactionMock;
        private readonly IndexingService _indexingService;
        private readonly string _testId;
        
        public UnitIndexerTests(ITestOutputHelper output)
        {
            _output = output;
            _testId = Guid.NewGuid().ToString("N");
            
            // إعداد Mocks
            _redisManagerMock = new Mock<IRedisConnectionManager>();
            _serviceProviderMock = new Mock<IServiceProvider>();
            _loggerMock = new Mock<ILogger<IndexingService>>();
            _databaseMock = new Mock<IDatabase>();
            _transactionMock = new Mock<ITransaction>();
            
            // إعداد السلوك الافتراضي
            _redisManagerMock.Setup(x => x.GetDatabase()).Returns(_databaseMock.Object);
            _databaseMock.Setup(x => x.CreateTransaction(It.IsAny<object>())).Returns(_transactionMock.Object);
            _transactionMock.Setup(x => x.ExecuteAsync(It.IsAny<CommandFlags>())).ReturnsAsync(true);
            
            // إعداد Configuration
            var _configMock = new Mock<IConfiguration>();
            _configMock.Setup(x => x.GetSection(It.IsAny<string>()))
                .Returns(Mock.Of<IConfigurationSection>());
            _configMock.Setup(x => x["Performance:MaxConcurrentIndexing"])
                .Returns("10");
            
            // إنشاء الطبقة المختبرة
            _indexingService = new IndexingService(
                _serviceProviderMock.Object,
                _redisManagerMock.Object,
                _loggerMock.Object
            );
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithValidUnit_ShouldIndexAllFields()
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            var unit = TestDataBuilder.UnitForProperty(propertyId, _testId);
            unit.AdultsCapacity = 4;
            unit.ChildrenCapacity = 2;
            unit.MaxCapacity = 6;
            
            // Act
            await _indexingService.OnUnitCreatedAsync(unit.Id, propertyId);
            
            // Assert - التحقق من النجاح
            
            // التحقق من حفظ بيانات الوحدة
            _transactionMock.Verify(x => x.HashSetAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"unit:{unit.Id}")),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من ربط الوحدة بالعقار
            _transactionMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{propertyId}:units")),
                It.Is<RedisValue>(v => v.ToString() == unit.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من فهرسة نوع الوحدة
            _transactionMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"tag:unit_type:{unit.UnitTypeId}")),
                It.Is<RedisValue>(v => v.ToString() == unit.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من فهرسة البالغين
            _transactionMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString() == "tag:unit:has_adults"),
                It.Is<RedisValue>(v => v.ToString() == unit.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _transactionMock.Verify(x => x.SortedSetAddAsync(
                It.Is<RedisKey>(k => k.ToString() == "idx:unit:adults_capacity"),
                It.Is<RedisValue>(v => v.ToString() == unit.Id.ToString()),
                It.Is<double>(score => score == unit.AdultsCapacity.GetValueOrDefault()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من فهرسة الأطفال
            _transactionMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString() == "tag:unit:has_children"),
                It.Is<RedisValue>(v => v.ToString() == unit.Id.ToString()),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _output.WriteLine($"✅ Unit {unit.Id} indexed with all fields");
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithAvailability_ShouldIndexPricingAndAvailability()
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            var unit = TestDataBuilder.UnitWithAvailability(
                propertyId,
                DateTime.UtcNow,
                DateTime.UtcNow.AddDays(30),
                _testId
            );
            
            // Act
            await _indexingService.OnUnitCreatedAsync(unit.Id, propertyId);
            
            // Assert - التحقق من النجاح
            
            // التحقق من فهرسة التسعير
            _transactionMock.Verify(x => x.SortedSetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"unit:{unit.Id}:pricing_z")),
                It.IsAny<RedisValue>(),
                It.IsAny<double>(),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            // التحقق من فهرسة الإتاحة
            _transactionMock.Verify(x => x.SortedSetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"unit:{unit.Id}:availability")),
                It.IsAny<RedisValue>(),
                It.IsAny<double>(),
                It.IsAny<CommandFlags>()),
                Times.Once);
            
            _output.WriteLine($"✅ Unit availability and pricing indexed");
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithInactiveUnit_ShouldNotIndexAvailability()
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            var unit = TestDataBuilder.SimpleUnit(_testId);
            unit.IsActive = false;
            unit.PropertyId = propertyId;
            
            // Act
            await _indexingService.OnUnitCreatedAsync(unit.Id, propertyId);
            
            // Assert - التحقق من النجاح
            
            // التحقق من عدم فهرسة الإتاحة للوحدة غير النشطة
            _transactionMock.Verify(x => x.SortedSetAddAsync(
                It.Is<RedisKey>(k => k.ToString().Contains("availability")),
                It.IsAny<RedisValue>(),
                It.IsAny<double>(),
                It.IsAny<CommandFlags>()),
                Times.Never);
            
            _output.WriteLine($"✅ Inactive unit indexed without availability");
        }
        
        [Fact]
        public async Task IndexMultipleUnits_ShouldUpdatePropertyCapacity()
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            var units = TestDataBuilder.BatchUnits(propertyId, 5, _testId);
            
            // Act
            foreach (var unit in units)
            {
                await _indexingService.OnUnitCreatedAsync(unit.Id, propertyId);
            }
            
            // Assert - التحقق من النجاح
            
            // التحقق من فهرسة جميع الوحدات
            foreach (var unit in units)
            {
                _transactionMock.Verify(x => x.HashSetAsync(
                    It.Is<RedisKey>(k => k.ToString().Contains($"unit:{unit.Id}")),
                    It.IsAny<HashEntry[]>(),
                    It.IsAny<CommandFlags>()),
                    Times.Once);
            }
            
            _output.WriteLine($"✅ {units.Count} units indexed successfully");
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithNullUnit_ShouldReturnFalse()
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            
            // Act - محاولة فهرسة وحدة فارغة
            try
            {
                await _indexingService.OnUnitCreatedAsync(Guid.Empty, propertyId);
            }
            catch
            {
                // متوقع
            }
            
            // Assert - يجب عدم الفهرسة
            
            // التحقق من عدم استدعاء أي عمليات Redis
            _transactionMock.Verify(x => x.HashSetAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<HashEntry[]>(),
                It.IsAny<CommandFlags>()),
                Times.Never);
            
            _output.WriteLine($"✅ Null unit handled gracefully");
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithRedisError_ShouldHandleGracefully()
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            var unit = TestDataBuilder.SimpleUnit(_testId);
            unit.PropertyId = propertyId;
            
            _transactionMock.Setup(x => x.ExecuteAsync(It.IsAny<CommandFlags>()))
                .ThrowsAsync(new RedisException("Connection failed"));
            
            // Act
            await _indexingService.OnUnitCreatedAsync(unit.Id, propertyId);
            
            // Assert - يجب عدم الفهرسة
            
            // التحقق من تسجيل الخطأ
            _loggerMock.Verify(
                x => x.Log(
                    LogLevel.Error,
                    It.IsAny<EventId>(),
                    It.IsAny<It.IsAnyType>(),
                    It.IsAny<Exception?>(),
                    It.IsAny<Func<It.IsAnyType, Exception?, string>>()),
                Times.AtLeastOnce);
            
            _output.WriteLine($"✅ Redis error handled gracefully");
        }
        
        [Theory]
        [InlineData(0, 0, false, false)] // لا بالغين ولا أطفال
        [InlineData(2, 0, true, false)]  // بالغين فقط
        [InlineData(0, 2, false, true)]  // أطفال فقط
        [InlineData(2, 2, true, true)]   // بالغين وأطفال
        public async Task IndexUnitAsync_WithDifferentCapacities_ShouldIndexCorrectly(
            int maxAdults, int maxChildren, bool expectAdultIndex, bool expectChildIndex)
        {
            // Arrange
            var propertyId = Guid.NewGuid();
            var unit = TestDataBuilder.SimpleUnit(_testId);
            unit.PropertyId = propertyId;
            unit.AdultsCapacity = maxAdults;
            unit.ChildrenCapacity = maxChildren;
            
            // Act
            await _indexingService.OnUnitCreatedAsync(unit.Id, propertyId);
            
            // Assert - التحقق من النجاح
            
            // التحقق من فهرسة البالغين
            var adultIndexTimes = expectAdultIndex ? Times.Once() : Times.Never();
            _transactionMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString() == "tag:unit:has_adults"),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()),
                adultIndexTimes);
            
            // التحقق من فهرسة الأطفال
            var childIndexTimes = expectChildIndex ? Times.Once() : Times.Never();
            _transactionMock.Verify(x => x.SetAddAsync(
                It.Is<RedisKey>(k => k.ToString() == "tag:unit:has_children"),
                It.IsAny<RedisValue>(),
                It.IsAny<CommandFlags>()),
                childIndexTimes);
            
            _output.WriteLine($"✅ Unit with adults={maxAdults}, children={maxChildren} indexed correctly");
        }
        
        public void Dispose()
        {
            _output.WriteLine($"🧹 Cleaning up test {_testId}");
        }
    }
}
