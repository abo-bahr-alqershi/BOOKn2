using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using FluentAssertions;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Helpers;
using YemenBooking.IndexingTests.Infrastructure.Builders;

namespace YemenBooking.IndexingTests.Integration
{
    /// <summary>
    /// اختبارات تكاملية للبحث - تستخدم Redis و PostgreSQL الحقيقيين
    /// تطبق مبادئ العزل الكامل والحتمية
    /// </summary>
    [Collection("TestContainers")]
    public class SearchIntegrationTests : TestBase
    {
        private IndexingTestHelper _indexingHelper;
        private SearchEngine _searchEngine;
        
        public SearchIntegrationTests(ITestOutputHelper output) : base(output)
        {
            // التهيئة ستتم في InitializeAsync بعد إنشاء ServiceProvider
        }
        
        protected override bool UseTestContainers() => true;
        
        /// <summary>
        /// تهيئة الخدمات بعد إنشاء ServiceProvider
        /// </summary>
        public override async Task InitializeAsync()
        {
            await base.InitializeAsync();
            
            // استخدام ServiceProvider الرئيسي وليس scope
            var logger = ServiceProvider.GetRequiredService<ILogger<IndexingTestHelper>>();
            _indexingHelper = new IndexingTestHelper(ServiceProvider, logger);
            
            // إنشاء SearchEngine باستخدام الخدمات المهيئة
            _searchEngine = new SearchEngine(
                RedisManager,
                ServiceProvider,
                Logger);
        }
        
        [Fact]
        public async Task SearchAsync_WithEmptyRequest_ShouldReturnAllActiveProperties()
        {
            // Arrange
            var properties = await _indexingHelper.SetupIndexedPropertiesAsync(3, TestId);
            var request = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 10
            };
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            result.TotalCount.Should().BeGreaterThanOrEqualTo(properties.Count);
            result.Properties.Should().NotBeEmpty();
            
            // التحقق من وجود العقارات المُنشأة
            var createdIds = properties.Select(p => p.Id.ToString()).ToList();
            var returnedIds = result.Properties.Select(p => p.Id).ToList();
            
            foreach (var id in createdIds)
            {
                returnedIds.Should().Contain(id, $"Property {id} should be in search results");
            }
            
