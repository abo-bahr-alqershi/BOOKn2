using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using System.Diagnostics;
using Xunit;
using Xunit.Abstractions;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Helpers;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using StackExchange.Redis;
using Npgsql;

namespace YemenBooking.IndexingTests.Integration
{
    /// <summary>
    /// اختبارات التزامن - يطبق مبادئ العزل والحتمية
    /// كل thread يستخدم scope منفصل تماماً
    /// </summary>
    [Collection("TestContainers")]
    public class ConcurrencyTests : TestBase
    {
        private readonly SemaphoreSlim _concurrencyLimiter;
        private readonly List<TimeSpan> _operationTimes = new();
        private readonly object _timesLock = new();
        
        public ConcurrencyTests(ITestOutputHelper output) : base(output)
        {
            // تحديد التزامن بناءً على عدد النوى
            _concurrencyLimiter = new SemaphoreSlim(
                initialCount: Environment.ProcessorCount * 2,
                maxCount: Environment.ProcessorCount * 2);
        }
        
        protected override bool UseTestContainers() => true;

        [Fact]
        public async Task ConcurrentPropertyCreation_ShouldHandleCorrectly()
        {
            // Arrange
            const int concurrentOperations = 20;
            var createdPropertyIds = new System.Collections.Concurrent.ConcurrentBag<Guid>();
            var errors = new System.Collections.Concurrent.ConcurrentBag<Exception>();
            
            // التحقق من وجود البيانات الأساسية أولاً
            await VerifyBaseDataExistsAsync();
            
            Output.WriteLine($"🚀 Starting {concurrentOperations} concurrent property creations");
            
            // Act
            var tasks = Enumerable.Range(0, concurrentOperations)
                .Select(i => CreatePropertyConcurrentlyAsync(i, createdPropertyIds, errors))
                .ToList();
            
            var results = await Task.WhenAll(tasks);
            
            // Assert
            errors.Should().BeEmpty("لا يجب أن تكون هناك أخطاء في العمليات المتزامنة");
            createdPropertyIds.Should().HaveCount(concurrentOperations);
            createdPropertyIds.Distinct().Should().HaveCount(concurrentOperations, "يجب أن تكون كل العقارات فريدة");
            
            // التحقق من Redis
            await VerifyRedisDataConsistencyAsync(createdPropertyIds.ToList());
            
            // تتبع العقارات للتنظيف
            foreach (var id in createdPropertyIds)
            {
                TrackEntity(id);
            }
            
            Output.WriteLine($"✅ Successfully created {createdPropertyIds.Count} properties concurrently");
            PrintPerformanceStats();
        }
        
        [Fact]
        public async Task ConcurrentUnitCreation_WithSameProperty_ShouldHandleCorrectly()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(TestId);
            
            using (var scope = CreateIsolatedScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                await db.Properties.AddAsync(property);
                await db.SaveChangesAsync();
            }
            
            TrackEntity(property.Id);
            
            const int unitsPerProperty = 10;
            var createdUnitIds = new System.Collections.Concurrent.ConcurrentBag<Guid>();
            
            // Act - إنشاء وحدات متعددة لنفس العقار بشكل متزامن
            var tasks = Enumerable.Range(0, unitsPerProperty)
                .Select(i => CreateUnitConcurrentlyAsync(property.Id, i, createdUnitIds))
                .ToList();
            
            await Task.WhenAll(tasks);
            
            // Assert
            createdUnitIds.Should().HaveCount(unitsPerProperty);
            createdUnitIds.Distinct().Should().HaveCount(unitsPerProperty);
            
            // التحقق من العقار محدث بشكل صحيح
            using (var scope = CreateIsolatedScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                var updatedProperty = await db.Properties
                    .Include(p => p.Units)
                    .FirstOrDefaultAsync(p => p.Id == property.Id);
                
                updatedProperty.Should().NotBeNull();
                updatedProperty.Units.Should().HaveCount(unitsPerProperty);
            }
            
            // تتبع للتنظيف
            foreach (var id in createdUnitIds)
            {
                TrackEntity(id);
            }
            
            Output.WriteLine($"✅ Successfully created {unitsPerProperty} units for property {property.Id}");
        }
        
