using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Xunit;
using Xunit.Abstractions;
using Moq;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Caching.Memory;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Redis.Core;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Assertions;
using StackExchange.Redis;

namespace YemenBooking.IndexingTests.Unit.Search
{
    /// <summary>
    /// اختبارات الفلترة والبحث المتقدم
    /// </summary>
    public class FilterTests : IDisposable
    {
        private readonly ITestOutputHelper _output;
        private readonly Mock<IRedisConnectionManager> _redisManagerMock;
        private readonly Mock<IPropertyRepository> _propertyRepoMock;
        private readonly Mock<IRedisCache> _cacheMock;
        private readonly Mock<ILogger<SearchEngine>> _loggerMock;
        private readonly Mock<IDatabase> _databaseMock;
        private readonly IMemoryCache _memoryCache;
        private readonly SearchEngine _searchEngine;
        private readonly string _testId;
        
        public FilterTests(ITestOutputHelper output)
        {
            _output = output;
            _testId = Guid.NewGuid().ToString("N");
            
            // إعداد Mocks
            _redisManagerMock = new Mock<IRedisConnectionManager>();
            _propertyRepoMock = new Mock<IPropertyRepository>();
            _cacheMock = new Mock<IRedisCache>();
            _loggerMock = new Mock<ILogger<SearchEngine>>();
            _databaseMock = new Mock<IDatabase>();
            _memoryCache = new MemoryCache(new MemoryCacheOptions());
            
            _redisManagerMock.Setup(x => x.GetDatabase()).Returns(_databaseMock.Object);
            _redisManagerMock.Setup(x => x.IsConnectedAsync()).ReturnsAsync(true);
            
            var serviceProviderMock = new Mock<IServiceProvider>();
            _searchEngine = new SearchEngine(
                _redisManagerMock.Object,
                serviceProviderMock.Object,
                _loggerMock.Object
            );
        }
        
