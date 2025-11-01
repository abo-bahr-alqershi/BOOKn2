using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using Xunit;
using Xunit.Abstractions;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Redis.Configuration;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Repositories;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Services.RedisConnectionManager;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Core.Entities;

namespace YemenBooking.IndexingTests.Tests
{
    /// <summary>
    /// الفئة الأساسية لجميع الاختبارات
    /// توفر الإعدادات المشتركة والوظائف المساعدة
    /// </summary>
    public abstract class TestBase : IClassFixture<TestDatabaseFixture>, IDisposable
    {
        protected readonly TestDatabaseFixture _fixture;
        protected readonly ITestOutputHelper _output;
        protected readonly IServiceProvider _serviceProvider;
        protected readonly IIndexingService _indexingService;
        protected readonly IPropertyRepository _propertyRepository;
        protected readonly IUnitRepository _unitRepository;
        protected readonly IRedisConnectionManager _redisManager;
        protected readonly ILogger _logger;
        protected readonly YemenBookingDbContext _dbContext;
        protected readonly Random _random = new Random();

        /// <summary>
        /// مُنشئ الفئة الأساسية
        /// </summary>
        /// <param name="fixture">موفر البيانات والخدمات</param>
        /// <param name="output">مخرجات الاختبار</param>
        protected TestBase(TestDatabaseFixture fixture, ITestOutputHelper output)
        {
            _fixture = fixture;
            _output = output;
            _serviceProvider = fixture.ServiceProvider;
            
            // الحصول على الخدمات المطلوبة
            using var scope = _serviceProvider.CreateScope();
            _indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            _propertyRepository = scope.ServiceProvider.GetRequiredService<IPropertyRepository>();
            _unitRepository = scope.ServiceProvider.GetRequiredService<IUnitRepository>();
            _redisManager = scope.ServiceProvider.GetRequiredService<IRedisConnectionManager>();
            _dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            var loggerFactory = scope.ServiceProvider.GetRequiredService<ILoggerFactory>();
            _logger = loggerFactory.CreateLogger(GetType());
        }

        /// <summary>
        /// إنشاء عقار اختباري
        /// </summary>
        protected async Task<Property> CreateTestPropertyAsync(
            string name = null,
            string city = null,
            Guid? typeId = null,
            decimal minPrice = 100,
            bool isActive = true,
            bool isApproved = true)
        {
            name ??= $"عقار اختباري {_random.Next(1000, 9999)}";
            city ??= GetRandomCity();
            typeId ??= GetRandomPropertyType();

            var property = new Property
            {
                Id = Guid.NewGuid(),
                Name = name,
                City = city,
                TypeId = typeId.Value,
                IsActive = isActive,
                IsApproved = isApproved,
                OwnerId = Guid.NewGuid(),
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow,
                Address = $"شارع {_random.Next(1, 100)}",
                Description = "وصف اختباري",
                Latitude = 15.3694 + (_random.NextDouble() * 0.1),
                Longitude = 44.1910 + (_random.NextDouble() * 0.1),
                StarRating = _random.Next(1, 6),
                AverageRating = (decimal)(_random.NextDouble() * 5)
            };

            _dbContext.Properties.Add(property);
            await _dbContext.SaveChangesAsync();

            // إنشاء وحدات للعقار
            await CreateTestUnitsForPropertyAsync(property.Id, _random.Next(1, 5));

            return property;
        }

        /// <summary>
        /// إنشاء وحدات اختبارية للعقار
        /// </summary>
        protected async Task CreateTestUnitsForPropertyAsync(Guid propertyId, int count = 3)
        {
            for (int i = 0; i < count; i++)
            {
                var unit = new Unit
                {
                    Id = Guid.NewGuid(),
                    PropertyId = propertyId,
                    Name = $"وحدة {i + 1}",
                    UnitTypeId = GetRandomUnitType(),
                    MaxCapacity = _random.Next(2, 10),
                    AdultsCapacity = _random.Next(2, 8),
                    ChildrenCapacity = _random.Next(0, 4),
                    IsAvailable = true,
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow,
                    BasePrice = new Money
                    {
                        Amount = _random.Next(50, 500) * 10,
                        Currency = "YER",
                        ExchangeRate = 1
                    }
                };

                _dbContext.Units.Add(unit);
            }

            await _dbContext.SaveChangesAsync();
        }

        /// <summary>
        /// إنشاء بيانات اختبار شاملة
        /// </summary>
        protected async Task<List<Property>> CreateComprehensiveTestDataAsync()
        {
            var properties = new List<Property>();

            // إنشاء عقارات في مدن مختلفة
            var cities = new[] { "صنعاء", "عدن", "تعز", "الحديدة", "إب" };
            var types = GetAllPropertyTypes();

            foreach (var city in cities)
            {
                foreach (var type in types)
                {
                    var property = await CreateTestPropertyAsync(
                        name: $"{GetPropertyTypeName(type)} في {city}",
                        city: city,
                        typeId: type,
                        minPrice: _random.Next(50, 1000),
                        isActive: true,
                        isApproved: true
                    );
                    properties.Add(property);
                }
            }

            return properties;
        }

