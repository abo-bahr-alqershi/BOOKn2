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
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.IndexingTests.Infrastructure;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using YemenBooking.IndexingTests.Infrastructure.Fixtures;
using YemenBooking.IndexingTests.Infrastructure.Helpers;
using StackExchange.Redis;

namespace YemenBooking.IndexingTests.Unit.Search
{
    /// <summary>
    /// اختبارات الفلترة والبحث المتقدم - باستخدام Redis و PostgreSQL الحقيقيين
    /// تطبق جميع مبادئ العزل الكامل والحتمية
    /// بدون استخدام Mocks - فقط خدمات حقيقية
    /// </summary>
    [Collection("TestContainers")]
    public class FilterTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        private readonly List<TimeSpan> _searchLatencies = new();
        private readonly SemaphoreSlim _searchLock;
        
        public FilterTests(TestContainerFixture containers, ITestOutputHelper output) 
            : base(output)
        {
            _containers = containers;
            _searchLock = new SemaphoreSlim(1, 1);
        }
        
        protected override bool UseTestContainers() => true;
        
        /// <summary>
        /// انتظار اكتمال فهرسة العقارات - باستخدام Polling Pattern
        /// </summary>
        private async Task WaitForIndexingCompletion(IServiceScope scope, int expectedCount)
        {
            var redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            var database = redisManager.GetDatabase();
            
            // الانتظار حتى تكتمل الفهرسة باستخدام Polling
            await WaitForConditionAsync(
                async () =>
                {
                    var searchIndexKey = "search:index";
                    var members = await database.SetMembersAsync(searchIndexKey);
                    return members.Length;
                },
                count => count >= expectedCount,
                TimeSpan.FromSeconds(5)
            );
        }
        
        [Fact]
        public async Task CityFilter_WithValidCity_ShouldReturnOnlyCityProperties()
        {
            // Arrange - استخدام scope منفصل للعزل الكامل
            using var scope = CreateIsolatedScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقارات فريدة في مدن مختلفة
            var sanaaProperties = new List<Property>();
            for (int i = 0; i < 3; i++)
            {
                var property = TestDataBuilder.CompleteProperty($"{TestId}_sanaa_{i}");
                property.City = "صنعاء";
                sanaaProperties.Add(property);
                TrackEntity(property.Id);
            }
            
            var adenProperties = new List<Property>();
            for (int i = 0; i < 2; i++)
            {
                var property = TestDataBuilder.CompleteProperty($"{TestId}_aden_{i}");
                property.City = "عدن";
                adenProperties.Add(property);
                TrackEntity(property.Id);
            }
            
            // حفظ في قاعدة البيانات
            await dbContext.Properties.AddRangeAsync(sanaaProperties.Concat(adenProperties));
            await dbContext.SaveChangesAsync();
            
            // فهرسة جميع العقارات
            foreach (var property in sanaaProperties.Concat(adenProperties))
            {
                await indexingService.OnPropertyCreatedAsync(property.Id);
            }
            
            // الانتظار حتى اكتمال الفهرسة
            await WaitForIndexingCompletion(scope, sanaaProperties.Count + adenProperties.Count);
            
            var stopwatch = Stopwatch.StartNew();
            
            // Act - البحث بفلتر المدينة
            var searchRequest = new PropertySearchRequest
            {
                City = "صنعاء",
                PageNumber = 1,
                PageSize = 20
            };
            
            var searchResult = await indexingService.SearchAsync(searchRequest);
            
            stopwatch.Stop();
            _searchLatencies.Add(stopwatch.Elapsed);
            
            // Assert
            searchResult.Should().NotBeNull();
            searchResult.TotalCount.Should().Be(sanaaProperties.Count);
            
            // التحقق من أن جميع النتائج من صنعاء
            foreach (var item in searchResult.Properties)
            {
                item.City.Should().Be("صنعاء");
                sanaaProperties.Should().Contain(p => p.Id.ToString() == item.Id);
            }
            
            // التحقق من عدم وجود عقارات من عدن
            searchResult.Properties.Should().NotContain(item => 
                adenProperties.Any(p => p.Id.ToString() == item.Id));
            
            Output.WriteLine($"✅ City filter test passed");
            Output.WriteLine($"   City: صنعاء");
            Output.WriteLine($"   Found: {searchResult.TotalCount} properties");
            Output.WriteLine($"   Search time: {stopwatch.ElapsedMilliseconds}ms");
        }
        
        [Fact]
        public async Task PriceFilter_WithRange_ShouldReturnPropertiesInRange()
        {
            // Arrange - استخدام scope منفصل للعزل الكامل
            using var scope = CreateIsolatedScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقارات بأسعار مختلفة
            var properties = new List<Property>();
            var prices = new[] { 50m, 150m, 250m, 350m, 450m, 550m };
            
            foreach (var price in prices)
            {
                var property = TestDataBuilder.PropertyWithUnits(1, $"{TestId}_price_{price}");
                property.Units.First().BasePrice = new Money(price, "USD");
                properties.Add(property);
                TrackEntity(property.Id);
                TrackEntities(property.Units.Select(u => u.Id));
            }
            
            await dbContext.Properties.AddRangeAsync(properties);
            await dbContext.SaveChangesAsync();
            
            // فهرسة العقارات والوحدات
            foreach (var property in properties)
            {
                await indexingService.OnPropertyCreatedAsync(property.Id);
                foreach (var unit in property.Units)
                {
                    await indexingService.OnUnitCreatedAsync(unit.Id, property.Id);
                }
            }
            
            await WaitForIndexingCompletion(scope, properties.Count);
            
            // Act - البحث بنطاق سعري
            var searchRequest = new PropertySearchRequest
            {
                MinPrice = 100m,
                MaxPrice = 400m,
                PageNumber = 1,
                PageSize = 20
            };
            
            var result = await indexingService.SearchAsync(searchRequest);
            
            // Assert
            result.Should().NotBeNull();
            
            // التحقق من أن جميع الأسعار في النطاق
            foreach (var item in result.Properties)
            {
                item.MinPrice.Should().BeInRange(100m, 400m);
            }
            
            // التحقق من العدد المتوقع
            var expectedCount = prices.Count(p => p >= 100m && p <= 400m);
            result.TotalCount.Should().Be(expectedCount);
            
            Output.WriteLine($"✅ Price filter test passed");
            Output.WriteLine($"   Range: $100 - $400");
            Output.WriteLine($"   Found: {result.TotalCount} properties");
        }
        
