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
using Microsoft.EntityFrameworkCore;
using StackExchange.Redis;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Assertions;
using YemenBooking.IndexingTests.Infrastructure.Extensions;

namespace YemenBooking.IndexingTests.Unit.Search
{
    /// <summary>
    /// اختبارات البحث النصي باستخدام الفهرسة الحقيقية
    /// تطبق مبادئ العزل الكامل والحتمية
    /// بدون استخدام Mocks - كل شيء حقيقي
    /// </summary>
    public class TextSearchTests : TestBase
    {
        private readonly SemaphoreSlim _concurrencyLimiter;
        private readonly List<Guid> _createdPropertyIds = new();
        private readonly List<string> _createdRedisKeys = new();
        
        public TextSearchTests(ITestOutputHelper output) : base(output)
        {
            _concurrencyLimiter = new SemaphoreSlim(
                initialCount: Environment.ProcessorCount * 2,
                maxCount: Environment.ProcessorCount * 2
            );
        }
        
        #region Basic Search Tests
        
        [Fact]
        public async Task SearchAsync_WithEmptyRequest_ShouldReturnAllActiveProperties()
        {
            // Arrange
            var uniqueTestId = $"empty_search_{Guid.NewGuid():N}".Substring(0, 20);
            var properties = new List<Property>();
            
            // إنشاء 3 عقارات نشطة
            for (int i = 0; i < 3; i++)
            {
                var property = TestDataBuilder.SimpleProperty($"{uniqueTestId}_{i}");
                property.IsActive = true;
                property.IsApproved = true;
                properties.Add(property);
                _createdPropertyIds.Add(property.Id);
            }
            
            // حفظ العقارات في قاعدة البيانات
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.AddRange(properties);
                await dbContext.SaveChangesAsync();
            }
            
            // فهرسة جميع العقارات
            foreach (var property in properties)
            {
                await IndexingService.OnPropertyCreatedAsync(property.Id);
            }
            
            // انتظار حتى تتم الفهرسة
            await Task.Delay(500);
            
            // Act - البحث بدون معايير
            var request = TestDataBuilder.SimpleSearchRequest();
            var result = await IndexingService.SearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            result.TotalCount.Should().BeGreaterThanOrEqualTo(properties.Count, 
                "Should return at least the created properties");
            
            // التحقق من وجود العقارات المنشأة في النتائج
            var propertyIds = result.Properties.Select(p => Guid.Parse(p.Id)).ToList();
            foreach (var property in properties)
            {
                propertyIds.Should().Contain(property.Id, 
                    $"Property {property.Name} should be in search results");
            }
            
