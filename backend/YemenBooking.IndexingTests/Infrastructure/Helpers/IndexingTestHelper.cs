using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Redis.Indexing;
using YemenBooking.IndexingTests.Infrastructure.Builders;
using StackExchange.Redis;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using CoreUnit = YemenBooking.Core.Entities.Unit;

namespace YemenBooking.IndexingTests.Infrastructure.Helpers
{
    /// <summary>
    /// مساعد اختبار الفهرسة والبحث
    /// </summary>
    public class IndexingTestHelper
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly IDatabase _redisDatabase;
        private readonly ILogger _logger;
        private readonly List<Guid> _trackedPropertyIds = new();
        private readonly List<string> _trackedRedisKeys = new();
        
        public IndexingTestHelper(IServiceProvider serviceProvider, ILogger logger)
        {
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            
            var redisManager = _serviceProvider.GetRequiredService<IRedisConnectionManager>();
            _redisDatabase = redisManager.GetDatabase();
        }
        
        /// <summary>
        /// إعداد بيانات اختبارية وفهرستها
        /// </summary>
        public async Task<List<Property>> SetupIndexedPropertiesAsync(int count = 3, string testId = null)
        {
            testId ??= Guid.NewGuid().ToString("N");
            var properties = new List<Property>();
            
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            for (int i = 0; i < count; i++)
            {
                var property = TestDataBuilder.SimpleProperty($"{testId}_{i}");
                properties.Add(property);
                
                // حفظ في قاعدة البيانات
                await dbContext.Properties.AddAsync(property);
                await dbContext.SaveChangesAsync();
                
                // فهرسة في Redis
                await indexingService.OnPropertyCreatedAsync(property.Id);
                
                _trackedPropertyIds.Add(property.Id);
                _logger.LogDebug($"Created and indexed property: {property.Id}");
            }
            
            // انتظار حتى تكتمل الفهرسة
            await WaitForIndexingCompletionAsync();
            
            return properties;
        }
        
        /// <summary>
        /// إعداد عقارات مع أنواع مختلفة
        /// </summary>
        public async Task<List<Property>> SetupPropertiesWithTypesAsync(Dictionary<string, int> typesCounts)
        {
            var properties = new List<Property>();
            
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            foreach (var (typeName, count) in typesCounts)
            {
                for (int i = 0; i < count; i++)
                {
                    var property = TestDataBuilder.SimpleProperty($"{typeName}_{i}");
                    
                    // تعيين النوع حسب الاسم
                    property.TypeId = GetPropertyTypeId(typeName);
                    property.Name = $"{typeName} {i}";
                    
                    properties.Add(property);
                    
                    await dbContext.Properties.AddAsync(property);
                    await dbContext.SaveChangesAsync();
                    await indexingService.OnPropertyCreatedAsync(property.Id);
                    
                    _trackedPropertyIds.Add(property.Id);
                }
            }
            
            await WaitForIndexingCompletionAsync();
            return properties;
        }
        
        /// <summary>
        /// إعداد عقارات مع نص بحث محدد
        /// </summary>
        public async Task<List<Property>> SetupPropertiesWithTextAsync(string[] names, string city = "صنعاء")
        {
            var properties = new List<Property>();
            
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            foreach (var name in names)
            {
                var property = TestDataBuilder.SimpleProperty(name);
                property.Name = name;
                property.City = city;
                properties.Add(property);
                
                await dbContext.Properties.AddAsync(property);
                await dbContext.SaveChangesAsync();
                await indexingService.OnPropertyCreatedAsync(property.Id);
                
                _trackedPropertyIds.Add(property.Id);
            }
            
            await WaitForIndexingCompletionAsync();
            return properties;
        }
        
        /// <summary>
        /// إعداد عقارات مع أسعار محددة
        /// </summary>
        public async Task<List<Property>> SetupPropertiesWithPricesAsync(Dictionary<Guid, decimal> propertyPrices)
        {
            var properties = new List<Property>();
            
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            var indexingService = scope.ServiceProvider.GetRequiredService<IIndexingService>();
            
            foreach (var (id, price) in propertyPrices)
            {
                var property = TestDataBuilder.SimpleProperty($"price_{price}");
                property.Id = id;
                
                // إضافة وحدة مع السعر المحدد
                var unit = TestDataBuilder.UnitForProperty(property.Id);
                unit.BasePrice = new Money(price, "YER");
                property.Units = new List<CoreUnit> { unit };
                
                properties.Add(property);
                
                await dbContext.Properties.AddAsync(property);
                await dbContext.SaveChangesAsync();
                await indexingService.OnPropertyCreatedAsync(property.Id);
                
                _trackedPropertyIds.Add(property.Id);
            }
            
            await WaitForIndexingCompletionAsync();
            return properties;
        }
        
