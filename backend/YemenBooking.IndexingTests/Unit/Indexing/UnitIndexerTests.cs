using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Helpers;
using YemenBooking.IndexingTests.Infrastructure.Assertions;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using StackExchange.Redis;
using Newtonsoft.Json;
using YemenBooking.Core.ValueObjects;

namespace YemenBooking.IndexingTests.Unit.Indexing
{
    /// <summary>
    /// اختبارات فهرسة الوحدات السكنية
    /// باستخدام Redis و PostgreSQL الحقيقيين
    /// مع تطبيق مبادئ العزل الكامل والحتمية
    /// </summary>
    [Collection("TestContainers")]
    public class UnitIndexerTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        
        public UnitIndexerTests(TestContainerFixture containers, ITestOutputHelper output) 
            : base(output)
        {
            _containers = containers;
        }
        
        protected override bool UseTestContainers() => true;
        
        [Fact]
        public async Task IndexUnitAsync_WithValidUnit_ShouldIndexAllFields()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedDb = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var scopedIndexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقار أولاً
            var property = TestDataBuilder.SimpleProperty($"{TestId}_unit_test");
            await scopedDb.Properties.AddAsync(property);
            await scopedDb.SaveChangesAsync();
            TrackEntity(property.Id);
            
            // إنشاء وحدة
            var unit = TestDataBuilder.UnitForProperty(property.Id, $"{TestId}_unit");
            unit.AdultsCapacity = 4;
            unit.ChildrenCapacity = 2;
            unit.MaxCapacity = 6;
            
            await scopedDb.Units.AddAsync(unit);
            await scopedDb.SaveChangesAsync();
            TrackEntity(unit.Id);
            
            // Act - فهرسة الوحدة
            await scopedIndexing.OnUnitCreatedAsync(unit.Id, property.Id);
            
            // Assert - التحقق من الفهرسة في Redis
            var unitKey = $"unit:{unit.Id}";
            var unitData = await RedisDatabase.StringGetAsync(unitKey);
            unitData.HasValue.Should().BeTrue("Unit should be indexed in Redis");
            
            var indexedData = JsonConvert.DeserializeObject<dynamic>(unitData.ToString());
            string propertyIdStr = indexedData.propertyId;
            string name = indexedData.name;
            int maxCapacity = indexedData.maxCapacity;
            
            propertyIdStr.Should().Be(property.Id.ToString());
            name.Should().Be(unit.Name);
            maxCapacity.Should().Be(unit.MaxCapacity);
            
            Output.WriteLine($"✅ Unit {unit.Id} indexed with all fields");
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithAvailability_ShouldIndexPricingAndAvailability()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedDb = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var scopedIndexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقار
            var property = TestDataBuilder.SimpleProperty($"{TestId}_avail");
            await scopedDb.Properties.AddAsync(property);
            await scopedDb.SaveChangesAsync();
            TrackEntity(property.Id);
            
            // إنشاء وحدة مع التوفر
            var unit = TestDataBuilder.UnitWithAvailability(
                property.Id,
                DateTime.UtcNow,
                DateTime.UtcNow.AddDays(30),
                $"{TestId}_avail"
            );
            
            await scopedDb.Units.AddAsync(unit);
            await scopedDb.SaveChangesAsync();
            TrackEntity(unit.Id);
            
            // Act
            await scopedIndexing.OnUnitCreatedAsync(unit.Id, property.Id);
            
            // Assert
            var unitKey = $"unit:{unit.Id}";
            var unitData = await RedisDatabase.StringGetAsync(unitKey);
            unitData.HasValue.Should().BeTrue();
            
            var indexedData = JsonConvert.DeserializeObject<dynamic>(unitData.ToString());
            decimal basePrice = (decimal)indexedData.basePrice;
            basePrice.Should().BeGreaterThan(0);
            
