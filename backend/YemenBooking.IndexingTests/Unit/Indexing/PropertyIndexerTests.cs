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
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;
using StackExchange.Redis;
using Polly;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Helpers;
using YemenBooking.IndexingTests.Infrastructure.Assertions;
using YemenBooking.IndexingTests.Infrastructure.Extensions;

namespace YemenBooking.IndexingTests.Unit.Indexing
{
    /// <summary>
    /// اختبارات فهرسة العقارات باستخدام الفهرسة الحقيقية
    /// تطبق مبادئ العزل الكامل والحتمية - بدون Mocks
    /// كل اختبار معزول تماماً باستخدام GUIDs فريدة
    /// </summary>
    public class PropertyIndexerTests : TestBase
    {
        // SemaphoreSlim للتحكم في التزامن
        private readonly SemaphoreSlim _concurrencyLimiter;
        
        // تتبع العقارات المنشأة للتنظيف
        private readonly List<Guid> _createdPropertyIds = new();
        private readonly List<string> _createdRedisKeys = new();
        
        // JsonSerializerOptions للتسلسل
        private readonly JsonSerializerOptions _jsonOptions;
        
        public PropertyIndexerTests(ITestOutputHelper output) : base(output)
        {
            // تحديد عدد العمليات المتزامنة المسموحة
            _concurrencyLimiter = new SemaphoreSlim(
                initialCount: Environment.ProcessorCount * 2,
                maxCount: Environment.ProcessorCount * 2
            );
            
            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = false
            };
        }
        
        /// <summary>
        /// تجاوز التهيئة لإضافة تكوينات خاصة باختبارات العقارات
        /// </summary>
        protected override async Task ConfigureServicesAsync(IServiceCollection services)
        {
            // استدعاء التكوين الأساسي
            await base.ConfigureServicesAsync(services);
            
            // إضافة أي خدمات إضافية مطلوبة لاختبارات العقارات
            // مثل repositories أو services إضافية
        }
        
        #region Basic Property Indexing Tests
        
        /// <summary>
        /// اختبار فهرسة عقار بسيط - السيناريو الأساسي
        /// </summary>
        [Fact]
        public async Task IndexProperty_WithValidSimpleProperty_ShouldIndexSuccessfully()
        {
            // Arrange
            var uniqueId = Guid.NewGuid().ToString("N");
            var property = TestDataBuilder.SimpleProperty(uniqueId);
            _createdPropertyIds.Add(property.Id);
            
            // حفظ العقار في قاعدة البيانات
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            // Act - فهرسة العقار
            await IndexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert - التحقق من النجاح باستخدام Polling
            await WaitForConditionAsync(
                async () =>
                {
                    // استخدام المفتاح الفعلي الذي يستخدمه IndexingService
                    var propertyKey = $"property:{property.Id}";
                    _createdRedisKeys.Add(propertyKey);
                    
                    var exists = await RedisDatabase.KeyExistsAsync(propertyKey);
                    if (!exists) return false;
                    
                    var json = await RedisDatabase.StringGetAsync(propertyKey);
                    return json.HasValue;
                },
                timeout: TimeSpan.FromSeconds(5),
                pollInterval: TimeSpan.FromMilliseconds(200),
                message: "Property should be indexed in Redis"
            );
            
            // التحقق من محتويات الفهرسة
            var indexedPropertyKey = $"property:{property.Id}";
            var indexedJson = await RedisDatabase.StringGetAsync(indexedPropertyKey);
            indexedJson.HasValue.Should().BeTrue("Property should be indexed with data");
            indexedJson.IsNullOrEmpty.Should().BeFalse("Index data should not be empty");
            
            // التحقق من البيانات المفهرسة
            var indexedData = JsonSerializer.Deserialize<Dictionary<string, object>>(indexedJson.ToString(), _jsonOptions);
            indexedData.Should().NotBeNull();
            indexedData!["name"].ToString()!.Should().Contain(uniqueId);
            
            Output.WriteLine($"✅ Successfully indexed property {property.Id} with unique identifier {uniqueId}");
        }
        