            Output.WriteLine($"✅ Empty search returned {result.TotalCount} properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithTextSearch_ShouldFilterByText()
        {
            // Arrange
            var uniqueTestId = $"text_{Guid.NewGuid():N}".Substring(0, 15);
            var searchText = "فندق_مميز";
            
            // إنشاء عقارات بأسماء مختلفة
            var matchingProperty1 = TestDataBuilder.SimpleProperty($"{uniqueTestId}_1");
            matchingProperty1.Name = $"فندق_مميز الأول {uniqueTestId}";
            matchingProperty1.IsActive = true;
            matchingProperty1.IsApproved = true;
            
            var matchingProperty2 = TestDataBuilder.SimpleProperty($"{uniqueTestId}_2");
            matchingProperty2.Name = $"فندق_مميز الثاني {uniqueTestId}";
            matchingProperty2.IsActive = true;
            matchingProperty2.IsApproved = true;
            
            var nonMatchingProperty = TestDataBuilder.SimpleProperty($"{uniqueTestId}_3");
            nonMatchingProperty.Name = $"شقة سكنية {uniqueTestId}";
            nonMatchingProperty.IsActive = true;
            nonMatchingProperty.IsApproved = true;
            
            _createdPropertyIds.AddRange(new[] { 
                matchingProperty1.Id, 
                matchingProperty2.Id, 
                nonMatchingProperty.Id 
            });
            
            // حفظ العقارات
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.AddRange(new[] { 
                    matchingProperty1, 
                    matchingProperty2, 
                    nonMatchingProperty 
                });
                await dbContext.SaveChangesAsync();
            }
            
            // فهرسة العقارات
            await IndexingService.OnPropertyCreatedAsync(matchingProperty1.Id);
            await IndexingService.OnPropertyCreatedAsync(matchingProperty2.Id);
            await IndexingService.OnPropertyCreatedAsync(nonMatchingProperty.Id);
            
            await Task.Delay(500);
            
            // Act - البحث بالنص
            var request = TestDataBuilder.TextSearchRequest(searchText);
            var result = await IndexingService.SearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            result.Properties.Should().NotBeNull();
            
            var foundProperties = result.Properties
                .Where(p => p.Name != null && p.Name.Contains(searchText))
                .ToList();
                
            foundProperties.Should().HaveCountGreaterThanOrEqualTo(2, 
                "Should find at least the two matching properties");
            
            Output.WriteLine($"✅ Text search for '{searchText}' found {foundProperties.Count} properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithPartialText_ShouldMatchPrefix()
        {
            // Arrange
            var uniqueTestId = $"partial_{Guid.NewGuid():N}".Substring(0, 15);
            var baseText = "منتجع_سياحي";
            
            var property = TestDataBuilder.SimpleProperty(uniqueTestId);
            property.Name = $"{baseText}_رائع {uniqueTestId}";
            property.IsActive = true;
            property.IsApproved = true;
            _createdPropertyIds.Add(property.Id);
            
            // حفظ العقار
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            // فهرسة العقار
            await IndexingService.OnPropertyCreatedAsync(property.Id);
            await Task.Delay(500);
            
            // Act - البحث بجزء من النص
            var request = TestDataBuilder.TextSearchRequest("منتجع");
            var result = await IndexingService.SearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            var foundProperty = result.Properties
                .FirstOrDefault(p => p.Id == property.Id.ToString());
                
            Assert.NotNull(foundProperty); // Should find property with partial text match
            
            Output.WriteLine($"✅ Partial text search matched property: {property.Name}");
        }
        
        [Fact]
        public async Task SearchAsync_WithMultipleWords_ShouldMatchAll()
        {
            // Arrange
            var uniqueTestId = $"multi_{Guid.NewGuid():N}".Substring(0, 15);
            
            var property = TestDataBuilder.SimpleProperty(uniqueTestId);
            property.Name = $"فندق خمس نجوم {uniqueTestId}";
            property.Description = "موقع ممتاز وخدمات راقية";
            property.IsActive = true;
            property.IsApproved = true;
            _createdPropertyIds.Add(property.Id);
            
            // حفظ العقار
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            // فهرسة العقار
            await IndexingService.OnPropertyCreatedAsync(property.Id);
            await Task.Delay(500);
            
            // Act - البحث بكلمات متعددة
            var request = TestDataBuilder.TextSearchRequest("فندق نجوم");
            var result = await IndexingService.SearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            var foundProperty = result.Properties
                .FirstOrDefault(p => p.Id == property.Id.ToString());
                
            Assert.NotNull(foundProperty); // Should find property matching multiple words
            
            Output.WriteLine($"✅ Multiple words search found property: {property.Name}");
        }
        
        #endregion
        
        #region Case Sensitivity Tests
        
        [Fact]
        public async Task SearchAsync_WithDifferentCase_ShouldBeCaseInsensitive()
        {
            // Arrange
            var uniqueTestId = $"case_{Guid.NewGuid():N}".Substring(0, 15);
            
            var property = TestDataBuilder.SimpleProperty(uniqueTestId);
            property.Name = $"HOTEL GRAND {uniqueTestId}";
            property.IsActive = true;
            property.IsApproved = true;
            _createdPropertyIds.Add(property.Id);
            
            // حفظ العقار
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            // فهرسة العقار
            await IndexingService.OnPropertyCreatedAsync(property.Id);
            await Task.Delay(500);
            
            // Act - البحث بحالة أحرف مختلفة
            var request = TestDataBuilder.TextSearchRequest("hotel grand");
            var result = await IndexingService.SearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            var foundProperty = result.Properties
                .FirstOrDefault(p => p.Name != null && 
                    p.Name.ToLower().Contains("hotel") && 
                    p.Name.ToLower().Contains("grand"));
                    
            Assert.NotNull(foundProperty); // Search should be case insensitive
            
            Output.WriteLine($"✅ Case insensitive search worked correctly");
        }
        
        #endregion
        
        #region Pagination Tests
        
        [Fact]
        public async Task SearchAsync_WithPagination_ShouldReturnCorrectPage()
        {
            // Arrange
            var uniqueTestId = $"page_{Guid.NewGuid():N}".Substring(0, 10);
            var properties = new List<Property>();
            
            // إنشاء 25 عقار
            for (int i = 0; i < 25; i++)
            {
                var property = TestDataBuilder.SimpleProperty($"{uniqueTestId}_{i:D2}");
                property.Name = $"عقار_رقم_{i:D2} {uniqueTestId}";
                property.IsActive = true;
                property.IsApproved = true;
                properties.Add(property);
                _createdPropertyIds.Add(property.Id);
            }
            
            // حفظ العقارات
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.AddRange(properties);
                await dbContext.SaveChangesAsync();
            }
            
            // فهرسة العقارات
            foreach (var property in properties)
            {
                await IndexingService.OnPropertyCreatedAsync(property.Id);
            }
            
            await Task.Delay(1000);
            
            // Act - البحث مع التصفح
            var request1 = new PropertySearchRequest
            {
                SearchText = uniqueTestId,
                PageNumber = 1,
                PageSize = 10
            };
            var result1 = await IndexingService.SearchAsync(request1);
            
            var request2 = new PropertySearchRequest
            {
                SearchText = uniqueTestId,
                PageNumber = 2,
                PageSize = 10
            };
            var result2 = await IndexingService.SearchAsync(request2);
            
            // Assert
            result1.Should().NotBeNull();
            result1.Properties.Count.Should().BeLessThanOrEqualTo(10, "Page size should be respected");
            
            result2.Should().NotBeNull();
            result2.Properties.Count.Should().BeLessThanOrEqualTo(10, "Page size should be respected");
            
            // التحقق من عدم تكرار العناصر بين الصفحات
            var page1Ids = result1.Properties.Select(p => p.Id).ToList();
            var page2Ids = result2.Properties.Select(p => p.Id).ToList();
            
            page1Ids.Intersect(page2Ids).Should().BeEmpty("Pages should not have duplicate items");
            
            Output.WriteLine($"✅ Pagination working correctly - Page 1: {result1.Properties.Count} items, Page 2: {result2.Properties.Count} items");
        }
        
        #endregion
        
        #region Special Characters Tests
        
        [Fact]
        public async Task SearchAsync_WithSpecialCharacters_ShouldHandleCorrectly()
        {
            // Arrange
            var uniqueTestId = $"spec_{Guid.NewGuid():N}".Substring(0, 10);
            
            var property = TestDataBuilder.SimpleProperty(uniqueTestId);
            property.Name = $"فندق@النجمة#الذهبية {uniqueTestId}";
            property.IsActive = true;
            property.IsApproved = true;
            _createdPropertyIds.Add(property.Id);
            
            // حفظ العقار
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                dbContext.Properties.Add(property);
                await dbContext.SaveChangesAsync();
            }
            
            // فهرسة العقار
            await IndexingService.OnPropertyCreatedAsync(property.Id);
            await Task.Delay(500);
            
            // Act - البحث بالرموز الخاصة
            var request = TestDataBuilder.TextSearchRequest("النجمة");
            var result = await IndexingService.SearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            var foundProperty = result.Properties
                .FirstOrDefault(p => p.Id == property.Id.ToString());
                
            Assert.NotNull(foundProperty); // Should handle special characters in search
            
            Output.WriteLine($"✅ Special characters handled correctly in search");
        }
        