        [Fact]
        public async Task PropertyTypeFilter_ShouldReturnOnlySpecificType()
        {
            // Arrange - استخدام scope منفصل للعزل الكامل
            using var scope = CreateIsolatedScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            var hotelTypeId = Guid.Parse("30000000-0000-0000-0000-000000000001");
            var apartmentTypeId = Guid.Parse("30000000-0000-0000-0000-000000000002");
            
            // إنشاء عقارات من أنواع مختلفة
            var hotels = new List<Property>();
            for (int i = 0; i < 3; i++)
            {
                var property = TestDataBuilder.CompleteProperty($"{TestId}_hotel_{i}");
                property.TypeId = hotelTypeId;
                hotels.Add(property);
                TrackEntity(property.Id);
            }
            
            var apartments = new List<Property>();
            for (int i = 0; i < 2; i++)
            {
                var property = TestDataBuilder.CompleteProperty($"{TestId}_apartment_{i}");
                property.TypeId = apartmentTypeId;
                apartments.Add(property);
                TrackEntity(property.Id);
            }
            
            await dbContext.Properties.AddRangeAsync(hotels.Concat(apartments));
            await dbContext.SaveChangesAsync();
            
            // فهرسة
            foreach (var property in hotels.Concat(apartments))
            {
                await indexingService.OnPropertyCreatedAsync(property.Id);
            }
            
            await WaitForIndexingCompletion(scope, hotels.Count + apartments.Count);
            
            // Act - البحث عن الفنادق فقط
            var searchRequest = new PropertySearchRequest
            {
                PropertyType = hotelTypeId.ToString(),
                PageNumber = 1,
                PageSize = 20
            };
            
            var result = await indexingService.SearchAsync(searchRequest);
            
            // Assert
            result.TotalCount.Should().Be(hotels.Count);
            result.Properties.Should().OnlyContain(p => 
                hotels.Any(h => h.Id.ToString() == p.Id));
            
            Output.WriteLine($"✅ Property type filter test passed");
            Output.WriteLine($"   Type: Hotel");
            Output.WriteLine($"   Found: {result.TotalCount} properties");
        }
        
        [Fact]
        public async Task GuestCapacityFilter_ShouldReturnPropertiesWithEnoughCapacity()
        {
            // Arrange - استخدام scope منفصل للعزل الكامل
            using var scope = CreateIsolatedScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            // إنشاء عقارات بسعات مختلفة
            var properties = new List<Property>();
            var capacities = new[] { 2, 4, 6, 8, 10 };
            
            foreach (var capacity in capacities)
            {
                var property = TestDataBuilder.PropertyWithUnits(1, $"{TestId}_capacity_{capacity}");
                property.Units.First().MaxCapacity = capacity;
                property.Units.First().AdultsCapacity = capacity;
                properties.Add(property);
                TrackEntity(property.Id);
                TrackEntities(property.Units.Select(u => u.Id));
            }
            
            await dbContext.Properties.AddRangeAsync(properties);
            await dbContext.SaveChangesAsync();
            
            // فهرسة
            foreach (var property in properties)
            {
                await indexingService.OnPropertyCreatedAsync(property.Id);
                foreach (var unit in property.Units)
                {
                    await indexingService.OnUnitCreatedAsync(unit.Id, property.Id);
                }
            }
            
            await WaitForIndexingCompletion(scope, properties.Count);
            
            // Act - البحث عن عقارات تتسع لـ 5 أشخاص
            var searchRequest = new PropertySearchRequest
            {
                GuestsCount = 5,
                PageNumber = 1,
                PageSize = 20
            };
            
            var result = await indexingService.SearchAsync(searchRequest);
            
            // Assert
            result.Should().NotBeNull();
            
            // التحقق من أن جميع العقارات تتسع لـ 5 أشخاص على الأقل
            foreach (var item in result.Properties)
            {
                item.MaxCapacity.Should().BeGreaterOrEqualTo(5);
            }
            
            // يجب أن تعود العقارات بسعة 6، 8، 10
            var expectedCount = capacities.Count(c => c >= 5);
            result.TotalCount.Should().Be(expectedCount);
            
            Output.WriteLine($"✅ Guest capacity filter test passed");
            Output.WriteLine($"   Guests: 5");
            Output.WriteLine($"   Found: {result.TotalCount} properties");
        }
        
        
        public override void Dispose()
        {
            _searchLock?.Dispose();
            base.Dispose();
            
            // طباعة إحصائيات الأداء
            if (_searchLatencies.Any())
            {
                Output.WriteLine($"\n📊 Search Performance Statistics:");
                Output.WriteLine($"   Total searches: {_searchLatencies.Count}");
                Output.WriteLine($"   Average latency: {_searchLatencies.Average(t => t.TotalMilliseconds):F2}ms");
                Output.WriteLine($"   Min latency: {_searchLatencies.Min().TotalMilliseconds:F2}ms");
                Output.WriteLine($"   Max latency: {_searchLatencies.Max().TotalMilliseconds:F2}ms");
            }
        }
    }
}