            Output.WriteLine($"✅ Unit availability and pricing indexed");
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithNonExistingProperty_ShouldThrowException()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedDb = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var scopedIndexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقار وهمي للاختبار
            var fakePropertyId = Guid.NewGuid();
            var property = TestDataBuilder.SimpleProperty($"{TestId}_fake");
            property.Id = fakePropertyId; // استخدام ID محدد
            await scopedDb.Properties.AddAsync(property);
            await scopedDb.SaveChangesAsync();
            TrackEntity(property.Id);
            
            // إنشاء وحدة للعقار
            var unit = TestDataBuilder.UnitForProperty(property.Id, $"{TestId}_test");
            await scopedDb.Units.AddAsync(unit);
            await scopedDb.SaveChangesAsync();
            TrackEntity(unit.Id);
            
            // حذف العقار لمحاكاة عدم وجوده
            scopedDb.Properties.Remove(property);
            await scopedDb.SaveChangesAsync();
            
            // Act & Assert - محاولة فهرسة وحدة لعقار غير موجود
            await Assert.ThrowsAsync<InvalidOperationException>(async () =>
                await scopedIndexing.OnUnitCreatedAsync(unit.Id, property.Id)
            );
            
            Output.WriteLine($"✅ Exception thrown for non-existing property");
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithInactiveUnit_ShouldStillIndex()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedDb = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var scopedIndexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقار
            var property = TestDataBuilder.SimpleProperty($"{TestId}_inactive");
            await scopedDb.Properties.AddAsync(property);
            await scopedDb.SaveChangesAsync();
            TrackEntity(property.Id);
            
            // إنشاء وحدة غير نشطة
            var unit = TestDataBuilder.SimpleUnit($"{TestId}_inactive");
            unit.IsActive = false;
            unit.PropertyId = property.Id;
            
            await scopedDb.Units.AddAsync(unit);
            await scopedDb.SaveChangesAsync();
            TrackEntity(unit.Id);
            
            // Act
            await scopedIndexing.OnUnitCreatedAsync(unit.Id, property.Id);
            
            // Assert - يجب أن تفهرس حتى لو كانت غير نشطة
            var unitKey = $"unit:{unit.Id}";
            var unitData = await RedisDatabase.StringGetAsync(unitKey);
            unitData.HasValue.Should().BeTrue("Inactive unit should still be indexed");
            
            var indexedData = JsonConvert.DeserializeObject<dynamic>(unitData.ToString());
            bool isActive = indexedData.isActive;
            isActive.Should().BeFalse();
            