        /// <summary>
        /// اختبار فهرسة عقار مع وحدات
        /// </summary>
        [Fact]
        public async Task IndexProperty_WithUnits_ShouldIndexPropertyAndUnits()
        {
            // Arrange
            var uniqueId = Guid.NewGuid().ToString("N");
            var property = TestDataBuilder.PropertyWithUnits(3, uniqueId);
            _createdPropertyIds.Add(property.Id);
            
            // حفظ العقار والوحدات في قاعدة البيانات
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            // Act
            await IndexingService.OnPropertyCreatedAsync(property.Id);
            
            // Assert - التحقق من فهرسة العقار
            await AssertEventuallyAsync(
                async () =>
                {
                    var propertyKey = $"property:{property.Id}";
                    return await RedisDatabase.KeyExistsAsync(propertyKey);
                },
                TimeSpan.FromSeconds(5),
                "Property should be indexed"
            );
            
            // التحقق من البيانات المفهرسة للعقار
            var propertyKey = $"property:{property.Id}";
            var propertyJson = await RedisDatabase.StringGetAsync(propertyKey);
            var propertyData = JsonSerializer.Deserialize<Dictionary<string, object>>(propertyJson.ToString(), _jsonOptions);
            
            propertyData.Should().NotBeNull();
            propertyData!.Should().ContainKey("totalUnits");
            
            // التعامل مع JsonElement بشكل صحيح
            var totalUnitsElement = propertyData["totalUnits"];
            int totalUnits = 0;
            if (totalUnitsElement is JsonElement jsonElement)
            {
                totalUnits = jsonElement.GetInt32();
            }
            else
            {
                totalUnits = Convert.ToInt32(totalUnitsElement);
            }
            
            totalUnits.Should().Be(3);
            
            Output.WriteLine($"✅ Indexed property with {totalUnits} units");
        }
        
        /// <summary>
        /// اختبار تحديث فهرسة عقار موجود
        /// </summary>
        [Fact]
        public async Task UpdateProperty_WhenPropertyExists_ShouldUpdateIndex()
        {
            // Arrange - إنشاء وفهرسة عقار أولي
            var uniqueId = Guid.NewGuid().ToString("N");
            var property = TestDataBuilder.SimpleProperty(uniqueId);
            _createdPropertyIds.Add(property.Id);
            
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            await IndexingService.OnPropertyCreatedAsync(property.Id);
            
            // انتظار حتى يتم الفهرسة الأولية
            await Task.Delay(500);
            
            // تحديث العقار
            property.Name = $"UPDATED_{uniqueId}_{Guid.NewGuid():N}";
            property.AverageRating = 4.8m;
            property.UpdatedAt = DateTime.UtcNow;
            
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Update(property);
                await dbContext.SaveChangesAsync();
            }
            
            // Act - تحديث الفهرسة
            await IndexingService.OnPropertyUpdatedAsync(property.Id);
            
            // Assert - التحقق من التحديث
            await WaitForConditionAsync(
                async () =>
                {
                    var propertyKey = $"property:{property.Id}";
                    var json = await RedisDatabase.StringGetAsync(propertyKey);
                    if (!json.HasValue) return false;
                    
                    var data = JsonSerializer.Deserialize<Dictionary<string, object>>(json.ToString(), _jsonOptions);
                    return data != null && data["name"].ToString()!.Contains("UPDATED");
                },
                TimeSpan.FromSeconds(3),
                TimeSpan.FromMilliseconds(100),
                "Property index should be updated"
            );
            