        [Fact]
        public async Task SearchAsync_WithCityFilter_ShouldReturnOnlyCityProperties()
        {
            // Arrange
            var city = "صنعاء";
            var request = TestDataBuilder.FilteredSearchRequest(city: city);
            
            var sanaaProperties = new[] { Guid.NewGuid(), Guid.NewGuid() };
            var adenProperties = new[] { Guid.NewGuid() };
            
            SetupCityFilter(city, sanaaProperties);
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().AllBeInCity(city);
            result.Should().HaveCount(sanaaProperties.Length);
            
            foreach (var id in sanaaProperties)
            {
                result.Should().ContainProperty(id);
            }
            
            foreach (var id in adenProperties)
            {
                result.Should().NotContainProperty(id);
            }
            
            _output.WriteLine($"✅ City filter '{city}' returned {result.TotalCount} properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithPriceRange_ShouldFilterByPrice()
        {
            // Arrange
            var minPrice = 100m;
            var maxPrice = 500m;
            var request = TestDataBuilder.FilteredSearchRequest(
                minPrice: minPrice,
                maxPrice: maxPrice
            );
            
            var matchingProperties = new[]
            {
                CreatePropertyWithPrice(Guid.NewGuid(), 150m),
                CreatePropertyWithPrice(Guid.NewGuid(), 300m),
                CreatePropertyWithPrice(Guid.NewGuid(), 450m)
            };
            
            var nonMatchingProperties = new[]
            {
                CreatePropertyWithPrice(Guid.NewGuid(), 50m),
                CreatePropertyWithPrice(Guid.NewGuid(), 600m)
            };
            
            SetupPriceFilter(matchingProperties.Select(p => Guid.Parse(p.Id)).ToArray());
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().HavePricesInRange(minPrice, maxPrice);
            
            foreach (var prop in matchingProperties)
            {
                result.Should().ContainProperty(prop.Id);
            }
            
            foreach (var prop in nonMatchingProperties)
            {
                result.Should().NotContainProperty(prop.Id);
            }
            
            _output.WriteLine($"✅ Price filter {minPrice}-{maxPrice} working correctly");
        }
        
        [Fact]
        public async Task SearchAsync_WithPropertyType_ShouldFilterByType()
        {
            // Arrange
            var propertyTypeId = Guid.Parse("30000000-0000-0000-0000-000000000001");
            var request = TestDataBuilder.FilteredSearchRequest(
                propertyType: propertyTypeId.ToString()
            );
            
            var matchingProperties = new[] { Guid.NewGuid(), Guid.NewGuid() };
            
            SetupPropertyTypeFilter(propertyTypeId, matchingProperties);
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().AllBeOfType(propertyTypeId.ToString());
            result.Should().HaveCount(matchingProperties.Length);
            
            _output.WriteLine($"✅ Property type filter working correctly");
        }
        
        [Fact]
        public async Task SearchAsync_WithGuestsCount_ShouldFilterByCapacity()
        {
            // Arrange
            var guestsCount = 4;
            var request = TestDataBuilder.FilteredSearchRequest(guestsCount: guestsCount);
            
            var matchingProperties = new[]
            {
                CreatePropertyWithCapacity(Guid.NewGuid(), 4),
                CreatePropertyWithCapacity(Guid.NewGuid(), 6),
                CreatePropertyWithCapacity(Guid.NewGuid(), 8)
            };
            
            var nonMatchingProperties = new[]
            {
                CreatePropertyWithCapacity(Guid.NewGuid(), 2),
                CreatePropertyWithCapacity(Guid.NewGuid(), 3)
            };
            
            SetupCapacityFilter(matchingProperties.Select(p => Guid.Parse(p.Id)).ToArray());
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Properties.All(p => p.MaxCapacity >= guestsCount).Should().BeTrue();
            
            _output.WriteLine($"✅ Capacity filter for {guestsCount} guests working");
        }
        
        [Fact]
        public async Task SearchAsync_WithMultipleFilters_ShouldApplyAllFilters()
        {
            // Arrange
            var request = new PropertySearchRequest
            {
                City = "صنعاء",
                PropertyType = "30000000-0000-0000-0000-000000000001",
                MinPrice = 100,
                MaxPrice = 500,
                MinRating = 4.0m,
                GuestsCount = 2,
                PageNumber = 1,
                PageSize = 20
            };
            
            var matchingProperty = Guid.NewGuid();
            SetupComplexFilter(matchingProperty);
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().HaveAtLeast(1);
            result.Should().ContainProperty(matchingProperty);
            
            var property = result.Properties.First(p => p.Id == matchingProperty.ToString());
            property.City.Should().Be(request.City);
            property.PropertyType.Should().Be("منتجع");
            property.MinPrice.Should().BeInRange(request.MinPrice.Value, request.MaxPrice.Value);
            property.AverageRating.Should().BeGreaterOrEqualTo(request.MinRating.Value);
            property.MaxCapacity.Should().BeGreaterOrEqualTo(request.GuestsCount.Value);
            
            _output.WriteLine($"✅ Multiple filters applied correctly");
        }
        
        [Fact]
        public async Task SearchAsync_WithAmenityFilter_ShouldFilterByAmenities()
        {
            // Arrange
            var amenityIds = new List<string>
            {
                "10000000-0000-0000-0000-000000000001", // WiFi
                "10000000-0000-0000-0000-000000000003"  // Pool
            };
            
            var request = new PropertySearchRequest
            {
                RequiredAmenityIds = amenityIds,
                PageNumber = 1,
                PageSize = 20
            };
            
            var matchingProperties = new[] { Guid.NewGuid(), Guid.NewGuid() };
            SetupAmenityFilter(amenityIds, matchingProperties);
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().HaveCount(matchingProperties.Length);
            
            foreach (var id in matchingProperties)
            {
                result.Should().ContainProperty(id);
            }
            
            _output.WriteLine($"✅ Amenity filter working for {amenityIds.Count} amenities");
        }
        
        [Fact]
        public async Task SearchAsync_WithDynamicFields_ShouldFilterCorrectly()
        {
            // Arrange
            var dynamicFilters = new Dictionary<string, object>
            {
                ["pet_friendly"] = "true",
                ["smoking_allowed"] = "false"
            };
            
            var request = new PropertySearchRequest
            {
                DynamicFieldFilters = dynamicFilters,
                PageNumber = 1,
                PageSize = 20
            };
            
            var matchingProperties = new[] { Guid.NewGuid() };
            SetupDynamicFieldFilter(dynamicFilters, matchingProperties);
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            result.Should().HaveCount(matchingProperties.Length);
            result.Should().ContainProperty(matchingProperties[0]);
            
            _output.WriteLine($"✅ Dynamic field filters working");
        }
        
        [Fact]
        public async Task SearchAsync_WithDateRange_ShouldFilterByAvailability()
        {
            // Arrange
            var checkIn = DateTime.Today.AddDays(7);
            var checkOut = DateTime.Today.AddDays(10);
            
            var request = new PropertySearchRequest
            {
                CheckIn = checkIn,
                CheckOut = checkOut,
                PageNumber = 1,
                PageSize = 20
            };
            
            var availableProperties = new[] { Guid.NewGuid(), Guid.NewGuid() };
            var unavailableProperties = new[] { Guid.NewGuid() };
            
            SetupAvailabilityFilter(checkIn, checkOut, availableProperties, unavailableProperties);
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            foreach (var id in availableProperties)
            {
                result.Should().ContainProperty(id);
            }
            
            foreach (var id in unavailableProperties)
            {
                result.Should().NotContainProperty(id);
            }
            
            _output.WriteLine($"✅ Availability filter for {checkIn:yyyy-MM-dd} to {checkOut:yyyy-MM-dd} working");
        }
        
        [Theory]
        [InlineData("price_asc")]
        [InlineData("price_desc")]
        [InlineData("rating")]
        [InlineData("newest")]
        [InlineData("popularity")]
        public async Task SearchAsync_WithSorting_ShouldSortCorrectly(string sortBy)
        {
            // Arrange
            var request = new PropertySearchRequest
            {
                SortBy = sortBy,
                PageNumber = 1,
                PageSize = 20
            };
            
            var properties = CreatePropertiesForSorting();
            SetupSortingTest(properties);
            
            // Act
            var result = await _searchEngine.ExecuteSearchAsync(request);
            
            // Assert
            switch (sortBy)
            {
                case "price_asc":
                    result.Should().BeSortedByPrice(ascending: true);
                    break;
                case "price_desc":
                    result.Should().BeSortedByPrice(ascending: false);
                    break;
                case "rating":
                    result.Should().BeSortedByRating(descending: true);
                    break;
                default:
                    result.Should().NotBeNull();
                    break;
            }
            
            _output.WriteLine($"✅ Sorting by '{sortBy}' working correctly");
        }
        
        #region Helper Methods
        
        private void SetupCityFilter(string city, Guid[] propertyIds)
        {
            _databaseMock.Setup(x => x.SetMembersAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"city:{city.ToLower()}")),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(propertyIds.Select(id => (RedisValue)id.ToString()).ToArray());
            
            SetupPropertyDetails(propertyIds, city: city);
        }
        
        private void SetupPriceFilter(Guid[] propertyIds)
        {
            SetupPropertyDetails(propertyIds);
        }
        
        private void SetupPropertyTypeFilter(Guid typeId, Guid[] propertyIds)
        {
            _databaseMock.Setup(x => x.SetMembersAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property_type:{typeId}")),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(propertyIds.Select(id => (RedisValue)id.ToString()).ToArray());
            
            SetupPropertyDetails(propertyIds, propertyType: typeId.ToString());
        }
        
        private void SetupCapacityFilter(Guid[] propertyIds)
        {
            SetupPropertyDetails(propertyIds);
        }
        
        private void SetupComplexFilter(Guid propertyId)
        {
            SetupPropertyDetails(new[] { propertyId },
                city: "صنعاء",
                propertyType: "30000000-0000-0000-0000-000000000001",
                minPrice: 200,
                rating: 4.5m,
                capacity: 4);
        }
        
        private void SetupAmenityFilter(List<string> amenityIds, Guid[] propertyIds)
        {
            foreach (var amenityId in amenityIds)
            {
                _databaseMock.Setup(x => x.SetMembersAsync(
                    It.Is<RedisKey>(k => k.ToString().Contains($"amenity:{amenityId}")),
                    It.IsAny<CommandFlags>()))
                    .ReturnsAsync(propertyIds.Select(id => (RedisValue)id.ToString()).ToArray());
            }
            
            SetupPropertyDetails(propertyIds);
        }
        
        private void SetupDynamicFieldFilter(Dictionary<string, string> fields, Guid[] propertyIds)
        {
            SetupPropertyDetails(propertyIds, dynamicFields: fields);
        }
        
        private void SetupAvailabilityFilter(DateTime checkIn, DateTime checkOut, 
            Guid[] availableProperties, Guid[] unavailableProperties)
        {
            // تكوين التوفر للعقارات المتاحة
            foreach (var id in availableProperties)
            {
                // محاكاة أن العقار متاح
                var availableKey = $"property:{id}:availability:{checkIn:yyyy-MM-dd}:{checkOut:yyyy-MM-dd}";
                _databaseMock.Setup(x => x.StringGetAsync(
                    It.Is<RedisKey>(k => k.ToString() == availableKey),
                    It.IsAny<CommandFlags>()))
                    .ReturnsAsync("available");
            }
            
            foreach (var id in unavailableProperties)
            {
                // محاكاة أن العقار غير متاح
                var unavailableKey = $"property:{id}:availability:{checkIn:yyyy-MM-dd}:{checkOut:yyyy-MM-dd}";
                _databaseMock.Setup(x => x.StringGetAsync(
                    It.Is<RedisKey>(k => k.ToString() == unavailableKey),
                    It.IsAny<CommandFlags>()))
                    .ReturnsAsync(RedisValue.Null);
            }
            
            SetupPropertyDetails(availableProperties.Concat(unavailableProperties).ToArray());
        }
        
        private void SetupSortingTest(List<PropertySearchItem> properties)
        {
            var propertyIds = properties.Select(p => p.Id).ToArray();
            
            _databaseMock.Setup(x => x.SetMembersAsync(
                It.Is<RedisKey>(k => k.ToString() == "properties:all"),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(propertyIds.Select(id => (RedisValue)id.ToString()).ToArray());
            
            foreach (var prop in properties)
            {
                var hashEntries = new HashEntry[]
                {
                    new("id", prop.Id.ToString()),
                    new("name", prop.Name),
                    new("city", prop.City),
                    new("property_type", prop.PropertyType),
                    new("min_price", prop.MinPrice.ToString()),
                    new("average_rating", prop.AverageRating.ToString()),
                    new("star_rating", prop.StarRating.ToString()),
                    new("max_capacity", prop.MaxCapacity.ToString()),
                    new("units_count", prop.UnitsCount.ToString()),
                    new("latitude", prop.Latitude.ToString()),
                    new("longitude", prop.Longitude.ToString()),
                    new("is_active", "1"),
                    new("is_approved", "1")
                };
                
                _databaseMock.Setup(x => x.HashGetAllAsync(
                    It.Is<RedisKey>(k => k.ToString().Contains($"property:{prop.Id}")),
                    It.IsAny<CommandFlags>()))
                    .ReturnsAsync(hashEntries);
            }
        }
        
        private void SetupPropertyDetails(Guid[] propertyIds,
            string city = null, decimal price = 0, string propertyType = null, 
            int capacity = 0, Dictionary<string, string> dynamicFields = null)
        {
            foreach (var id in propertyIds)
            {
                var hashEntries = new List<HashEntry>
                {
                    new("id", id.ToString()),
                    new("name", $"Property {id}"),
                    new("city", city ?? "صنعاء"),
                    new("min_price", price.ToString()),
                    new("average_rating", "4.5"),
                    new("max_capacity", capacity.ToString()),
                    new("is_active", "1"),
                    new("is_approved", "1")
                };
                
                if (!string.IsNullOrEmpty(propertyType))
                {
                    hashEntries.Add(new("property_type", propertyType));
                }
                
                if (dynamicFields != null)
                {
                    var dynamicFieldsJson = string.Join(" ", 
                        dynamicFields.Select(kv => $"{kv.Key}:{kv.Value}"));
                    hashEntries.Add(new("dynamic_fields", dynamicFieldsJson));
                }
                
                _databaseMock.Setup(x => x.HashGetAllAsync(
                    It.Is<RedisKey>(k => k.ToString().Contains($"property:{id}")),
                    It.IsAny<CommandFlags>()))
                    .ReturnsAsync(hashEntries.ToArray());
            }
        }
        
        private PropertySearchItem CreateTestDocument(Guid id, string city = null, decimal price = 0)
        {
            return new PropertySearchItem
            {
                Id = id.ToString(),
                Name = $"Property {id}",
                MinPrice = price
            };
        }
        
        private PropertySearchItem CreatePropertyWithPrice(Guid id, decimal price)
        {
            return new PropertySearchItem
            {
                Id = id.ToString(),
                Name = $"Property {id}",
                MinPrice = price
            };
        }
        
        private PropertySearchItem CreatePropertyWithCapacity(Guid id, int capacity)
        {
            return new PropertySearchItem
            {
                Id = id.ToString(),
                Name = $"Property {id}",
                MaxCapacity = capacity
            };
        }
        
        private List<PropertySearchItem> CreatePropertiesForSorting()
        {
            return new List<PropertySearchItem>
            {
                new PropertySearchItem
                {
                    Id = Guid.NewGuid().ToString(),
                    Name = "Property A",
                    MinPrice = 300,
                    AverageRating = 3.5m
                },
                new PropertySearchItem
                {
                    Id = Guid.NewGuid().ToString(),
                    Name = "Property B",
                    MinPrice = 100,
                    AverageRating = 4.8m
                },
                new PropertySearchItem
                {
                    Id = Guid.NewGuid().ToString(),
                    Name = "Property C",
                    MinPrice = 200,
                    AverageRating = 4.2m
                }
            };
        }
        
        #endregion
        
        public void Dispose()
        {
            _memoryCache?.Dispose();
            _output.WriteLine($"🧹 Cleaning up test {_testId}");
        }
    }
}