        [Fact]
        public async Task ConcurrentSearch_ShouldReturnConsistentResults()
        {
            // Arrange - إنشاء بيانات للبحث
            var properties = await CreateTestPropertiesAsync(10);
            
            // انتظار حتى تصبح البيانات جاهزة في Redis
            await AsyncTestOperations.AssertEventuallyAsync(
                async () => await VerifyAllPropertiesIndexedAsync(properties),
                timeout: TimeSpan.FromSeconds(10),
                message: "Properties not indexed within timeout");
            
            const int concurrentSearches = 50;
            var searchResults = new System.Collections.Concurrent.ConcurrentBag<PropertySearchResult>();
            
            // Act - تنفيذ عمليات بحث متزامنة
            var searchTasks = Enumerable.Range(0, concurrentSearches)
                .Select(async i =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        using var scope = CreateIsolatedScope();
                        var searchService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        var request = TestDataBuilder.SimpleSearchRequest();
                        var result = await searchService.SearchAsync(request);
                        searchResults.Add(result);
                        
                        return result;
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                });
            
            await Task.WhenAll(searchTasks);
            
            // التحقق من أن جميع العقارات مفهرسة بشكل صحيح
            await AsyncTestOperations.AssertEventuallyAsync(
                async () => 
                {
                    using var scope = CreateIsolatedScope();
                    var searchService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    var result = await searchService.SearchAsync(new PropertySearchRequest
                    {
                        PageNumber = 1,
                        PageSize = 100
                    });
                    return result?.TotalCount >= properties.Count;
                },
                TimeSpan.FromSeconds(10),
                "All properties should be searchable"
            );
            
            // Assert - التحقق من اتساق النتائج
            searchResults.Should().HaveCount(concurrentSearches);
            
            // كل النتائج يجب أن تكون متسقة
            var firstResult = searchResults.First();
            foreach (var result in searchResults)
            {
                result.TotalCount.Should().Be(firstResult.TotalCount);
                result.Properties.Count.Should().Be(firstResult.Properties.Count);
            }
            