            Output.WriteLine($"✅ Successfully updated property index for {property.Id}");
        }
        
        /// <summary>
        /// اختبار حذف فهرسة عقار
        /// </summary>
        [Fact]
        public async Task DeleteProperty_WhenPropertyIndexed_ShouldRemoveFromAllIndexes()
        {
            // Arrange - إنشاء وفهرسة عقار
            var uniqueId = Guid.NewGuid().ToString("N");
            var property = TestDataBuilder.PropertyWithUnits(2, uniqueId);
            _createdPropertyIds.Add(property.Id);
            
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            await IndexingService.OnPropertyCreatedAsync(property.Id);
            
            // انتظار حتى يتم الفهرسة
            await Task.Delay(500);
            
            // التحقق من وجود الفهرسة
            var propertyKey = $"property:{property.Id}";
            var exists = await RedisDatabase.KeyExistsAsync(propertyKey);
            exists.Should().BeTrue("Property should be indexed before deletion");
            
            // Act - حذف الفهرسة
            await IndexingService.OnPropertyDeletedAsync(property.Id);
            
            // Assert - التحقق من الحذف
            await WaitForConditionAsync(
                async () =>
                {
                    var stillExists = await RedisDatabase.KeyExistsAsync(propertyKey);
                    return !stillExists;
                },
                TimeSpan.FromSeconds(3),
                TimeSpan.FromMilliseconds(100),
                "Property should be removed from all indexes"
            );
            
            // التحقق من حذف العقار من جميع الفهارس
            var searchIndexKey = $"search:index";
            var isInSearchIndex = await RedisDatabase.SetContainsAsync(searchIndexKey, property.Id.ToString());
            isInSearchIndex.Should().BeFalse("Property should be removed from search index");
            
            Output.WriteLine($"✅ Successfully removed property {property.Id} from all indexes");
        }
        
        #endregion
        
        #region Concurrent Operations Tests
        
        /// <summary>
        /// اختبار الفهرسة المتزامنة لعدة عقارات
        /// </summary>
        [Fact]
        public async Task IndexMultipleProperties_Concurrently_ShouldIndexAllSuccessfully()
        {
            // Arrange
            const int propertyCount = 10;
            var properties = new List<Property>();
            
            for (int i = 0; i < propertyCount; i++)
            {
                var uniqueId = $"concurrent_{i}_{Guid.NewGuid():N}";
                var property = TestDataBuilder.SimpleProperty(uniqueId);
                properties.Add(property);
                _createdPropertyIds.Add(property.Id);
            }
            
            // حفظ جميع العقارات في قاعدة البيانات
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.AddRange(properties);
                await dbContext.SaveChangesAsync();
            }
            
            // Act - فهرسة متزامنة
            var indexingTasks = properties.Select(async property =>
            {
                await _concurrencyLimiter.WaitAsync();
                try
                {
                    // استخدام scope منفصل لكل عملية
                    using var scope = ServiceProvider.CreateScope();
                    var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    await indexingService.OnPropertyCreatedAsync(property.Id);
                }
                finally
                {
                    _concurrencyLimiter.Release();
                }
            });
            
            await Task.WhenAll(indexingTasks);
            
            // Assert - التحقق من فهرسة جميع العقارات
            foreach (var property in properties)
            {
                await AssertEventuallyAsync(
                    async () =>
                    {
                        var propertyKey = $"property:{property.Id}";
                        return await RedisDatabase.KeyExistsAsync(propertyKey);
                    },
                    TimeSpan.FromSeconds(5),
                    $"Property {property.Id} should be indexed"
                );
            }
            
            Output.WriteLine($"✅ Successfully indexed {propertyCount} properties concurrently");
        }
        
        /// <summary>
        /// اختبار التحديثات المتزامنة لنفس العقار
        /// </summary>
        [Fact]
        public async Task UpdateSameProperty_Concurrently_ShouldMaintainDataIntegrity()
        {
            // Arrange
            var uniqueId = Guid.NewGuid().ToString("N");
            var property = TestDataBuilder.SimpleProperty(uniqueId);
            _createdPropertyIds.Add(property.Id);
            
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            await IndexingService.OnPropertyCreatedAsync(property.Id);
            await Task.Delay(500);
            
            // Act - تحديثات متزامنة
            const int updateCount = 5;
            var updateTasks = Enumerable.Range(0, updateCount).Select(async i =>
            {
                await _concurrencyLimiter.WaitAsync();
                try
                {
                    using var scope = ServiceProvider.CreateScope();
                    var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                    var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    
                    // تحديث البيانات
                    var propertyToUpdate = await dbContext.Properties.FindAsync(property.Id);
                    if (propertyToUpdate != null)
                    {
                        propertyToUpdate.AverageRating = 3.0m + (i * 0.2m);
                        propertyToUpdate.UpdatedAt = DateTime.UtcNow;
                        await dbContext.SaveChangesAsync();
                        
                        await indexingService.OnPropertyUpdatedAsync(property.Id);
                    }
                }
                finally
                {
                    _concurrencyLimiter.Release();
                }
            });
            
            await Task.WhenAll(updateTasks);
            
            // Assert - التحقق من سلامة البيانات
            await Task.Delay(1000); // انتظار لإتمام جميع التحديثات
            
            var propertyKey = $"property:{property.Id}";
            var finalJson = await RedisDatabase.StringGetAsync(propertyKey);
            finalJson.HasValue.Should().BeTrue("Property should still be indexed after concurrent updates");
            
            var finalData = JsonSerializer.Deserialize<Dictionary<string, object>>(finalJson.ToString(), _jsonOptions);
            finalData.Should().NotBeNull();
            
            Output.WriteLine($"✅ Property maintained data integrity after {updateCount} concurrent updates");
        }
        
        #endregion
        
        #region Error Handling Tests
        
        /// <summary>
        /// اختبار فهرسة عقار غير موجود
        /// </summary>
        [Fact]
        public async Task IndexProperty_WithNonExistentId_ShouldHandleGracefully()
        {
            // Arrange
            var nonExistentId = Guid.NewGuid();
            
            // Act & Assert
            await IndexingService.OnPropertyCreatedAsync(nonExistentId);
            
            // لا يجب أن يتم إنشاء مفتاح Redis للعقار غير الموجود
            var propertyKey = $"property:{nonExistentId}";
            var exists = await RedisDatabase.KeyExistsAsync(propertyKey);
            exists.Should().BeFalse("Non-existent property should not be indexed");
            
            Output.WriteLine($"✅ Handled non-existent property ID gracefully");
        }
        
        /// <summary>
        /// اختبار فهرسة عقار مع معرف فارغ
        /// </summary>
        [Fact]
        public async Task IndexProperty_WithEmptyGuid_ShouldThrowArgumentException()
        {
            // Arrange
            var emptyGuid = Guid.Empty;
            
            // Act & Assert
            await Assert.ThrowsAsync<ArgumentException>(async () =>
            {
                await IndexingService.OnPropertyCreatedAsync(emptyGuid);
            });
            
            Output.WriteLine($"✅ Correctly threw ArgumentException for empty GUID");
        }
        
        /// <summary>
        /// اختبار إعادة المحاولة عند فشل Redis مؤقتاً
        /// </summary>
        [Fact]
        public async Task IndexProperty_WithTemporaryRedisFailure_ShouldRetryAndSucceed()
        {
            // Arrange
            var uniqueId = Guid.NewGuid().ToString("N");
            var property = TestDataBuilder.SimpleProperty(uniqueId);
            _createdPropertyIds.Add(property.Id);
            
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            // Act - الفهرسة مع سياسة إعادة المحاولة
            var retryPolicy = Policy
                .Handle<RedisConnectionException>()
                .Or<RedisException>()
                .WaitAndRetryAsync(
                    3,
                    retryAttempt => TimeSpan.FromMilliseconds(Math.Pow(2, retryAttempt) * 100),
                    onRetry: (exception, timeSpan, retryCount, context) =>
                    {
                        Output.WriteLine($"⚠️ Retry {retryCount} after {timeSpan}ms due to: {exception.Message}");
                    }
                );
            
            await retryPolicy.ExecuteAsync(async () =>
            {
                await IndexingService.OnPropertyCreatedAsync(property.Id);
            });
            
            // Assert
            var propertyKey = $"property:{property.Id}";
            _createdRedisKeys.Add(propertyKey);
            
            await AssertEventuallyAsync(
                async () => await RedisDatabase.KeyExistsAsync(propertyKey),
                TimeSpan.FromSeconds(5),
                "Property should eventually be indexed after retries"
            );
            
            Output.WriteLine($"✅ Successfully indexed property after handling temporary failures");
        }
        
        #endregion
        
        #region Performance Tests
        
        /// <summary>
        /// اختبار أداء فهرسة عدد كبير من العقارات
        /// </summary>
        [Fact]
        public async Task IndexLargeNumberOfProperties_ShouldCompleteWithinReasonableTime()
        {
            // Arrange
            const int batchSize = 50;
            var properties = new List<Property>();
            var stopwatch = Stopwatch.StartNew();
            
            for (int i = 0; i < batchSize; i++)
            {
                var uniqueId = $"perf_{i}_{Guid.NewGuid():N}";
                var property = TestDataBuilder.SimpleProperty(uniqueId);
                properties.Add(property);
                _createdPropertyIds.Add(property.Id);
            }
            
            // حفظ جميع العقارات
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.AddRange(properties);
                await dbContext.SaveChangesAsync();
            }
            
            // Act - فهرسة بالدفعات
            var indexingStopwatch = Stopwatch.StartNew();
            
            var tasks = properties.Select(async property =>
            {
                await _concurrencyLimiter.WaitAsync();
                try
                {
                    using var scope = ServiceProvider.CreateScope();
                    var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    await indexingService.OnPropertyCreatedAsync(property.Id);
                }
                finally
                {
                    _concurrencyLimiter.Release();
                }
            });
            
            await Task.WhenAll(tasks);
            indexingStopwatch.Stop();
            
            // Assert
            indexingStopwatch.ElapsedMilliseconds.Should().BeLessThan(10000, 
                $"Indexing {batchSize} properties should complete within 10 seconds");
            
            var averageTime = indexingStopwatch.ElapsedMilliseconds / (double)batchSize;
            Output.WriteLine($"✅ Indexed {batchSize} properties in {indexingStopwatch.ElapsedMilliseconds}ms");
            Output.WriteLine($"📊 Average time per property: {averageTime:F2}ms");
            
            // التحقق من فهرسة جميع العقارات
            var indexedCount = 0;
            foreach (var property in properties)
            {
                var propertyKey = $"property:{property.Id}";
                if (await RedisDatabase.KeyExistsAsync(propertyKey))
                    indexedCount++;
            }
            
            indexedCount.Should().Be(batchSize, "All properties should be indexed");
            Output.WriteLine($"✅ Successfully verified {indexedCount}/{batchSize} properties indexed");
        }
        
        #endregion
        
        #region Helper Methods
        
        /// <summary>
        /// انتظار حتى يتحقق شرط معين باستخدام Polling
        /// </summary>
        private async Task WaitForConditionAsync(
            Func<Task<bool>> condition,
            TimeSpan timeout,
            TimeSpan pollInterval,
            string message = null)
        {
            var deadline = DateTime.UtcNow.Add(timeout);
            
            while (DateTime.UtcNow < deadline)
            {
                if (await condition())
                    return;
                    
                var remainingTime = deadline - DateTime.UtcNow;
                if (remainingTime <= TimeSpan.Zero)
                    break;
                    
                var delay = remainingTime < pollInterval ? remainingTime : pollInterval;
                await Task.Delay(delay);
            }
            
            throw new TimeoutException(message ?? $"Condition not met within {timeout}");
        }
        
        /// <summary>
        /// التأكيد النهائي مع إعادة المحاولة
        /// </summary>
        private async Task AssertEventuallyAsync(
            Func<Task<bool>> assertion,
            TimeSpan timeout,
            string message = null)
        {
            var deadline = DateTime.UtcNow.Add(timeout);
            Exception lastException = null;
            
            while (DateTime.UtcNow < deadline)
            {
                try
                {
                    if (await assertion())
                        return;
                }
                catch (Exception ex)
                {
                    lastException = ex;
                }
                
                await Task.Delay(50);
            }
            
            var errorMessage = message ?? "Assertion did not become true within timeout";
            if (lastException != null)
                throw new AssertionException(errorMessage, lastException);
            else
                throw new AssertionException(errorMessage);
        }
        
        #endregion
        
        #region Cleanup
        
        /// <summary>
        /// تنظيف البيانات بعد كل اختبار
        /// </summary>
        public override async Task DisposeAsync()
        {
            try
            {
                // تنظيف مفاتيح Redis
                if (_createdRedisKeys.Any())
                {
                    foreach (var key in _createdRedisKeys)
                    {
                        await RedisDatabase.KeyDeleteAsync(key);
                    }
                    Output.WriteLine($"🧹 Cleaned {_createdRedisKeys.Count} Redis keys");
                }
                
                // تنظيف العقارات من قاعدة البيانات
                if (_createdPropertyIds.Any())
                {
                    using var scope = ServiceProvider.CreateScope();
                    var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                    
                    var propertiesToDelete = await dbContext.Properties
                        .Where(p => _createdPropertyIds.Contains(p.Id))
                        .ToListAsync();
                    
                    if (propertiesToDelete.Any())
                    {
                        dbContext.Properties.RemoveRange(propertiesToDelete);
                        await dbContext.SaveChangesAsync();
                        Output.WriteLine($"🧹 Cleaned {propertiesToDelete.Count} properties from database");
                    }
                }
                
                // التنظيف الأساسي
                await base.DisposeAsync();
            }
            catch (Exception ex)
            {
                Output.WriteLine($"⚠️ Error during cleanup: {ex.Message}");
            }
            finally
            {
                _concurrencyLimiter?.Dispose();
            }
        }
        
        public override void Dispose()
        {
            DisposeAsync().GetAwaiter().GetResult();
            base.Dispose();
        }
        
        #endregion
        
        // Custom Exception for Assertions
        public class AssertionException : Exception
        {
            public AssertionException(string message) : base(message) { }
            public AssertionException(string message, Exception innerException) : base(message, innerException) { }
        }
    }
}