        /// <summary>
        /// تنظيف البيانات الاختبارية
        /// </summary>
        protected async Task CleanupTestDataAsync()
        {
            // حذف جميع البيانات الاختبارية
            _dbContext.Units.RemoveRange(_dbContext.Units);
            _dbContext.Properties.RemoveRange(_dbContext.Properties);
            await _dbContext.SaveChangesAsync();

            // تنظيف Redis
            var db = _redisManager.GetDatabase();
            await db.ExecuteAsync("FLUSHDB");
        }

        /// <summary>
        /// التحقق من نتائج البحث
        /// </summary>
        protected void AssertSearchResults(
            PropertySearchResult result,
            int? expectedMinCount = null,
            int? expectedMaxCount = null,
            string expectedCity = null,
            Guid? expectedType = null,
            decimal? expectedMinPrice = null,
            decimal? expectedMaxPrice = null)
        {
            Assert.NotNull(result);
            Assert.NotNull(result.Properties);

            if (expectedMinCount.HasValue)
                Assert.True(result.TotalCount >= expectedMinCount.Value,
                    $"العدد الفعلي {result.TotalCount} أقل من المتوقع {expectedMinCount}");

            if (expectedMaxCount.HasValue)
                Assert.True(result.TotalCount <= expectedMaxCount.Value,
                    $"العدد الفعلي {result.TotalCount} أكثر من المتوقع {expectedMaxCount}");

            if (!string.IsNullOrEmpty(expectedCity))
                Assert.All(result.Properties, p =>
                    Assert.Equal(expectedCity, p.City, StringComparer.OrdinalIgnoreCase));

            if (expectedType.HasValue)
                Assert.All(result.Properties, p =>
                    Assert.Equal(expectedType.Value.ToString(), p.PropertyType));

            if (expectedMinPrice.HasValue)
                Assert.All(result.Properties, p =>
                    Assert.True(p.MinPrice >= expectedMinPrice.Value));

            if (expectedMaxPrice.HasValue)
                Assert.All(result.Properties, p =>
                    Assert.True(p.MinPrice <= expectedMaxPrice.Value));
        }

        /// <summary>
        /// قياس زمن التنفيذ
        /// </summary>
        protected async Task<(T Result, long ElapsedMs)> MeasureExecutionTimeAsync<T>(
            Func<Task<T>> action, 
            string operationName)
        {
            var stopwatch = System.Diagnostics.Stopwatch.StartNew();
            var result = await action();
            stopwatch.Stop();

            _output.WriteLine($"⏱️ {operationName}: {stopwatch.ElapsedMilliseconds}ms");
            
            return (result, stopwatch.ElapsedMilliseconds);
        }

        #region Helper Methods

        private string GetRandomCity()
        {
            var cities = new[] { "صنعاء", "عدن", "تعز", "الحديدة", "إب", "ذمار", "المكلا" };
            return cities[_random.Next(cities.Length)];
        }

        private Guid GetRandomPropertyType()
        {
            var types = GetAllPropertyTypes();
            return types[_random.Next(types.Length)];
        }

        private Guid GetRandomUnitType()
        {
            // معرفات أنواع الوحدات الافتراضية
            var types = new[]
            {
                Guid.Parse("20000000-0000-0000-0000-000000000001"), // غرفة مفردة
                Guid.Parse("20000000-0000-0000-0000-000000000002"), // غرفة مزدوجة
                Guid.Parse("20000000-0000-0000-0000-000000000003"), // جناح
                Guid.Parse("20000000-0000-0000-0000-000000000004"), // شقة
            };
            return types[_random.Next(types.Length)];
        }

        private Guid[] GetAllPropertyTypes()
        {
            return new[]
            {
                Guid.Parse("30000000-0000-0000-0000-000000000001"), // منتجع
                Guid.Parse("30000000-0000-0000-0000-000000000002"), // شقق مفروشة
                Guid.Parse("30000000-0000-0000-0000-000000000003"), // فندق
                Guid.Parse("30000000-0000-0000-0000-000000000004"), // فيلا
                Guid.Parse("30000000-0000-0000-0000-000000000005"), // شاليه
            };
        }

        private string GetPropertyTypeName(Guid typeId)
        {
            var typeNames = new Dictionary<string, string>
            {
                ["30000000-0000-0000-0000-000000000001"] = "منتجع",
                ["30000000-0000-0000-0000-000000000002"] = "شقق مفروشة",
                ["30000000-0000-0000-0000-000000000003"] = "فندق",
                ["30000000-0000-0000-0000-000000000004"] = "فيلا",
                ["30000000-0000-0000-0000-000000000005"] = "شاليه",
            };

            return typeNames.GetValueOrDefault(typeId.ToString(), "عقار");
        }

        #endregion

        public virtual void Dispose()
        {
            // التنظيف إذا لزم الأمر
        }
    }
}
