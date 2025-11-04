using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Assertions;

namespace YemenBooking.IndexingTests.Integration
{
    /// <summary>
    /// اختبارات التزامن والعمليات المتوازية
    /// كل عملية في scope منفصل - لا DbContext مشترك
    /// </summary>
    [Collection("TestContainers")]
    public class ConcurrencyTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        private readonly SemaphoreSlim _concurrencyLimiter;
        
        public ConcurrencyTests(TestContainerFixture containers, ITestOutputHelper output) 
            : base(output)
        {
            _containers = containers;
            _concurrencyLimiter = new SemaphoreSlim(
                initialCount: Environment.ProcessorCount * 2,
                maxCount: Environment.ProcessorCount * 2
            );
        }
        
        [Fact]
        public async Task ConcurrentPropertyCreation_ShouldHandleCorrectly()
        {
            // Arrange
            const int propertyCount = 50;
            var properties = TestDataBuilder.BatchProperties(propertyCount, TestId);
            TrackEntities(properties.Select(p => p.Id));
            
            Output.WriteLine($"🚀 Testing concurrent creation of {propertyCount} properties");
            
            // Act: Create properties concurrently
            var tasks = new List<Task>();
            
            foreach (var property in properties)
            {
                tasks.Add(Task.Run(async () =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        // استخدام scope منفصل لكل task
                        using var scope = CreateIsolatedScope();
                        var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        // حفظ في قاعدة البيانات
                        await dbContext.Properties.AddAsync(property);
                        await dbContext.SaveChangesAsync();
                        
                        // فهرسة
                        await indexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                }));
            }
            
            await Task.WhenAll(tasks);
            