            Output.WriteLine($"✅ Inactive unit indexed successfully");
        }
        
        [Fact]
        public async Task IndexMultipleUnits_ShouldUpdatePropertyAggregates()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedDb = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var scopedIndexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقار
            var property = TestDataBuilder.SimpleProperty($"{TestId}_multiple");
            await scopedDb.Properties.AddAsync(property);
            await scopedDb.SaveChangesAsync();
            TrackEntity(property.Id);
            
            // فهرسة العقار أولاً
            await scopedIndexing.OnPropertyCreatedAsync(property.Id);
            
            // إنشاء وحدات متعددة
            var units = TestDataBuilder.BatchUnits(property.Id, 5, $"{TestId}_batch");
            await scopedDb.Units.AddRangeAsync(units);
            await scopedDb.SaveChangesAsync();
            TrackEntities(units.Select(u => u.Id));
            
            // Act - فهرسة جميع الوحدات
            foreach (var unit in units)
            {
                await scopedIndexing.OnUnitCreatedAsync(unit.Id, property.Id);
            }
            
            // Assert - التحقق من فهرسة جميع الوحدات
            foreach (var unit in units)
            {
                var unitKey = $"unit:{unit.Id}";
                var unitData = await RedisDatabase.StringGetAsync(unitKey);
                unitData.HasValue.Should().BeTrue($"Unit {unit.Id} should be indexed");
            }
            
            // التحقق من تحديث فهرس السعر للعقار
            var priceIndexKey = "index:price";
            var priceScore = await RedisDatabase.SortedSetScoreAsync(priceIndexKey, property.Id.ToString());
            priceScore.Should().NotBeNull("Property should be in price index after units are added");
            
            Output.WriteLine($"✅ {units.Count} units indexed successfully");
        }
        
        [Fact]
        public async Task IndexUnitAsync_WithEmptyGuid_ShouldThrow()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedIndexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // Act & Assert
            await Assert.ThrowsAsync<ArgumentException>(async () =>
                await scopedIndexing.OnUnitCreatedAsync(Guid.Empty, Guid.NewGuid())
            );
            
            Output.WriteLine($"✅ Empty Guid handled correctly");
        }
        
        [Theory]
        [InlineData(0, 0, false, false)] // لا بالغين ولا أطفال
        [InlineData(2, 0, true, false)]  // بالغين فقط
        [InlineData(0, 2, false, true)]  // أطفال فقط
        [InlineData(2, 2, true, true)]   // بالغين وأطفال
        public async Task IndexUnitAsync_WithDifferentCapacities_ShouldIndexCorrectly(
            int maxAdults, int maxChildren, bool expectAdultCapacity, bool expectChildCapacity)
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedDb = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var scopedIndexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقار
            var property = TestDataBuilder.SimpleProperty($"{TestId}_capacity_{maxAdults}_{maxChildren}");
            await scopedDb.Properties.AddAsync(property);
            await scopedDb.SaveChangesAsync();
            TrackEntity(property.Id);
            
            // إنشاء وحدة
            var unit = TestDataBuilder.SimpleUnit($"{TestId}_capacity");
            unit.PropertyId = property.Id;
            unit.AdultsCapacity = maxAdults;
            unit.ChildrenCapacity = maxChildren;
            
            await scopedDb.Units.AddAsync(unit);
            await scopedDb.SaveChangesAsync();
            TrackEntity(unit.Id);
            
            // Act
            await scopedIndexing.OnUnitCreatedAsync(unit.Id, property.Id);
            
            // Assert
            var unitKey = $"unit:{unit.Id}";
            var unitData = await RedisDatabase.StringGetAsync(unitKey);
            unitData.HasValue.Should().BeTrue();
            
            var indexedData = JsonConvert.DeserializeObject<dynamic>(unitData.ToString());
            
            if (expectAdultCapacity)
            {
                ((int?)indexedData.adultsCapacity ?? 0).Should().Be(maxAdults);
            }
            
            if (expectChildCapacity)
            {
                ((int?)indexedData.childrenCapacity ?? 0).Should().Be(maxChildren);
            }
            
            Output.WriteLine($"✅ Unit with adults={maxAdults}, children={maxChildren} indexed correctly");
        }
        
        [Fact]
        public async Task UpdateUnitAsync_ShouldUpdateIndexedData()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedDb = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var scopedIndexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقار ووحدة
            var property = TestDataBuilder.SimpleProperty($"{TestId}_update");
            await scopedDb.Properties.AddAsync(property);
            await scopedDb.SaveChangesAsync();
            TrackEntity(property.Id);
            
            var unit = TestDataBuilder.UnitForProperty(property.Id, $"{TestId}_update");
            unit.BasePrice = new Money(100, "USD");
            await scopedDb.Units.AddAsync(unit);
            await scopedDb.SaveChangesAsync();
            TrackEntity(unit.Id);
            
            // فهرسة أولية
            await scopedIndexing.OnUnitCreatedAsync(unit.Id, property.Id);
            
            // Act - تحديث الوحدة
            unit.BasePrice = new Money(200, "USD");
            unit.UpdatedAt = DateTime.UtcNow;
            scopedDb.Units.Update(unit);
            await scopedDb.SaveChangesAsync();
            
            await scopedIndexing.OnUnitUpdatedAsync(unit.Id, property.Id);
            
            // Assert - التحقق من تحديث البيانات
            var unitKey = $"unit:{unit.Id}";
            var unitData = await RedisDatabase.StringGetAsync(unitKey);
            unitData.HasValue.Should().BeTrue();
            
            var indexedData = JsonConvert.DeserializeObject<dynamic>(unitData.ToString());
            decimal basePrice = indexedData.basePrice;
            basePrice.Should().Be(200);
            
            Output.WriteLine($"✅ Unit update handled correctly");
        }
        
        [Fact]
        public async Task DeleteUnitAsync_ShouldRemoveFromIndexes()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedDb = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var scopedIndexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقار مع وحدتين على الأقل
            var property = TestDataBuilder.PropertyWithUnits(2, $"{TestId}_delete");
            await scopedDb.Properties.AddAsync(property);
            await scopedDb.SaveChangesAsync();
            TrackEntity(property.Id);
            TrackEntities(property.Units.Select(u => u.Id));
            
            // فهرسة العقار ووحداته
            await scopedIndexing.OnPropertyCreatedAsync(property.Id);
            foreach (var unit in property.Units)
            {
                await scopedIndexing.OnUnitCreatedAsync(unit.Id, property.Id);
            }
            
            // التحقق من فهرسة الوحدة الأولى
            var firstUnit = property.Units.First();
            var unitKey = $"unit:{firstUnit.Id}";
            var beforeDelete = await RedisDatabase.StringGetAsync(unitKey);
            beforeDelete.HasValue.Should().BeTrue("Unit should be indexed before deletion");
            
            // Act - حذف وحدة واحدة فقط (ليس كل الوحدات)
            scopedDb.Units.Remove(firstUnit);
            await scopedDb.SaveChangesAsync();
            
            await scopedIndexing.OnUnitDeletedAsync(firstUnit.Id, property.Id);
            
            // Assert - التحقق من الحذف
            var afterDelete = await RedisDatabase.StringGetAsync(unitKey);
            afterDelete.HasValue.Should().BeFalse("Unit should be deleted from Redis");
            
            // التحقق من بقاء الوحدة الثانية
            var secondUnit = property.Units.Last();
            var secondUnitKey = $"unit:{secondUnit.Id}";
            var secondUnitData = await RedisDatabase.StringGetAsync(secondUnitKey);
            secondUnitData.HasValue.Should().BeTrue("Other units should remain indexed");
            
            Output.WriteLine($"✅ Unit deletion handled correctly with remaining units");
        }
        
        [Fact]
        public async Task ConcurrentUnitIndexing_ShouldHandleCorrectly()
        {
            // Arrange
            using var scope = CreateIsolatedScope();
            var scopedDb = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // إنشاء عقار
            var property = TestDataBuilder.SimpleProperty($"{TestId}_concurrent");
            await scopedDb.Properties.AddAsync(property);
            await scopedDb.SaveChangesAsync();
            TrackEntity(property.Id);
            
            // إنشاء وحدات متعددة
            const int unitCount = 10;
            var unitIds = new List<Guid>();
            
            for (int i = 0; i < unitCount; i++)
            {
                var unit = TestDataBuilder.UnitForProperty(property.Id, $"{TestId}_concurrent_{i}");
                await scopedDb.Units.AddAsync(unit);
                unitIds.Add(unit.Id);
                TrackEntity(unit.Id);
            }
            
            await scopedDb.SaveChangesAsync();
            
            // Act - فهرسة متزامنة
            var indexingTasks = unitIds.Select(async unitId =>
            {
                // كل task يستخدم scope منفصل
                using var taskScope = CreateIsolatedScope();
                var taskIndexing = taskScope.ServiceProvider.GetRequiredService<IIndexingService>();
                await taskIndexing.OnUnitCreatedAsync(unitId, property.Id);
            });
            
            await Task.WhenAll(indexingTasks);
            
            // Assert - التحقق من فهرسة جميع الوحدات
            foreach (var unitId in unitIds)
            {
                var unitKey = $"unit:{unitId}";
                var unitData = await RedisDatabase.StringGetAsync(unitKey);
                unitData.HasValue.Should().BeTrue($"Unit {unitId} should be indexed");
            }
            
            Output.WriteLine($"✅ {unitCount} units indexed concurrently successfully");
        }
    }
}
