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
using YemenBooking.IndexingTests.Infrastructure.Utilities;

namespace YemenBooking.IndexingTests.Integration
{
    /// <summary>
    /// اختبارات تدفق الفهرسة الكامل
    /// </summary>
    [Collection("TestContainers")]
    public class IndexingFlowTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        
        public IndexingFlowTests(TestContainerFixture containers, ITestOutputHelper output) 
            : base(output)
        {
            _containers = containers;
        }
        
        [Fact]
        public async Task CompleteIndexingFlow_FromCreationToSearch_ShouldWork()
        {
            // Arrange
            Output.WriteLine("🚀 Testing complete indexing flow");
            
            var property = TestDataBuilder.CompleteProperty(TestId);
            TrackEntity(property.Id);
            
            // Act 1: Create property
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            Output.WriteLine($"✅ Property {property.Id} saved to database");
            
            // Act 2: Index property
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            Output.WriteLine($"✅ Property {property.Id} indexed");
            
            // Act 3: Index units
            foreach (var unit in property.Units)
            {
                await IndexingService.OnUnitCreatedAsync(unit.Id, property.Id, TestCancellation.Token);
            }
            Output.WriteLine($"✅ {property.Units.Count} units indexed");
            
            // Act 4: Search for property
            var searchResult = await RetryAssertions.AssertEventuallyAsync(
                async () => await IndexingService.SearchAsync(new PropertySearchRequest
                {
                    SearchText = property.Name,
                    PageNumber = 1,
                    PageSize = 10
                }),
                result => result.TotalCount > 0,
                TimeSpan.FromSeconds(5),
                message: "Property should be searchable after indexing"
            );
            
            // Assert
            searchResult.Should().ContainProperty(property.Id);
            
            var foundProperty = searchResult.Properties.First(p => p.Id == property.Id.ToString());
            foundProperty.Name.Should().Be(property.Name);
            foundProperty.City.Should().Be(property.City);
            foundProperty.UnitsCount.Should().Be(property.Units.Count);
            
            Output.WriteLine($"✅ Complete flow successful");
        }
        
        [Fact]
        public async Task UpdateFlow_ShouldReflectChangesInSearch()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(TestId);
            property.City = "صنعاء";
            property.StarRating = 3;
            TrackEntity(property.Id);
            
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            
            // Act 1: Update property
            property.City = "عدن";
            property.StarRating = 5;
            property.UpdatedAt = DateTime.UtcNow;
            