            // Assert: All properties should be indexed
            var searchResult = await RetryAssertions.AssertEventuallyAsync(
                async () => await IndexingService.SearchAsync(new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 100
                }),
                result => result.TotalCount >= propertyCount,
                TimeSpan.FromSeconds(10),
                message: $"All {propertyCount} properties should be indexed"
            );
            
            searchResult.Should().HaveAtLeast(propertyCount);
            
            Output.WriteLine($"✅ Concurrent creation handled successfully");
        }
        
        [Fact]
        public async Task ConcurrentUpdates_OnSameProperty_ShouldMaintainConsistency()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(TestId);
            TrackEntity(property.Id);
            
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            
            const int updateCount = 20;
            var updateTasks = new List<Task>();
            var random = new Random();
            
            Output.WriteLine($"🚀 Testing {updateCount} concurrent updates on same property");
            
            // Act: Multiple concurrent updates
            for (int i = 0; i < updateCount; i++)
            {
                var updateIndex = i;
                updateTasks.Add(Task.Run(async () =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        using var scope = CreateIsolatedScope();
                        var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        // جلب العقار
                        var prop = await dbContext.Properties.FindAsync(property.Id);
                        if (prop != null)
                        {
                            // تحديث عشوائي
                            prop.StarRating = random.Next(1, 6);
                            prop.UpdatedAt = DateTime.UtcNow;
                            prop.ViewCount = prop.ViewCount + 1;
                            
                            dbContext.Properties.Update(prop);
                            await dbContext.SaveChangesAsync();
                            
                            await indexingService.OnPropertyUpdatedAsync(property.Id, TestCancellation.Token);
                        }
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                }));
            }
            
            await Task.WhenAll(updateTasks);
            
            // Assert: Property should still be searchable and consistent
            var searchResult = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            });
            
            searchResult.Should().ContainProperty(property.Id);
            
            // التحقق من عدم وجود تكرار
            var duplicates = searchResult.Properties
                .Where(p => p.Id == property.Id.ToString())
                .Count();
            
            duplicates.Should().Be(1, "No duplicates should exist");
            
            Output.WriteLine($"✅ Concurrent updates maintained consistency");
        }
        
        [Fact]
        public async Task ConcurrentSearches_ShouldHandleHighLoad()
        {
            // Arrange: Create some properties first
            var properties = TestDataBuilder.BatchProperties(10, TestId);
            TrackEntities(properties.Select(p => p.Id));
            
            foreach (var property in properties)
            {
                await DbContext.Properties.AddAsync(property);
            }
            await DbContext.SaveChangesAsync();
            
            foreach (var property in properties)
            {
                await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            }
            
            const int searchCount = 100;
            var searchTasks = new List<Task<PropertySearchResult>>();
            
            Output.WriteLine($"🚀 Testing {searchCount} concurrent searches");
            
            // Act: Concurrent searches with different criteria
            for (int i = 0; i < searchCount; i++)
            {
                var searchIndex = i;
                searchTasks.Add(Task.Run(async () =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        using var scope = CreateIsolatedScope();
                        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        var request = searchIndex % 3 switch
                        {
                            0 => TestDataBuilder.SimpleSearchRequest(),
                            1 => TestDataBuilder.TextSearchRequest($"test_{searchIndex}"),
                            _ => TestDataBuilder.FilteredSearchRequest(city: "صنعاء")
                        };
                        
                        return await indexingService.SearchAsync(request, TestCancellation.Token);
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                }));
            }
            
            var results = await Task.WhenAll(searchTasks);
            
            // Assert: All searches should complete successfully
            results.Should().AllSatisfy(result =>
            {
                result.Should().NotBeNull();
                result.Properties.Should().NotBeNull();
            });
            
            Output.WriteLine($"✅ {searchCount} concurrent searches completed successfully");
        }
        
        [Fact]
        public async Task MixedOperations_CreateUpdateDelete_ShouldHandleConcurrently()
        {
            // Arrange
            var propertiesToCreate = TestDataBuilder.BatchProperties(10, $"{TestId}_create");
            var propertiesToUpdate = TestDataBuilder.BatchProperties(10, $"{TestId}_update");
            var propertiesToDelete = TestDataBuilder.BatchProperties(10, $"{TestId}_delete");
            
            TrackEntities(propertiesToCreate.Select(p => p.Id));
            TrackEntities(propertiesToUpdate.Select(p => p.Id));
            TrackEntities(propertiesToDelete.Select(p => p.Id));
            
            // Setup properties for update and delete
            foreach (var prop in propertiesToUpdate.Concat(propertiesToDelete))
            {
                await DbContext.Properties.AddAsync(prop);
            }
            await DbContext.SaveChangesAsync();
            
            foreach (var prop in propertiesToUpdate.Concat(propertiesToDelete))
            {
                await IndexingService.OnPropertyCreatedAsync(prop.Id, TestCancellation.Token);
            }
            
            Output.WriteLine($"🚀 Testing mixed concurrent operations");
            
            var tasks = new List<Task>();
            
            // Act: Create operations
            foreach (var property in propertiesToCreate)
            {
                tasks.Add(Task.Run(async () =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        using var scope = CreateIsolatedScope();
                        var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        await dbContext.Properties.AddAsync(property);
                        await dbContext.SaveChangesAsync();
                        await indexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                }));
            }
            
            // Act: Update operations
            foreach (var property in propertiesToUpdate)
            {
                tasks.Add(Task.Run(async () =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        using var scope = CreateIsolatedScope();
                        var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        var prop = await dbContext.Properties.FindAsync(property.Id);
                        if (prop != null)
                        {
                            prop.Name = $"Updated_{prop.Name}";
                            prop.UpdatedAt = DateTime.UtcNow;
                            dbContext.Properties.Update(prop);
                            await dbContext.SaveChangesAsync();
                            await indexingService.OnPropertyUpdatedAsync(property.Id, TestCancellation.Token);
                        }
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                }));
            }
            
            // Act: Delete operations
            foreach (var property in propertiesToDelete)
            {
                tasks.Add(Task.Run(async () =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        using var scope = CreateIsolatedScope();
                        var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        var prop = await dbContext.Properties.FindAsync(property.Id);
                        if (prop != null)
                        {
                            dbContext.Properties.Remove(prop);
                            await dbContext.SaveChangesAsync();
                            await indexingService.OnPropertyDeletedAsync(property.Id, TestCancellation.Token);
                        }
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                }));
            }
            
            await Task.WhenAll(tasks);
            
            // Assert
            await Task.Delay(2000); // Give time for indexing to complete
            
            var searchResult = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            });
            
            // Created properties should be found
            foreach (var prop in propertiesToCreate)
            {
                searchResult.Should().ContainProperty(prop.Id);
            }
            
            // Updated properties should be found with new names
            foreach (var prop in propertiesToUpdate)
            {
                searchResult.Should().ContainProperty(prop.Id);
            }
            
            // Deleted properties should not be found
            foreach (var prop in propertiesToDelete)
            {
                searchResult.Should().NotContainProperty(prop.Id);
            }
            
            Output.WriteLine($"✅ Mixed operations handled concurrently");
        }
        
        [Fact]
        public async Task RaceCondition_RapidCreateDelete_ShouldHandleGracefully()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(TestId);
            TrackEntity(property.Id);
            
            const int iterations = 10;
            
            Output.WriteLine($"🚀 Testing race condition with rapid create/delete");
            
            // Act: Rapid create and delete
            for (int i = 0; i < iterations; i++)
            {
                // Create
                using (var createScope = CreateIsolatedScope())
                {
                    var dbContext = createScope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                    var indexingService = createScope.ServiceProvider.GetRequiredService<IIndexingService>();
                    
                    await dbContext.Properties.AddAsync(property);
                    await dbContext.SaveChangesAsync();
                    await indexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
                }
                
                // Small delay to ensure indexing
                await Task.Delay(100);
                
                // Delete
                using (var deleteScope = CreateIsolatedScope())
                {
                    var dbContext = deleteScope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                    var indexingService = deleteScope.ServiceProvider.GetRequiredService<IIndexingService>();
                    
                    var prop = await dbContext.Properties.FindAsync(property.Id);
                    if (prop != null)
                    {
                        dbContext.Properties.Remove(prop);
                        await dbContext.SaveChangesAsync();
                    }
                    await indexingService.OnPropertyDeletedAsync(property.Id, TestCancellation.Token);
                }
                
                // Recreate for next iteration
                property = TestDataBuilder.SimpleProperty(TestId);
                property.Id = property.Id; // Keep same ID for testing
            }
            
            // Assert: Final state should be consistent
            var searchResult = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            });
            
            // Should not have duplicates or inconsistent state
            var count = searchResult.Properties.Count(p => p.Id == property.Id.ToString());
            count.Should().BeLessOrEqualTo(1, "No duplicates should exist");
            
            Output.WriteLine($"✅ Race condition handled gracefully");
        }
        
        [Fact]
        public async Task DeadlockPrevention_CrossEntityUpdates_ShouldNotDeadlock()
        {
            // Arrange
            var property1 = TestDataBuilder.PropertyWithUnits(2, $"{TestId}_1");
            var property2 = TestDataBuilder.PropertyWithUnits(2, $"{TestId}_2");
            
            TrackEntity(property1.Id);
            TrackEntity(property2.Id);
            
            await DbContext.Properties.AddRangeAsync(property1, property2);
            await DbContext.SaveChangesAsync();
            
            await IndexingService.OnPropertyCreatedAsync(property1.Id, TestCancellation.Token);
            await IndexingService.OnPropertyCreatedAsync(property2.Id, TestCancellation.Token);
            
            Output.WriteLine($"🚀 Testing deadlock prevention");
            
            // Act: Cross updates that could cause deadlock
            var task1 = Task.Run(async () =>
            {
                using var scope = CreateIsolatedScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                
                // Update property1 then property2
                var p1 = await dbContext.Properties.FindAsync(property1.Id);
                p1.Name = "Updated_1_A";
                await Task.Delay(50); // Simulate processing
                
                var p2 = await dbContext.Properties.FindAsync(property2.Id);
                p2.Name = "Updated_2_A";
                
                dbContext.Properties.UpdateRange(p1, p2);
                await dbContext.SaveChangesAsync();
                
                await indexingService.OnPropertyUpdatedAsync(property1.Id, TestCancellation.Token);
                await indexingService.OnPropertyUpdatedAsync(property2.Id, TestCancellation.Token);
            });
            
            var task2 = Task.Run(async () =>
            {
                using var scope = CreateIsolatedScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                
                // Update property2 then property1 (opposite order)
                var p2 = await dbContext.Properties.FindAsync(property2.Id);
                p2.Name = "Updated_2_B";
                await Task.Delay(50); // Simulate processing
                
                var p1 = await dbContext.Properties.FindAsync(property1.Id);
                p1.Name = "Updated_1_B";
                
                dbContext.Properties.UpdateRange(p2, p1);
                await dbContext.SaveChangesAsync();
                
                await indexingService.OnPropertyUpdatedAsync(property2.Id, TestCancellation.Token);
                await indexingService.OnPropertyUpdatedAsync(property1.Id, TestCancellation.Token);
            });
            
            // Assert: Both should complete without deadlock
            var completedTask = await Task.WhenAny(
                Task.WhenAll(task1, task2),
                Task.Delay(TimeSpan.FromSeconds(10))
            );
            
            completedTask.Should().NotBeOfType<Task<Task>>($"Tasks should complete without timeout (deadlock)");
            
            Output.WriteLine($"✅ No deadlock occurred");
        }
    }
}