            Output.WriteLine($"✅ Empty search returned {result.TotalCount} properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithTextSearch_ShouldFilterByText()
        {
            // Arrange
            var hotelNames = new[] { "فندق الخليج", "فندق النخيل", "فندق السلام" };
            var villaNames = new[] { "فيلا الورد", "فيلا البحر" };
            
            var hotels = await _indexingHelper.SetupPropertiesWithTextAsync(hotelNames);
            var villas = await _indexingHelper.SetupPropertiesWithTextAsync(villaNames);
            
            var request = new PropertySearchRequest
            {
                SearchText = "فندق",
                PageNumber = 1,
                PageSize = 10
            };
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            result.TotalCount.Should().BeGreaterThanOrEqualTo(hotels.Count);
            
            // يجب أن تحتوي النتائج على الفنادق فقط
            var hotelIds = hotels.Select(h => h.Id.ToString()).ToList();
            var villaIds = villas.Select(v => v.Id.ToString()).ToList();
            var resultIds = result.Properties.Select(p => p.Id).ToList();
            
            foreach (var hotelId in hotelIds)
            {
                resultIds.Should().Contain(hotelId);
            }
            
            foreach (var villaId in villaIds)
            {
                resultIds.Should().NotContain(villaId);
            }
            
            Output.WriteLine($"✅ Text search for 'فندق' returned {result.TotalCount} hotels");
        }
        
        [Theory]
        [InlineData("HOTEL")]
        [InlineData("hotel")]
        [InlineData("HoTeL")]
        [InlineData("فندق")]
        public async Task SearchAsync_WithTextSearch_ShouldBeCaseInsensitive(string searchText)
        {
            // Arrange
            var properties = await _indexingHelper.SetupPropertiesWithTextAsync(
                new[] { "Hotel Plaza", "فندق البحر", "HOTEL GRAND" }
            );
            
            var request = new PropertySearchRequest
            {
                SearchText = searchText,
                PageNumber = 1,
                PageSize = 10
            };
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            result.TotalCount.Should().BeGreaterThan(0);
            
            Output.WriteLine($"✅ Case insensitive search for '{searchText}' found {result.TotalCount} results");
        }
        
        [Fact]
        public async Task SearchAsync_WithCityFilter_ShouldReturnOnlyCityProperties()
        {
            // Arrange
            var sanaaProperties = await _indexingHelper.SetupPropertiesWithTextAsync(
                new[] { "عقار صنعاء 1", "عقار صنعاء 2" }, 
                "صنعاء"
            );
            
            var adenProperties = await _indexingHelper.SetupPropertiesWithTextAsync(
                new[] { "عقار عدن 1", "عقار عدن 2" }, 
                "عدن"
            );
            
            var request = new PropertySearchRequest
            {
                City = "صنعاء",
                PageNumber = 1,
                PageSize = 10
            };
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            result.TotalCount.Should().BeGreaterThanOrEqualTo(sanaaProperties.Count);
            
            var sanaaIds = sanaaProperties.Select(p => p.Id.ToString()).ToList();
            var adenIds = adenProperties.Select(p => p.Id.ToString()).ToList();
            var resultIds = result.Properties.Select(p => p.Id).ToList();
            
            // يجب أن تحتوي على عقارات صنعاء فقط
            foreach (var sanaaId in sanaaIds)
            {
                resultIds.Should().Contain(sanaaId);
            }
            
            foreach (var adenId in adenIds)
            {
                resultIds.Should().NotContain(adenId);
            }
            
            Output.WriteLine($"✅ City filter for 'صنعاء' returned {result.TotalCount} properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithPriceRange_ShouldFilterByPrice()
        {
            // Arrange
            var propertyPrices = new Dictionary<Guid, decimal>
            {
                { Guid.NewGuid(), 100m },
                { Guid.NewGuid(), 200m },
                { Guid.NewGuid(), 300m },
                { Guid.NewGuid(), 400m },
                { Guid.NewGuid(), 500m }
            };
            
            var properties = await _indexingHelper.SetupPropertiesWithPricesAsync(propertyPrices);
            
            var request = new PropertySearchRequest
            {
                MinPrice = 200m,
                MaxPrice = 400m,
                PageNumber = 1,
                PageSize = 10
            };
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            result.TotalCount.Should().Be(3); // 200, 300, 400
            
            var expectedIds = propertyPrices
                .Where(kv => kv.Value >= 200m && kv.Value <= 400m)
                .Select(kv => kv.Key.ToString())
                .ToList();
            
            var resultIds = result.Properties.Select(p => p.Id).ToList();
            
            foreach (var expectedId in expectedIds)
            {
                resultIds.Should().Contain(expectedId);
            }
            
            Output.WriteLine($"✅ Price range filter (200-400) returned {result.TotalCount} properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithPagination_ShouldReturnCorrectPage()
        {
            // Arrange
            var properties = await _indexingHelper.SetupIndexedPropertiesAsync(25, TestId);
            
            // Test Page 1
            var request1 = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 10
            };
            
            var result1 = await _searchEngine.ExecuteSearchAsync(request1);
            
            result1.Should().NotBeNull();
            result1.PageNumber.Should().Be(1);
            result1.PageSize.Should().Be(10);
            result1.Properties.Count.Should().BeLessOrEqualTo(10);
            result1.TotalCount.Should().BeGreaterThanOrEqualTo(25);
            result1.TotalPages.Should().BeGreaterThanOrEqualTo(3);
            
            // Test Page 2
            var request2 = new PropertySearchRequest
            {
                PageNumber = 2,
                PageSize = 10
            };
            
            var result2 = await _searchEngine.ExecuteSearchAsync(request2);
            
            result2.Should().NotBeNull();
            result2.PageNumber.Should().Be(2);
            result2.Properties.Count.Should().BeLessOrEqualTo(10);
            
            // التحقق من عدم تكرار النتائج بين الصفحات
            var page1Ids = result1.Properties.Select(p => p.Id).ToList();
            var page2Ids = result2.Properties.Select(p => p.Id).ToList();
            
            page1Ids.Intersect(page2Ids).Should().BeEmpty("Pages should not have duplicate results");
            
            Output.WriteLine($"✅ Pagination working correctly with {result1.TotalCount} total properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithMultipleFilters_ShouldApplyAllFilters()
        {
            // Arrange
            var properties = await _indexingHelper.SetupPropertiesWithTypesAsync(
                new Dictionary<string, int>
                {
                    { "فندق", 3 },
                    { "فيلا", 2 },
                    { "شقة", 1 }
                }
            );
            
            var request = new PropertySearchRequest
            {
                SearchText = "فندق",
                City = "صنعاء",
                MinPrice = 100,
                MaxPrice = 500,
                PageNumber = 1,
                PageSize = 10
            };
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            // يجب أن تطبق جميع الفلاتر
            foreach (var property in result.Properties)
            {
                property.Name.ToLower().Should().Contain("فندق");
                property.City.Should().Be("صنعاء");
            }
            
            Output.WriteLine($"✅ Multiple filters applied successfully, found {result.TotalCount} matching properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithSorting_ShouldReturnSortedResults()
        {
            // Arrange
            var propertyPrices = new Dictionary<Guid, decimal>
            {
                { Guid.NewGuid(), 500m },
                { Guid.NewGuid(), 100m },
                { Guid.NewGuid(), 300m }
            };
            
            var properties = await _indexingHelper.SetupPropertiesWithPricesAsync(propertyPrices);
            
            var request = new PropertySearchRequest
            {
                SortBy = "price_asc",
                PageNumber = 1,
                PageSize = 10
            };
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().NotBeNull();
            result.Properties.Should().NotBeEmpty();
            
            // التحقق من الترتيب
            for (int i = 1; i < result.Properties.Count; i++)
            {
                var prevPrice = result.Properties[i - 1].MinPrice;
                var currPrice = result.Properties[i].MinPrice;
                currPrice.Should().BeGreaterThanOrEqualTo(prevPrice, "Properties should be sorted by price ascending");
            }
            
            Output.WriteLine($"✅ Sorting by price ascending worked correctly");
        }
        
        public override async Task DisposeAsync()
        {
            try
            {
                if (_indexingHelper != null)
                {
                    await _indexingHelper.CleanupAsync();
                }
            }
            catch (Exception ex)
            {
                Output.WriteLine($"⚠️ Error during cleanup: {ex.Message}");
            }
            finally
            {
                await base.DisposeAsync();
            }
        }
    }
}