        /// <summary>
        /// التحقق من وجود عقار في الفهرس
        /// </summary>
        public async Task<bool> IsPropertyIndexedAsync(Guid propertyId)
        {
            var key = $"property:{propertyId}";
            return await _redisDatabase.KeyExistsAsync(key);
        }
        
        /// <summary>
        /// الحصول على بيانات عقار مفهرس
        /// </summary>
        public async Task<Dictionary<string, object>> GetIndexedPropertyAsync(Guid propertyId)
        {
            var key = $"property:{propertyId}";
            var json = await _redisDatabase.StringGetAsync(key);
            
            if (json.IsNullOrEmpty)
                return null;
            
            return System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, object>>(json);
        }
        
        /// <summary>
        /// انتظار اكتمال الفهرسة
        /// </summary>
        private async Task WaitForIndexingCompletionAsync()
        {
            // انتظار قليل لضمان اكتمال العمليات غير المتزامنة
            await Task.Delay(100);
            
            // التحقق من فهرسة جميع العقارات
            var maxAttempts = 30;
            for (int i = 0; i < maxAttempts; i++)
            {
                var allIndexed = true;
                foreach (var id in _trackedPropertyIds)
                {
                    if (!await IsPropertyIndexedAsync(id))
                    {
                        allIndexed = false;
                        break;
                    }
                }
                
                if (allIndexed)
                {
                    _logger.LogDebug("All properties indexed successfully");
                    return;
                }
                
                await Task.Delay(100);
            }
            
            _logger.LogWarning("Indexing did not complete within timeout");
        }
        
        /// <summary>
        /// تنظيف البيانات الاختبارية
        /// </summary>
        public async Task CleanupAsync()
        {
            try
            {
                // حذف من Redis أولاً (لا يحتاج ServiceProvider)
                foreach (var id in _trackedPropertyIds)
                {
                    var key = $"property:{id}";
                    try
                    {
                        await _redisDatabase.KeyDeleteAsync(key);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning($"Failed to delete Redis key {key}: {ex.Message}");
                    }
                    _trackedRedisKeys.Remove(key);
                }
                
                // حذف مفاتيح Redis الأخرى
                foreach (var key in _trackedRedisKeys)
                {
                    try
                    {
                        await _redisDatabase.KeyDeleteAsync(key);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning($"Failed to delete Redis key {key}: {ex.Message}");
                    }
                }
                
                // حذف من قاعدة البيانات فقط إذا كان ServiceProvider متاحاً
                if (_trackedPropertyIds.Any())
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                        
                        var properties = await dbContext.Properties
                            .Where(p => _trackedPropertyIds.Contains(p.Id))
                            .ToListAsync();
                        
                        if (properties.Any())
                        {
                            dbContext.Properties.RemoveRange(properties);
                            await dbContext.SaveChangesAsync();
                        }
                    }
                    catch (ObjectDisposedException)
                    {
                        _logger.LogWarning("ServiceProvider was disposed, skipping database cleanup");
                    }
                    catch (Exception ex)
                    {
                        _logger.LogWarning($"Failed to cleanup database: {ex.Message}");
                    }
                }
                
                _trackedPropertyIds.Clear();
                _trackedRedisKeys.Clear();
                
                _logger.LogDebug("Test data cleaned up successfully");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during test data cleanup");
            }
        }
        
        private Guid GetPropertyTypeId(string typeName)
        {
            return typeName?.ToLower() switch
            {
                "فندق" or "hotel" => Guid.Parse("30000000-0000-0000-0000-000000000003"),
                "منتجع" or "resort" => Guid.Parse("30000000-0000-0000-0000-000000000001"),
                "شقق" or "apartment" => Guid.Parse("30000000-0000-0000-0000-000000000002"),
                "فيلا" or "villa" => Guid.Parse("30000000-0000-0000-0000-000000000004"),
                "شاليه" or "chalet" => Guid.Parse("30000000-0000-0000-0000-000000000005"),
                _ => Guid.Parse("30000000-0000-0000-0000-000000000003") // Default to hotel
            };
        }
        
        public void TrackRedisKey(string key)
        {
            if (!_trackedRedisKeys.Contains(key))
            {
                _trackedRedisKeys.Add(key);
            }
        }
    }
}