            DbContext.Properties.Update(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyUpdatedAsync(property.Id, TestCancellation.Token);
            
            // Assert: Search in new city
            var newCitySearch = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                City = "عدن",
                PageNumber = 1,
                PageSize = 10
            });
            
            newCitySearch.Should().ContainProperty(property.Id);
            
            // Assert: Not in old city
            var oldCitySearch = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                City = "صنعاء",
                PageNumber = 1,
                PageSize = 10
            });
            
            oldCitySearch.Should().NotContainProperty(property.Id);
            
            Output.WriteLine($"✅ Update flow working correctly");
        }
        
        [Fact]
        public async Task DeletionFlow_ShouldRemoveFromSearch()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(TestId);
            TrackEntity(property.Id);
            
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            
            // Verify indexed
            var beforeDelete = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            });
            
            beforeDelete.Should().ContainProperty(property.Id);
            
            // Act: Delete property
            DbContext.Properties.Remove(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyDeletedAsync(property.Id, TestCancellation.Token);
            
            // Assert: Should not be in search
            var afterDelete = await RetryAssertions.AssertEventuallyAsync(
                async () => await IndexingService.SearchAsync(new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 100
                }),
                result => !result.Properties.Any(p => p.Id == property.Id.ToString()),
                TimeSpan.FromSeconds(5),
                message: "Property should be removed from search after deletion"
            );
            
            afterDelete.Should().NotContainProperty(property.Id);
            
            Output.WriteLine($"✅ Deletion flow working correctly");
        }
        
        [Fact]
        public async Task BulkIndexing_ShouldHandleMultipleProperties()
        {
            // Arrange
            const int propertyCount = 20;
            var properties = TestDataBuilder.BatchProperties(propertyCount, TestId);
            TrackEntities(properties.Select(p => p.Id));
            
            Output.WriteLine($"🚀 Bulk indexing {propertyCount} properties");
            
            // Act: Save all properties
            await DbContext.Properties.AddRangeAsync(properties);
            await DbContext.SaveChangesAsync();
            
            // Act: Index all properties
            var indexingTasks = properties.Select(p => 
                IndexingService.OnPropertyCreatedAsync(p.Id, TestCancellation.Token)
            );
            
            await Task.WhenAll(indexingTasks);
            
            // Assert: All should be searchable
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
            
            foreach (var property in properties)
            {
                searchResult.Should().ContainProperty(property.Id);
            }
            
            Output.WriteLine($"✅ Bulk indexing successful");
        }
        
        [Fact]
        public async Task AvailabilityFlow_ShouldUpdateCorrectly()
        {
            // Arrange
            var property = TestDataBuilder.PropertyWithUnits(2, TestId);
            TrackEntity(property.Id);
            
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            
            var unit = property.Units.First();
            var availableRanges = new List<(DateTime Start, DateTime End)>
            {
                (DateTime.Today.AddDays(1), DateTime.Today.AddDays(5)),
                (DateTime.Today.AddDays(10), DateTime.Today.AddDays(15))
            };
            
            // Act: Update availability
            await IndexingService.OnAvailabilityChangedAsync(
                unit.Id,
                property.Id,
                availableRanges,
                TestCancellation.Token
            );
            
            // Assert: Search with date range
            var searchWithDates = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                CheckIn = DateTime.Today.AddDays(2),
                CheckOut = DateTime.Today.AddDays(4),
                PageNumber = 1,
                PageSize = 10
            });
            
            // The property should be available for these dates
            searchWithDates.Properties.Should().NotBeEmpty();
            
            Output.WriteLine($"✅ Availability flow working");
        }
        
        [Fact]
        public async Task PricingFlow_ShouldUpdateCorrectly()
        {
            // Arrange
            var property = TestDataBuilder.PropertyWithUnits(1, TestId);
            var unit = property.Units.First();
            unit.BasePrice = new Core.ValueObjects.Money(100, "YER");
            TrackEntity(property.Id);
            
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            await IndexingService.OnUnitCreatedAsync(unit.Id, property.Id, TestCancellation.Token);
            
            // Act: Update pricing
            var pricingRules = new List<PricingRule>
            {
                new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = unit.Id,
                    PriceType = "seasonal",
                    PriceAmount = 120,
                    PercentageChange = 20,
                    PricingTier = "high_season",
                    Currency = "YER",
                    StartDate = DateTime.Today.AddDays(30),
                    EndDate = DateTime.Today.AddDays(60),
                    CreatedAt = DateTime.UtcNow
                }
            };
            
            await IndexingService.OnPricingRuleChangedAsync(
                unit.Id,
                property.Id,
                pricingRules,
                TestCancellation.Token
            );
            
            // Assert: Search with price filter
            var searchWithPrice = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                MinPrice = 80,
                MaxPrice = 150,
                PageNumber = 1,
                PageSize = 10
            });
            
            searchWithPrice.Should().ContainProperty(property.Id);
            
            Output.WriteLine($"✅ Pricing flow working");
        }
        
        [Fact]
        public async Task DynamicFieldsFlow_ShouldIndexAndSearchCorrectly()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(TestId);
            TrackEntity(property.Id);
            
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            
            // Act: Add dynamic fields
            await IndexingService.OnDynamicFieldChangedAsync(
                property.Id,
                "pet_friendly",
                "true",
                isAdd: true,
                TestCancellation.Token
            );
            
            await IndexingService.OnDynamicFieldChangedAsync(
                property.Id,
                "has_pool",
                "true",
                isAdd: true,
                TestCancellation.Token
            );
            
            // Assert: Search with dynamic fields
            var searchWithDynamicFields = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                DynamicFieldFilters = new Dictionary<string, string>
                {
                    ["pet_friendly"] = "true"
                },
                PageNumber = 1,
                PageSize = 10
            });
            
            searchWithDynamicFields.Should().ContainProperty(property.Id);
            
            Output.WriteLine($"✅ Dynamic fields flow working");
        }
        
        [Fact]
        public async Task TransactionFlow_ShouldMaintainConsistency()
        {
            // Arrange
            var property = TestDataBuilder.PropertyWithUnits(3, TestId);
            TrackEntity(property.Id);
            
            // Act: Use transaction for multiple operations
            using (var transaction = await DbContext.Database.BeginTransactionAsync())
            {
                try
                {
                    await DbContext.Properties.AddAsync(property);
                    await DbContext.SaveChangesAsync();
                    
                    // Index property
                    await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
                    
                    // Index all units
                    foreach (var unit in property.Units)
                    {
                        await IndexingService.OnUnitCreatedAsync(unit.Id, property.Id, TestCancellation.Token);
                    }
                    
                    await transaction.CommitAsync();
                }
                catch
                {
                    await transaction.RollbackAsync();
                    throw;
                }
            }
            
            // Assert: Everything should be indexed
            var searchResult = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            });
            
            searchResult.Should().ContainProperty(property.Id);
            
            var foundProperty = searchResult.Properties.First(p => p.Id == property.Id.ToString());
            foundProperty.UnitsCount.Should().Be(property.Units.Count);
            
            Output.WriteLine($"✅ Transaction flow maintained consistency");
        }
    }
}
