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
    /// اختبارات التكامل الشاملة End-to-End
    /// تستخدم قاعدة بيانات و Redis حقيقيين في Docker
    /// كل اختبار معزول تماماً
    /// </summary>
    [Collection("TestContainers")]
    public class EndToEndSearchTests : TestBase
    {
        private readonly TestContainerFixture _containers;
        private readonly SemaphoreSlim _concurrencyLimiter;
        
        public EndToEndSearchTests(TestContainerFixture containers, ITestOutputHelper output) 
            : base(output)
        {
            _containers = containers;
            _concurrencyLimiter = new SemaphoreSlim(
                initialCount: Environment.ProcessorCount * 2,
                maxCount: Environment.ProcessorCount * 2
            );
        }
        
        protected override async Task ConfigureServicesAsync(IServiceCollection services)
        {
            // تكوين قاعدة البيانات من الحاوية
            services.AddDbContext<YemenBookingDbContext>(options =>
            {
                options.UseNpgsql(_containers.PostgresConnectionString);
                options.EnableSensitiveDataLogging();
                options.UseQueryTrackingBehavior(QueryTrackingBehavior.NoTracking);
            });
            
            // تكوين Redis من الحاوية
            services.AddSingleton<IRedisConnectionManager>(sp =>
            {
                var manager = new RedisConnectionManager(_containers.RedisConnectionString);
                manager.InitializeAsync().GetAwaiter().GetResult();
                return manager;
            });
            
            // تسجيل الخدمات
            services.AddScoped<IIndexingService, RedisIndexingSystem>();
            services.AddScoped<IPropertyRepository, PropertyRepository>();
            services.AddScoped<IUnitRepository, UnitRepository>();
            services.AddScoped<IBookingRepository, BookingRepository>();
            
            // إضافة logging
            services.AddLogging(builder =>
            {
                builder.AddConsole();
                builder.SetMinimumLevel(LogLevel.Information);
            });
            
            await Task.CompletedTask;
        }
        
        protected override async Task InitializeDatabaseAsync()
        {
            // إنشاء قاعدة البيانات
            await DbContext.Database.EnsureCreatedAsync();
            
            // إضافة البيانات الأساسية
            await SeedBaseDataAsync();
        }
        
        protected override async Task PerformEntityCleanupAsync(List<Guid> entityIds)
        {
            if (!entityIds.Any())
                return;
            
            // حذف من قاعدة البيانات
            var sql = @"
                DELETE FROM units WHERE property_id = ANY(@ids);
                DELETE FROM properties WHERE id = ANY(@ids);
            ";
            
            await DbContext.Database.ExecuteSqlRawAsync(sql, entityIds.ToArray());
            
            // مسح Redis
            await _containers.FlushRedisAsync();
        }
        
        #region Test Cases
        
        [Fact]
        public async Task FullIndexingAndSearchFlow_ShouldWorkEndToEnd()
        {
            // Arrange
            Output.WriteLine("🚀 Starting full end-to-end test");
            
            var property = TestDataBuilder.CompleteProperty(TestId);
            TrackEntity(property.Id);
            
            // Act 1: حفظ في قاعدة البيانات
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            
            // Act 2: فهرسة العقار
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            
            // Act 3: البحث عن العقار
            var searchResult = await WaitForConditionAsync(
                async () => await IndexingService.SearchAsync(new PropertySearchRequest
                {
                    SearchText = property.Name,
                    PageNumber = 1,
                    PageSize = 10
                }),
                result => result.TotalCount > 0,
                TimeSpan.FromSeconds(5)
            );
            
            // Assert
            searchResult.Should().HaveAtLeast(1);
            searchResult.Should().ContainProperty(property.Id);
            
            var foundProperty = searchResult.Properties.First(p => p.Id == property.Id.ToString());
            foundProperty.Should().HaveName(property.Name);
            foundProperty.Should().BeInCity(property.City);
            
            Output.WriteLine($"✅ Property {property.Id} indexed and found successfully");
        }
        
        [Fact]
        public async Task ConcurrentIndexing_ShouldHandleMultipleOperations()
        {
            // Arrange
            Output.WriteLine("🚀 Testing concurrent indexing");
            
            var propertyCount = 10;
            var properties = TestDataBuilder.BatchProperties(propertyCount, TestId);
            TrackEntities(properties.Select(p => p.Id));
            
            // حفظ في قاعدة البيانات
            await DbContext.Properties.AddRangeAsync(properties);
            await DbContext.SaveChangesAsync();
            
            // Act: فهرسة متزامنة
            var indexingTasks = new List<Task>();
            
            foreach (var property in properties)
            {
                indexingTasks.Add(Task.Run(async () =>
                {
                    await _concurrencyLimiter.WaitAsync();
                    try
                    {
                        // استخدام scope منفصل لكل task
                        using var scope = CreateIsolatedScope();
                        var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                        
                        await indexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
                    }
                    finally
                    {
                        _concurrencyLimiter.Release();
                    }
                }));
            }
            
            await Task.WhenAll(indexingTasks);
            
            // Assert: التحقق من فهرسة جميع العقارات
            var searchResult = await WaitForConditionAsync(
                async () => await IndexingService.SearchAsync(new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 100
                }),
                result => result.TotalCount >= propertyCount,
                TimeSpan.FromSeconds(10)
            );
            
            searchResult.Should().HaveAtLeast(propertyCount);
            
            foreach (var property in properties)
            {
                searchResult.Should().ContainProperty(property.Id);
            }
            
            Output.WriteLine($"✅ Successfully indexed {propertyCount} properties concurrently");
        }
        
        [Fact]
        public async Task UpdateAndDelete_ShouldReflectInSearch()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(TestId);
            property.City = "صنعاء";
            TrackEntity(property.Id);
            
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            
            // Act 1: تحديث المدينة
            property.City = "عدن";
            DbContext.Properties.Update(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyUpdatedAsync(property.Id, TestCancellation.Token);
            
            // Assert 1: التحقق من التحديث
            var searchAfterUpdate = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                City = "عدن",
                PageNumber = 1,
                PageSize = 10
            });
            
            searchAfterUpdate.Should().ContainProperty(property.Id);
            
            // Act 2: حذف العقار
            DbContext.Properties.Remove(property);
            await DbContext.SaveChangesAsync();
            await IndexingService.OnPropertyDeletedAsync(property.Id, TestCancellation.Token);
            
            // Assert 2: التحقق من الحذف
            var searchAfterDelete = await WaitForConditionAsync(
                async () => await IndexingService.SearchAsync(new PropertySearchRequest
                {
                    PageNumber = 1,
                    PageSize = 100
                }),
                result => !result.Properties.Any(p => p.Id == property.Id.ToString()),
                TimeSpan.FromSeconds(5)
            );
            
            searchAfterDelete.Should().NotContainProperty(property.Id);
            
            Output.WriteLine($"✅ Update and delete operations reflected correctly in search");
        }
        
        [Fact]
        public async Task ComplexFiltering_ShouldReturnCorrectResults()
        {
            // Arrange
            Output.WriteLine("🚀 Testing complex filtering");
            
            // إنشاء عقارات متنوعة
            var properties = new List<Property>
            {
                CreatePropertyWithSpecs("فندق الخليج", "صنعاء", 100, 4.5m),
                CreatePropertyWithSpecs("منتجع البحر", "عدن", 200, 4.0m),
                CreatePropertyWithSpecs("شقق النخيل", "صنعاء", 150, 3.5m),
                CreatePropertyWithSpecs("فيلا الورد", "تعز", 300, 5.0m),
                CreatePropertyWithSpecs("شاليه الساحل", "عدن", 250, 4.2m)
            };
            
            TrackEntities(properties.Select(p => p.Id));
            
            await DbContext.Properties.AddRangeAsync(properties);
            await DbContext.SaveChangesAsync();
            
            // فهرسة جميع العقارات
            foreach (var property in properties)
            {
                await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            }
            
            // Act & Assert: اختبار فلاتر مختلفة
            
            // 1. البحث بالمدينة
            var sanaaResults = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                City = "صنعاء",
                PageNumber = 1,
                PageSize = 10
            });
            
            sanaaResults.Should().HaveCount(2);
            sanaaResults.Should().AllBeInCity("صنعاء");
            
            // 2. البحث بنطاق السعر
            var priceResults = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                MinPrice = 150,
                MaxPrice = 250,
                PageNumber = 1,
                PageSize = 10
            });
            
            priceResults.Should().HaveAtLeast(3);
            priceResults.Should().HavePricesInRange(150, 250);
            
            // 3. البحث بالتقييم
            var ratingResults = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                MinRating = 4.0m,
                PageNumber = 1,
                PageSize = 10
            });
            
            ratingResults.Properties.All(p => p.AverageRating >= 4.0m).Should().BeTrue();
            
            // 4. البحث المركب
            var complexResults = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                City = "عدن",
                MinPrice = 200,
                MinRating = 4.0m,
                PageNumber = 1,
                PageSize = 10
            });
            
            complexResults.Should().HaveAtLeast(1);
            complexResults.Should().AllBeInCity("عدن");
            complexResults.Properties.All(p => p.MinPrice >= 200).Should().BeTrue();
            complexResults.Properties.All(p => p.AverageRating >= 4.0m).Should().BeTrue();
            
            Output.WriteLine($"✅ Complex filtering working correctly");
        }
        
        [Fact]
        public async Task Sorting_ShouldWorkCorrectly()
        {
            // Arrange
            var properties = new List<Property>
            {
                CreatePropertyWithSpecs("A", "صنعاء", 300, 3.0m),
                CreatePropertyWithSpecs("B", "صنعاء", 100, 5.0m),
                CreatePropertyWithSpecs("C", "صنعاء", 200, 4.0m)
            };
            
            TrackEntities(properties.Select(p => p.Id));
            
            await DbContext.Properties.AddRangeAsync(properties);
            await DbContext.SaveChangesAsync();
            
            foreach (var property in properties)
            {
                await IndexingService.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
            }
            
            // Act & Assert
            
            // 1. ترتيب حسب السعر تصاعدي
            var priceAscResults = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                City = "صنعاء",
                SortBy = "price_asc",
                PageNumber = 1,
                PageSize = 10
            });
            
            priceAscResults.Should().BeSortedByPrice(ascending: true);
            
            // 2. ترتيب حسب السعر تنازلي
            var priceDescResults = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                City = "صنعاء",
                SortBy = "price_desc",
                PageNumber = 1,
                PageSize = 10
            });
            
            priceDescResults.Should().BeSortedByPrice(ascending: false);
            
            // 3. ترتيب حسب التقييم
            var ratingResults = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                City = "صنعاء",
                SortBy = "rating",
                PageNumber = 1,
                PageSize = 10
            });
            
            ratingResults.Should().BeSortedByRating(descending: true);
            
            Output.WriteLine($"✅ Sorting working correctly");
        }
        
        [Fact]
        public async Task RaceCondition_ShouldHandleGracefully()
        {
            // Arrange
            var property = TestDataBuilder.SimpleProperty(TestId);
            TrackEntity(property.Id);
            
            await DbContext.Properties.AddAsync(property);
            await DbContext.SaveChangesAsync();
            
            // Act: عمليات متزامنة على نفس العقار
            var tasks = new List<Task>
            {
                Task.Run(async () =>
                {
                    using var scope = CreateIsolatedScope();
                    var service = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    await service.OnPropertyCreatedAsync(property.Id, TestCancellation.Token);
                }),
                Task.Run(async () =>
                {
                    using var scope = CreateIsolatedScope();
                    var service = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    property.City = "عدن";
                    await service.OnPropertyUpdatedAsync(property.Id, TestCancellation.Token);
                }),
                Task.Run(async () =>
                {
                    using var scope = CreateIsolatedScope();
                    var service = scope.ServiceProvider.GetRequiredService<IIndexingService>();
                    property.Name = "اسم جديد";
                    await service.OnPropertyUpdatedAsync(property.Id, TestCancellation.Token);
                })
            };
            
            await Task.WhenAll(tasks);
            
            // Assert: يجب أن يكون العقار مفهرساً بدون أخطاء
            var searchResult = await IndexingService.SearchAsync(new PropertySearchRequest
            {
                PageNumber = 1,
                PageSize = 100
            });
            
            searchResult.Should().ContainProperty(property.Id);
            
            Output.WriteLine($"✅ Race conditions handled gracefully");
        }
        
        #endregion
        
        #region Helper Methods
        
        private async Task SeedBaseDataAsync()
        {
            // إضافة أنواع العقارات
            var propertyTypes = new[]
            {
                new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000001"), Name = "منتجع" },
                new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000002"), Name = "شقق مفروشة" },
                new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000003"), Name = "فندق" },
                new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000004"), Name = "فيلا" },
                new PropertyType { Id = Guid.Parse("30000000-0000-0000-0000-000000000005"), Name = "شاليه" }
            };
            
            await DbContext.PropertyTypes.AddRangeAsync(propertyTypes);
            
            // إضافة أنواع الوحدات
            var unitTypes = new[]
            {
                new UnitType { Id = Guid.Parse("20000000-0000-0000-0000-000000000001"), Name = "غرفة مفردة" },
                new UnitType { Id = Guid.Parse("20000000-0000-0000-0000-000000000002"), Name = "غرفة مزدوجة" },
                new UnitType { Id = Guid.Parse("20000000-0000-0000-0000-000000000003"), Name = "جناح" },
                new UnitType { Id = Guid.Parse("20000000-0000-0000-0000-000000000004"), Name = "شقة" }
            };
            
            await DbContext.UnitTypes.AddRangeAsync(unitTypes);
            
            // إضافة المدن
            var cities = new[]
            {
                new City { Name = "صنعاء", Country = "اليمن" },
                new City { Name = "عدن", Country = "اليمن" },
                new City { Name = "تعز", Country = "اليمن" },
                new City { Name = "الحديدة", Country = "اليمن" },
                new City { Name = "إب", Country = "اليمن" }
            };
            
            await DbContext.Cities.AddRangeAsync(cities);
            
            await DbContext.SaveChangesAsync();
        }
        
        private Property CreatePropertyWithSpecs(string name, string city, decimal price, decimal rating)
        {
            var property = TestDataBuilder.PropertyWithUnits(2, TestId);
            property.Name = name;
            property.City = city;
            property.AverageRating = rating;
            
            foreach (var unit in property.Units)
            {
                unit.BasePrice = new Core.ValueObjects.Money(price, "YER");
            }
            
            return property;
        }
        
        #endregion
    }
}