        #endregion
        
        #region Performance Tests
        
        [Fact]
        public async Task SearchAsync_WithLargeDataset_ShouldPerformQuickly()
        {
            // Arrange
            var uniqueTestId = $"perf_{Guid.NewGuid():N}".Substring(0, 10);
            var properties = new List<Property>();
            
            // إنشاء 100 عقار
            for (int i = 0; i < 100; i++)
            {
                var property = TestDataBuilder.SimpleProperty($"{uniqueTestId}_{i:D3}");
                property.IsActive = true;
                property.IsApproved = true;
                properties.Add(property);
                _createdPropertyIds.Add(property.Id);
            }
            
            // حفظ العقارات بدفعات
            using (var scope = ServiceProvider.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                
                foreach (var batch in properties.Chunk(25))
                {
                    dbContext.Properties.AddRange(batch);
                    await dbContext.SaveChangesAsync();
                }
            }
            
            // فهرسة العقارات بشكل متزامن
            var indexingTasks = properties.Select(async property =>
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
            
            await Task.WhenAll(indexingTasks);
            await Task.Delay(1000);
            
            // Act - قياس وقت البحث
            var stopwatch = Stopwatch.StartNew();
            var request = TestDataBuilder.SimpleSearchRequest();
            var result = await IndexingService.SearchAsync(request);
            stopwatch.Stop();
            
            // Assert
            result.Should().NotBeNull();
            stopwatch.ElapsedMilliseconds.Should().BeLessThan(1000, 
                "Search should complete within 1 second even with large dataset");
            
            Output.WriteLine($"✅ Search in {properties.Count} properties completed in {stopwatch.ElapsedMilliseconds}ms");
        }
        
        #endregion
        
        #region Cleanup
        
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
    }
}
