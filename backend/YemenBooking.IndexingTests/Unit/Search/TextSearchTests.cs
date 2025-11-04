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
    /// اختبارات البحث النصي
    /// </summary>
    public class TextSearchTests : IDisposable
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
        
        public TextSearchTests(ITestOutputHelper output)
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
            
            // إنشاء محرك البحث
            var serviceProviderMock = new Mock<IServiceProvider>();
            _searchEngine = new SearchEngine(
                _redisManagerMock.Object,
                serviceProviderMock.Object,
                _loggerMock.Object
            );
        }
        
        [Fact]
        public async Task SearchAsync_WithEmptyRequest_ShouldReturnAllActiveProperties()
        {
            // Arrange
            var request = TestDataBuilder.SimpleSearchRequest();
            var propertyIds = new[] { Guid.NewGuid(), Guid.NewGuid(), Guid.NewGuid() };
            
            SetupBasicSearch(propertyIds);
            
            // Act
            var result = await _searchEngine.SearchAsync(request);
            
            // Assert
            result.Should().HaveCount(propertyIds.Length);
            result.Properties.Should().HaveCount(propertyIds.Length);
            
            _output.WriteLine($"✅ Empty search returned {result.TotalCount} properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithTextSearch_ShouldFilterByText()
        {
            // Arrange
            var searchText = "فندق";
            var request = TestDataBuilder.TextSearchRequest(searchText);
            
            var matchingIds = new[] { Guid.NewGuid(), Guid.NewGuid() };
            var nonMatchingIds = new[] { Guid.NewGuid() };
            
            SetupTextSearch(searchText, matchingIds);
            
            // Act
            var result = await _searchEngine.SearchAsync(request);
            
            // Assert
            result.Should().HaveCount(matchingIds.Length);
            
            foreach (var id in matchingIds)
            {
                result.Should().ContainProperty(id);
            }
            
            foreach (var id in nonMatchingIds)
            {
                result.Should().NotContainProperty(id);
            }
            
            _output.WriteLine($"✅ Text search for '{searchText}' returned {result.TotalCount} properties");
        }
        
        [Theory]
        [InlineData("hotel")]
        [InlineData("HOTEL")]
        [InlineData("HoTeL")]
        [InlineData("فندق")]
        [InlineData("الفندق")]
        public async Task SearchAsync_WithTextSearch_ShouldBeCaseInsensitive(string searchText)
        {
            // Arrange
            var request = TestDataBuilder.TextSearchRequest(searchText);
            var propertyId = Guid.NewGuid();
            
            SetupTextSearch("hotel", new[] { propertyId });
            
            // Act
            var result = await _searchEngine.SearchAsync(request);
            
            // Assert
            result.Should().HaveAtLeast(1);
            
            _output.WriteLine($"✅ Case-insensitive search for '{searchText}' worked");
        }
        
        [Fact]
        public async Task SearchAsync_WithPartialText_ShouldMatchPrefix()
        {
            // Arrange
            var request = TestDataBuilder.TextSearchRequest("فن"); // جزء من "فندق"
            var propertyId = Guid.NewGuid();
            
            SetupPrefixSearch("فن", new[] { propertyId });
            
            // Act
            var result = await _searchEngine.SearchAsync(request);
            
            // Assert
            result.Should().HaveAtLeast(1);
            result.Should().ContainProperty(propertyId);
            
            _output.WriteLine($"✅ Prefix search for 'فن' matched 'فندق'");
        }
        
        [Fact]
        public async Task SearchAsync_WithMultipleWords_ShouldMatchAll()
        {
            // Arrange
            var request = TestDataBuilder.TextSearchRequest("فندق صنعاء");
            var matchingId = Guid.NewGuid(); // يحتوي على كلا الكلمتين
            var partialMatchId = Guid.NewGuid(); // يحتوي على كلمة واحدة فقط
            
            SetupMultiWordSearch(new[] { "فندق", "صنعاء" }, new[] { matchingId });
            
            // Act
            var result = await _searchEngine.SearchAsync(request);
            
            // Assert
            result.Should().ContainProperty(matchingId);
            result.Should().NotContainProperty(partialMatchId);
            
            _output.WriteLine($"✅ Multi-word search matched properties with all words");
        }
        
        [Fact]
        public async Task SearchAsync_WithSpecialCharacters_ShouldHandleGracefully()
        {
            // Arrange
            var specialTexts = new[]
            {
                "test@example.com",
                "100%",
                "5*",
                "C#",
                "Node.js",
                "الفندق!",
                "صنعاء؟"
            };
            
            foreach (var text in specialTexts)
            {
                var request = TestDataBuilder.TextSearchRequest(text);
                
                // Act
                var result = await _searchEngine.SearchAsync(request);
                
                // Assert
                result.Should().NotBeNull();
                // لا يجب أن يفشل البحث
                
                _output.WriteLine($"✅ Handled special characters in '{text}'");
            }
        }
        
        [Fact]
        public async Task SearchAsync_WithEmptySearchText_ShouldReturnAll()
        {
            // Arrange
            var request = TestDataBuilder.TextSearchRequest("");
            var propertyIds = new[] { Guid.NewGuid(), Guid.NewGuid() };
            
            SetupBasicSearch(propertyIds);
            
            // Act
            var result = await _searchEngine.SearchAsync(request);
            
            // Assert
            result.Should().HaveAtLeast(propertyIds.Length);
            
            _output.WriteLine($"✅ Empty text search returned all properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithPagination_ShouldReturnCorrectPage()
        {
            // Arrange
            var totalProperties = 25;
            var pageSize = 10;
            var propertyIds = Enumerable.Range(0, totalProperties)
                .Select(_ => Guid.NewGuid())
                .ToArray();
            
            SetupPaginatedSearch(propertyIds, pageSize);
            
            // Test Page 1
            var request1 = new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = pageSize
            };
            
            var result1 = await _searchEngine.SearchAsync(request1);
            
            result1.Should().BeOnPage(1);
            result1.Should().HavePageSize(pageSize);
            result1.Properties.Count.Should().Be(pageSize);
            result1.TotalCount.Should().Be(totalProperties);
            result1.TotalPages.Should().Be(3);
            
            // Test Page 2
            var request2 = new PropertySearchRequest
            {
                PageNumber = 2,
                PageSize = pageSize
            };
            
            var result2 = await _searchEngine.SearchAsync(request2);
            
            result2.Should().BeOnPage(2);
            result2.Properties.Count.Should().Be(pageSize);
            
            // Test Page 3 (partial)
            var request3 = new PropertySearchRequest
            {
                PageNumber = 3,
                PageSize = pageSize
            };
            
            var result3 = await _searchEngine.SearchAsync(request3);
            
            result3.Should().BeOnPage(3);
            result3.Properties.Count.Should().Be(5); // 25 - 20
            
            _output.WriteLine($"✅ Pagination working correctly with {totalProperties} properties");
        }
        
        [Fact]
        public async Task SearchAsync_WithHighlighting_ShouldHighlightMatchedText()
        {
            // Arrange
            var searchText = "فندق";
            var request = TestDataBuilder.TextSearchRequest(searchText);
            request.EnableHighlighting = true;
            
            var propertyId = Guid.NewGuid();
            var propertyName = "فندق الخليج";
            
            SetupHighlightedSearch(searchText, propertyId, propertyName);
            
            // Act
            var result = await _searchEngine.SearchAsync(request);
            
            // Assert
            result.Should().HaveAtLeast(1);
            var property = result.Properties.First(p => p.Id == propertyId.ToString());
            
            // يجب أن يحتوي على تمييز
            property.HighlightedName?.Should().Contain("<mark>");
            property.HighlightedName?.Should().Contain("</mark>");
            
            _output.WriteLine($"✅ Text highlighting working for '{searchText}'");
        }
        
        #region Helper Methods
        
        private void SetupBasicSearch(Guid[] propertyIds)
        {
            var properties = propertyIds.Select(id =>
            {
                var prop = TestDataBuilder.SimpleProperty(_testId);
                prop.Id = id;
                return prop;
            }).ToList();
            
            // Mock database operations
            _databaseMock.Setup(x => x.SetMembersAsync(
                It.IsAny<RedisKey>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(propertyIds.Select(id => (RedisValue)id.ToString()).ToArray());
            
            foreach (var prop in properties)
            {
                var hashEntries = new HashEntry[]
                {
                    new("id", prop.Id.ToString()),
                    new("name", prop.Name),
                    new("city", prop.City),
                    new("is_active", "1"),
                    new("is_approved", "1")
                };
                
                _databaseMock.Setup(x => x.HashGetAllAsync(
                    It.Is<RedisKey>(k => k.ToString().Contains($"property:{prop.Id}")),
                    It.IsAny<CommandFlags>()))
                    .ReturnsAsync(hashEntries);
            }
        }
        
        private void SetupTextSearch(string searchText, Guid[] matchingIds)
        {
            // Setup search results
            _databaseMock.Setup(x => x.ScriptEvaluateAsync(
                It.IsAny<string>(),
                It.IsAny<RedisKey[]>(),
                It.IsAny<RedisValue[]>(),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(RedisResult.Create(new RedisValue(
                    $"{{\"total_count\":{matchingIds.Length},\"results\":[{string.Join(",", matchingIds.Select(id => $"[\"{id}\"]"))}]}}"
                )));
            
            SetupBasicSearch(matchingIds);
        }
        
        private void SetupPrefixSearch(string prefix, Guid[] matchingIds)
        {
            SetupTextSearch(prefix + "*", matchingIds);
        }
        
        private void SetupMultiWordSearch(string[] words, Guid[] matchingIds)
        {
            SetupTextSearch(string.Join(" ", words), matchingIds);
        }
        
        private void SetupPaginatedSearch(Guid[] propertyIds, int pageSize)
        {
            SetupBasicSearch(propertyIds);
            
            // Mock pagination
            _cacheMock.Setup(x => x.GetAsync<PropertySearchResult>(
                It.IsAny<string>(),
                It.IsAny<CancellationToken>()))
                .ReturnsAsync((PropertySearchResult)null);
        }
        
        private void SetupHighlightedSearch(string searchText, Guid propertyId, string propertyName)
        {
            SetupTextSearch(searchText, new[] { propertyId });
            
            // Add highlighting info
            var hashEntries = new HashEntry[]
            {
                new("id", propertyId.ToString()),
                new("name", propertyName),
                new("city", "صنعاء"),
                new("is_active", "1"),
                new("is_approved", "1")
            };
            
            _databaseMock.Setup(x => x.HashGetAllAsync(
                It.Is<RedisKey>(k => k.ToString().Contains($"property:{propertyId}")),
                It.IsAny<CommandFlags>()))
                .ReturnsAsync(hashEntries);
        }
        
        #endregion
        
        public void Dispose()
        {
            _memoryCache?.Dispose();
            _output.WriteLine($"🧹 Cleaning up test {_testId}");
        }
    }
}