            Output.WriteLine($"✅ {concurrentSearches} concurrent searches returned consistent results");
        }
        
        [Fact]
        public async Task ConcurrentPropertyDeletion_ShouldHandleCorrectly()
        {
            // Arrange
            var properties = await CreateTestPropertiesAsync(5);
            
            // انتظار حتى تصبح جميع العقارات مفهرسة
            await AsyncTestOperations.AssertEventuallyAsync(
                async () => await VerifyAllPropertiesIndexedAsync(properties),
                timeout: TimeSpan.FromSeconds(10));
            
            
            // Act: حذف متزامن لجميع العقارات
            var deleteTasks = properties.Select(property => Task.Run(async () =>
            {
                using var scope = CreateIsolatedScope();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                await indexingService.OnPropertyDeletedAsync(property.Id);
            }));
            
            await Task.WhenAll(deleteTasks);
            
            // Assert: التحقق من حذف جميع العقارات من Redis
            foreach (var property in properties)
            {
                var redisData = await GetRedisPropertyDataAsync(property.Id);
                redisData.Should().BeNullOrEmpty($"Property {property.Id} should be deleted from Redis");
            }
            
            Output.WriteLine($"✅ Successfully deleted {properties.Count} properties concurrently");
        }
        
        [Fact]
        public async Task StressTest_HighConcurrency_ShouldHandleLoad()
        {
            // Arrange - اختبار ضغط عالي
            const int highConcurrencyLevel = 100;
            var stopwatch = Stopwatch.StartNew();
            var errors = new System.Collections.Concurrent.ConcurrentBag<Exception>();
            
            Output.WriteLine($"🚀 Starting stress test with {highConcurrencyLevel} concurrent operations");
            
            // Act
            var tasks = Enumerable.Range(0, highConcurrencyLevel)
                .Select(i => Task.Run(async () =>
                {
                    try
                    {
                        using var scope = CreateIsolatedScope();
                        var db = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                        var indexing = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        // عملية عشوائية
                        var operation = Random.Shared.Next(0, 3);
                        switch (operation)
                        {
                            case 0: // إنشاء
                                var prop = TestDataBuilder.SimpleProperty($"{TestId}_stress_{i}");
                                await db.Properties.AddAsync(prop);
                                await db.SaveChangesAsync();
                                await indexing.OnPropertyCreatedAsync(prop.Id);
                                TrackEntity(prop.Id);
                                break;
                                
                            case 1: // بحث
                                var request = TestDataBuilder.SimpleSearchRequest();
                                await indexing.SearchAsync(request);
                                break;
                                
                            case 2: // تحديث
                                var props = await db.Properties.Take(1).ToListAsync();
                                if (props.Any())
                                {
                                    await indexing.OnPropertyUpdatedAsync(props.First().Id);
                                }
                                break;
                        }
                    }
                    catch (Exception ex)
                    {
                        errors.Add(ex);
                    }
                }));
            
            await Task.WhenAll(tasks);
            stopwatch.Stop();
            
            // Assert
            var errorRate = (errors.Count / (double)highConcurrencyLevel) * 100;
            errorRate.Should().BeLessThan(5, $"Error rate should be less than 5%, but was {errorRate:F2}%");
            
            Output.WriteLine($"✅ Stress test completed in {stopwatch.ElapsedMilliseconds}ms");
            Output.WriteLine($"   Total operations: {highConcurrencyLevel}");
            Output.WriteLine($"   Errors: {errors.Count} ({errorRate:F2}%)");
            Output.WriteLine($"   Success rate: {100 - errorRate:F2}%");
        }
        
        [Fact]
        public async Task ConcurrentUpdates_ToSameProperty_ShouldNotLoseData()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(TestId);
            
            using (var scope = CreateIsolatedScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                await db.Properties.AddAsync(property);
                await db.SaveChangesAsync();
            }
            
            TrackEntity(property.Id);
            
            const int concurrentUpdates = 20;
            var updateTasks = new List<Task>();
            
            // Act - تحديثات متزامنة لنفس العقار
            for (int i = 0; i < concurrentUpdates; i++)
            {
                var updateIndex = i;
                updateTasks.Add(Task.Run(async () =>
                {
                    using var scope = CreateIsolatedScope();
                    var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    
                    // تحديث الفهرسة
                    await indexingService.OnPropertyUpdatedAsync(property.Id);
                    
                    Output.WriteLine($"Update {updateIndex} completed at {DateTime.UtcNow:HH:mm:ss.fff}");
                }));
            }
            
            await Task.WhenAll(updateTasks);
            
            // Assert - التحقق من أن البيانات مازالت متسقة
            var finalData = await GetRedisPropertyDataAsync(property.Id);
            finalData.Should().NotBeNull();
            
            Output.WriteLine($"✅ {concurrentUpdates} concurrent updates handled correctly");
        }
        
        #region Helper Methods
        
        private async Task VerifyBaseDataExistsAsync()
        {
            using var scope = CreateIsolatedScope();
            var db = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            // التحقق من PropertyTypes
            var propertyTypes = await db.PropertyTypes.ToListAsync();
            Output.WriteLine($"🔍 Checking PropertyTypes: Found {propertyTypes.Count}");
            
            if (propertyTypes.Count == 0)
            {
                Output.WriteLine("⚠️ PropertyTypes not found, trying to initialize...");
                
                // محاولة إعادة تحميل البيانات الأساسية
                await InitializeDatabaseAsync();
                
                // التحقق مرة أخرى
                propertyTypes = await db.PropertyTypes.ToListAsync();
                Output.WriteLine($"🔍 After initialization: PropertyTypes count = {propertyTypes.Count}");
            }
            
            foreach(var pt in propertyTypes.Take(5))
            {
                Output.WriteLine($"   - PropertyType: {pt.Id} = {pt.Name}");
            }
            
            // التحقق من Cities
            var cities = await db.Cities.ToListAsync();
            Output.WriteLine($"🔍 Checking Cities: Found {cities.Count}");
            
            // التحقق من Currencies
            var currencies = await db.Currencies.ToListAsync();
            Output.WriteLine($"🔍 Checking Currencies: Found {currencies.Count}");
            
            // إذا لم توجد بيانات أساسية
            if (propertyTypes.Count == 0 || cities.Count == 0 || currencies.Count == 0)
            {
                throw new InvalidOperationException("⛔ Base data is missing! Cannot proceed with tests.");
            }
        }
        
        private async Task<bool> CreatePropertyConcurrentlyAsync(
            int index,
            System.Collections.Concurrent.ConcurrentBag<Guid> propertyIds,
            System.Collections.Concurrent.ConcurrentBag<Exception> errors)
        {
            var stopwatch = Stopwatch.StartNew();
            
            await _concurrencyLimiter.WaitAsync();
            try
            {
                // كل thread يستخدم scope منفصل
                using var scope = CreateIsolatedScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                
                // إنشاء عقار فريد
                var property = TestDataBuilder.SimpleProperty($"{TestId}_concurrent_{index}");
                
                // حفظ في قاعدة البيانات
                await dbContext.Properties.AddAsync(property);
                await dbContext.SaveChangesAsync();
                
                // فهرسة
                await indexingService.OnPropertyCreatedAsync(property.Id);
                
                propertyIds.Add(property.Id);
                
                stopwatch.Stop();
                RecordOperationTime(stopwatch.Elapsed);
                
                return true;
            }
            catch (Exception ex)
            {
                errors.Add(ex);
                Output.WriteLine($"❌ Error in thread {index}: {ex.Message}");
                if (ex.InnerException != null)
                {
                    Output.WriteLine($"   Inner: {ex.InnerException.Message}");
                }
                return false;
            }
            finally
            {
                _concurrencyLimiter.Release();
            }
        }
        
        private async Task<bool> CreateUnitConcurrentlyAsync(
            Guid propertyId,
            int index,
            System.Collections.Concurrent.ConcurrentBag<Guid> unitIds)
        {
            await _concurrencyLimiter.WaitAsync();
            try
            {
                using var scope = CreateIsolatedScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                
                var unit = TestDataBuilder.UnitForProperty(propertyId, $"{TestId}_unit_{index}");
                
                await dbContext.Units.AddAsync(unit);
                await dbContext.SaveChangesAsync();
                
                await indexingService.OnUnitCreatedAsync(unit.Id, propertyId);
                
                unitIds.Add(unit.Id);
                return true;
            }
            finally
            {
                _concurrencyLimiter.Release();
            }
        }
        
        private async Task<List<Property>> CreateTestPropertiesAsync(int count)
        {
            var properties = new List<Property>();
            
            using var scope = CreateIsolatedScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            for (int i = 0; i < count; i++)
            {
                var property = TestDataBuilder.SimpleProperty($"{TestId}_search_{i}");
                await dbContext.Properties.AddAsync(property);
                properties.Add(property);
                TrackEntity(property.Id);
            }
            
            await dbContext.SaveChangesAsync();
            
            // فهرسة كل العقارات
            foreach (var property in properties)
            {
                await indexingService.OnPropertyCreatedAsync(property.Id);
            }
            
            return properties;
        }
        
        private async Task<bool> VerifyAllPropertiesIndexedAsync(List<Property> properties)
        {
            foreach (var property in properties)
            {
                var data = await GetRedisPropertyDataAsync(property.Id);
                if (data == null) return false;
            }
            return true;
        }
        
        private async Task VerifyRedisDataConsistencyAsync(List<Guid> propertyIds)
        {
            foreach (var propertyId in propertyIds)
            {
                var redisData = await GetRedisPropertyDataAsync(propertyId);
                redisData.Should().NotBeNull($"Property {propertyId} should be indexed in Redis");
            }
        }
        
        private async Task<string> GetRedisPropertyDataAsync(Guid propertyId)
        {
            // IndexingService يستخدم مفتاحًا بدون test prefix
            var key = $"property:{propertyId}";
            return await RedisDatabase.StringGetAsync(key);
        }
        
        private void RecordOperationTime(TimeSpan time)
        {
            lock (_timesLock)
            {
                _operationTimes.Add(time);
            }
        }
        
        private void PrintPerformanceStats()
        {
            if (!_operationTimes.Any()) return;
            
            lock (_timesLock)
            {
                var avg = _operationTimes.Average(t => t.TotalMilliseconds);
                var min = _operationTimes.Min(t => t.TotalMilliseconds);
                var max = _operationTimes.Max(t => t.TotalMilliseconds);
                
                Output.WriteLine($"📊 Performance Stats:");
                Output.WriteLine($"   Average: {avg:F2}ms");
                Output.WriteLine($"   Min: {min:F2}ms");
                Output.WriteLine($"   Max: {max:F2}ms");
            }
        }
        
        #endregion
        
        public override void Dispose()
        {
            _concurrencyLimiter?.Dispose();
            base.Dispose();
        }
    }
}
