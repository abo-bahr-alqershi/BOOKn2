using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Infrastructure.Redis.Core.Interfaces;
using YemenBooking.Infrastructure.Data.Context;
using Microsoft.EntityFrameworkCore;
using StackExchange.Redis;
using System.Text.Json;

namespace YemenBooking.Infrastructure.Redis.Indexing
{
    /// <summary>
    /// خدمة الفهرسة الرئيسية - تطبق مبادئ العزل والحتمية
    /// </summary>
    public sealed class IndexingService : IIndexingService, IDisposable
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly IRedisConnectionManager _redisManager;
        private readonly ILogger<IndexingService> _logger;
        private readonly SemaphoreSlim _indexingLock;
        private readonly JsonSerializerOptions _jsonOptions;
        private bool _disposed;

        // مفاتيح Redis
        private const string PROPERTY_KEY_PREFIX = "property:";
        private const string UNIT_KEY_PREFIX = "unit:";
        private const string SEARCH_INDEX_KEY = "search:index";
        private const string CITY_INDEX_KEY = "index:city:";
        private const string TYPE_INDEX_KEY = "index:type:";
        private const string PRICE_INDEX_KEY = "index:price";
        private const string RATING_INDEX_KEY = "index:rating";

        public IndexingService(
            IServiceProvider serviceProvider,
            IRedisConnectionManager redisManager,
            ILogger<IndexingService> logger)
        {
            _serviceProvider = serviceProvider ?? throw new ArgumentNullException(nameof(serviceProvider));
            _redisManager = redisManager ?? throw new ArgumentNullException(nameof(redisManager));
            _logger = logger ?? throw new ArgumentNullException(nameof(logger));
            
            _indexingLock = new SemaphoreSlim(Environment.ProcessorCount * 2);
            _jsonOptions = new JsonSerializerOptions
            {
                PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                WriteIndented = false
            };
        }

        #region Property Operations

        /// <summary>
        /// فهرسة عقار جديد
        /// </summary>
        public async Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            if (propertyId == Guid.Empty)
            {
                throw new ArgumentException("Invalid property ID", nameof(propertyId));
            }

            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                
                var property = await dbContext.Properties
                    .Include(p => p.Units)
                    .Include(p => p.PropertyType)
                    .Include(p => p.Amenities)
                    .AsNoTracking()
                    .FirstOrDefaultAsync(p => p.Id == propertyId, cancellationToken);

                if (property == null)
                {
                    _logger.LogWarning("Property {PropertyId} not found for indexing", propertyId);
                    return;
                }

                await IndexPropertyAsync(property, cancellationToken);
                _logger.LogInformation("Successfully indexed property {PropertyId}", propertyId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error indexing property {PropertyId}", propertyId);
                throw;
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        /// <summary>
        /// تحديث فهرسة عقار
        /// </summary>
        public async Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            if (propertyId == Guid.Empty)
            {
                throw new ArgumentException("Invalid property ID", nameof(propertyId));
            }

            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                // حذف الفهرسة القديمة
                await RemovePropertyFromIndexesAsync(propertyId, cancellationToken);
                
                // إعادة الفهرسة
                await OnPropertyCreatedAsync(propertyId, cancellationToken);
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        /// <summary>
        /// حذف فهرسة عقار
        /// </summary>
        public async Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            if (propertyId == Guid.Empty)
            {
                throw new ArgumentException("Invalid property ID", nameof(propertyId));
            }

            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                await RemovePropertyFromIndexesAsync(propertyId, cancellationToken);
                _logger.LogInformation("Successfully removed property {PropertyId} from indexes", propertyId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error removing property {PropertyId} from indexes", propertyId);
                throw;
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        #endregion

        #region Unit Operations

        /// <summary>
        /// فهرسة وحدة جديدة
        /// </summary>
        public async Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            if (unitId == Guid.Empty || propertyId == Guid.Empty)
            {
                throw new ArgumentException("Invalid unit or property ID");
            }

            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                
                // التحقق من وجود العقار أولاً
                var propertyExists = await dbContext.Properties
                    .AsNoTracking()
                    .AnyAsync(p => p.Id == propertyId, cancellationToken);
                    
                if (!propertyExists)
                {
                    _logger.LogError("Property {PropertyId} not found for unit {UnitId}. Cannot index unit without valid property", propertyId, unitId);
                    throw new InvalidOperationException($"Property {propertyId} not found. Unit must be associated with an existing property.");
                }
                
                var unit = await dbContext.Units
                    .Include(u => u.UnitType)
                    .AsNoTracking()
                    .FirstOrDefaultAsync(u => u.Id == unitId, cancellationToken);

                if (unit == null)
                {
                    _logger.LogWarning("Unit {UnitId} not found for indexing", unitId);
                    return;
                }
                
                // التحقق من أن الوحدة تنتمي للعقار الصحيح
                if (unit.PropertyId != propertyId)
                {
                    _logger.LogError("Unit {UnitId} belongs to property {ActualPropertyId}, not {RequestedPropertyId}", 
                        unitId, unit.PropertyId, propertyId);
                    throw new InvalidOperationException($"Unit {unitId} does not belong to property {propertyId}");
                }

                await IndexUnitAsync(unit, propertyId, cancellationToken);
                
                // تحديث فهرسة العقار
                await UpdatePropertyAggregatesAsync(propertyId, cancellationToken);
                
                _logger.LogInformation("Successfully indexed unit {UnitId} for property {PropertyId}", unitId, propertyId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error indexing unit {UnitId} for property {PropertyId}", unitId, propertyId);
                throw;
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        /// <summary>
        /// تحديث فهرسة وحدة
        /// </summary>
        public async Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await OnUnitCreatedAsync(unitId, propertyId, cancellationToken);
        }

        /// <summary>
        /// حذف فهرسة وحدة
        /// </summary>
        public async Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            if (unitId == Guid.Empty || propertyId == Guid.Empty)
            {
                throw new ArgumentException("Invalid unit or property ID");
            }

            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                var db = _redisManager.GetDatabase();
                var unitKey = $"{UNIT_KEY_PREFIX}{unitId}";
                
                await db.KeyDeleteAsync(unitKey);
                await UpdatePropertyAggregatesAsync(propertyId, cancellationToken);
                
                _logger.LogInformation("Successfully removed unit {UnitId} from indexes", unitId);
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        #endregion

        #region Availability & Pricing

        /// <summary>
        /// تحديث الإتاحة
        /// </summary>
        public async Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId, List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default)
        {
            if (unitId == Guid.Empty || propertyId == Guid.Empty)
            {
                throw new ArgumentException("Invalid unit or property ID");
            }

            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                var db = _redisManager.GetDatabase();
                var availabilityKey = $"availability:{unitId}";
                
                // تخزين نطاقات الإتاحة
                var availabilityData = JsonSerializer.Serialize(availableRanges, _jsonOptions);
                await db.StringSetAsync(availabilityKey, availabilityData, TimeSpan.FromDays(30));
                
                _logger.LogInformation("Updated availability for unit {UnitId}", unitId);
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        /// <summary>
        /// تحديث قواعد التسعير
        /// </summary>
        public async Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId, List<PricingRule> pricingRules, CancellationToken cancellationToken = default)
        {
            if (unitId == Guid.Empty || propertyId == Guid.Empty)
            {
                throw new ArgumentException("Invalid unit or property ID");
            }

            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                var db = _redisManager.GetDatabase();
                var pricingKey = $"pricing:{unitId}";
                
                // تخزين قواعد التسعير
                var pricingData = JsonSerializer.Serialize(pricingRules, _jsonOptions);
                await db.StringSetAsync(pricingKey, pricingData, TimeSpan.FromDays(30));
                
                // تحديث فهرس السعر
                await UpdatePriceIndexAsync(unitId, propertyId, pricingRules, cancellationToken);
                
                _logger.LogInformation("Updated pricing rules for unit {UnitId}", unitId);
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        #endregion

        #region Dynamic Fields

        /// <summary>
        /// تحديث حقل ديناميكي
        /// </summary>
        public async Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName, string fieldValue, bool isAdd, CancellationToken cancellationToken = default)
        {
            if (propertyId == Guid.Empty || string.IsNullOrWhiteSpace(fieldName))
            {
                throw new ArgumentException("Invalid property ID or field name");
            }

            await _indexingLock.WaitAsync(cancellationToken);
            try
            {
                var db = _redisManager.GetDatabase();
                var dynamicFieldKey = $"dynamic:{propertyId}:{fieldName}";
                
                if (isAdd)
                {
                    await db.StringSetAsync(dynamicFieldKey, fieldValue, TimeSpan.FromDays(90));
                }
                else
                {
                    await db.KeyDeleteAsync(dynamicFieldKey);
                }
                
                _logger.LogInformation("Updated dynamic field {FieldName} for property {PropertyId}", fieldName, propertyId);
            }
            finally
            {
                _indexingLock.Release();
            }
        }

        #endregion

        #region Search

        /// <summary>
        /// البحث في العقارات
        /// </summary>
        public async Task<PropertySearchResult> SearchAsync(PropertySearchRequest request, CancellationToken cancellationToken = default)
        {
            if (request == null)
            {
                throw new ArgumentNullException(nameof(request));
            }

            try
            {
                using var scope = _serviceProvider.CreateScope();
                var searchEngine = new SearchEngine(_redisManager, scope.ServiceProvider, _logger);
                
                return await searchEngine.ExecuteSearchAsync(request, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error executing search");
                throw;
            }
        }

        #endregion

        #region Maintenance

        /// <summary>
        /// تحسين قاعدة البيانات
        /// </summary>
        public async Task OptimizeDatabaseAsync()
        {
            try
            {
                _logger.LogInformation("Starting database optimization");
                
                var server = _redisManager.GetServer();
                
                // تنفيذ عمليات التحسين
                await Task.Run(() => server.DatabaseSize());
                
                // حذف المفاتيح المنتهية الصلاحية
                var db = _redisManager.GetDatabase();
                await Task.CompletedTask;
                
                _logger.LogInformation("Database optimization completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error optimizing database");
                throw;
            }
        }

        /// <summary>
        /// إعادة بناء الفهرس بالكامل
        /// </summary>
        public async Task RebuildIndexAsync(CancellationToken cancellationToken = default)
        {
            try
            {
                _logger.LogInformation("Starting index rebuild");
                
                using var scope = _serviceProvider.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
                
                // مسح الفهارس القديمة
                await ClearAllIndexesAsync(cancellationToken);
                
                // إعادة فهرسة جميع العقارات
                var properties = await dbContext.Properties
                    .Include(p => p.Units)
                    .Include(p => p.PropertyType)
                    .Include(p => p.Amenities)
                    .AsNoTracking()
                    .ToListAsync(cancellationToken);
                
                var batchSize = 100;
                for (int i = 0; i < properties.Count; i += batchSize)
                {
                    var batch = properties.Skip(i).Take(batchSize);
                    var tasks = batch.Select(p => IndexPropertyAsync(p, cancellationToken));
                    await Task.WhenAll(tasks);
                    
                    _logger.LogInformation("Indexed {Count} properties", i + batch.Count());
                }
                
                _logger.LogInformation("Index rebuild completed. Total properties: {Count}", properties.Count);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error rebuilding index");
                throw;
            }
        }

        #endregion

        #region Private Methods

        /// <summary>
        /// فهرسة عقار
        /// </summary>
        private async Task IndexPropertyAsync(Property property, CancellationToken cancellationToken)
        {
            var db = _redisManager.GetDatabase();
            var propertyKey = $"{PROPERTY_KEY_PREFIX}{property.Id}";
            
            // إنشاء بيانات الفهرسة
            var indexData = new PropertyIndexData
            {
                Id = property.Id,
                Name = property.Name,
                Description = property.Description,
                City = property.City,
                Address = property.Address,
                PropertyTypeId = property.TypeId,
                PropertyTypeName = property.PropertyType?.Name,
                OwnerId = property.OwnerId,
                IsActive = property.IsActive,
                IsApproved = property.IsApproved,
                AverageRating = property.AverageRating,
                TotalReviews = 0, // يمكن حسابها من Reviews
                MinPrice = property.Units?.Any() == true ? property.Units.Min(u => u.BasePrice?.Amount ?? 0) : 0,
                MaxPrice = property.Units?.Any() == true ? property.Units.Max(u => u.BasePrice?.Amount ?? 0) : 0,
                TotalUnits = property.Units?.Count ?? 0,
                Amenities = property.Amenities?.Select(a => a.Id.ToString()).ToList() ?? new List<string>(),
                CreatedAt = property.CreatedAt,
                UpdatedAt = property.UpdatedAt
            };
            
            // تخزين البيانات الأساسية
            var json = JsonSerializer.Serialize(indexData, _jsonOptions);
            await db.StringSetAsync(propertyKey, json, TimeSpan.FromDays(30));
            
            // إضافة إلى الفهارس
            await AddToIndexesAsync(property, indexData, cancellationToken);
        }

        /// <summary>
        /// فهرسة وحدة
        /// </summary>
        private async Task IndexUnitAsync(Unit unit, Guid propertyId, CancellationToken cancellationToken)
        {
            var db = _redisManager.GetDatabase();
            var unitKey = $"{UNIT_KEY_PREFIX}{unit.Id}";
            
            var unitData = new UnitIndexData
            {
                Id = unit.Id,
                PropertyId = propertyId,
                Name = unit.Name,
                UnitTypeId = unit.UnitTypeId,
                UnitTypeName = unit.UnitType?.Name,
                MaxCapacity = unit.MaxCapacity,
                AdultsCapacity = unit.AdultsCapacity ?? 0,
                ChildrenCapacity = unit.ChildrenCapacity ?? 0,
                BasePrice = unit.BasePrice?.Amount ?? 0,
                Currency = unit.BasePrice?.Currency ?? "YER",
                IsActive = unit.IsActive
            };
            
            var json = JsonSerializer.Serialize(unitData, _jsonOptions);
            await db.StringSetAsync(unitKey, json, TimeSpan.FromDays(30));
        }

        /// <summary>
        /// إضافة إلى الفهارس
        /// </summary>
        private async Task AddToIndexesAsync(Property property, PropertyIndexData indexData, CancellationToken cancellationToken)
        {
            var db = _redisManager.GetDatabase();
            var tasks = new List<Task>();
            
            // فهرس المدينة
            if (!string.IsNullOrWhiteSpace(property.City))
            {
                var cityKey = $"{CITY_INDEX_KEY}{property.City.ToLower()}";
                tasks.Add(db.SetAddAsync(cityKey, property.Id.ToString()));
            }
            
            // فهرس نوع العقار
            if (property.TypeId != Guid.Empty)
            {
                var typeKey = $"{TYPE_INDEX_KEY}{property.TypeId}";
                tasks.Add(db.SetAddAsync(typeKey, property.Id.ToString()));
            }
            
            // فهرس السعر (Sorted Set)
            if (indexData.MinPrice > 0)
            {
                tasks.Add(db.SortedSetAddAsync(PRICE_INDEX_KEY, property.Id.ToString(), (double)indexData.MinPrice));
            }
            
            // فهرس التقييم (Sorted Set)
            if (indexData.AverageRating > 0)
            {
                tasks.Add(db.SortedSetAddAsync(RATING_INDEX_KEY, property.Id.ToString(), (double)indexData.AverageRating));
            }
            
            // فهرس البحث النصي
            tasks.Add(db.SetAddAsync(SEARCH_INDEX_KEY, property.Id.ToString()));
            
            await Task.WhenAll(tasks);
        }

        /// <summary>
        /// إزالة من الفهارس
        /// </summary>
        private async Task RemovePropertyFromIndexesAsync(Guid propertyId, CancellationToken cancellationToken)
        {
            var db = _redisManager.GetDatabase();
            var propertyKey = $"{PROPERTY_KEY_PREFIX}{propertyId}";
            
            // الحصول على البيانات الحالية
            var json = await db.StringGetAsync(propertyKey);
            if (json.HasValue)
            {
                var indexData = JsonSerializer.Deserialize<PropertyIndexData>(json, _jsonOptions);
                
                var tasks = new List<Task>
                {
                    // حذف البيانات الأساسية
                    db.KeyDeleteAsync(propertyKey),
                    
                    // حذف من فهرس البحث
                    db.SetRemoveAsync(SEARCH_INDEX_KEY, propertyId.ToString()),
                    
                    // حذف من فهرس السعر
                    db.SortedSetRemoveAsync(PRICE_INDEX_KEY, propertyId.ToString()),
                    
                    // حذف من فهرس التقييم
                    db.SortedSetRemoveAsync(RATING_INDEX_KEY, propertyId.ToString())
                };
                
                // حذف من فهرس المدينة
                if (!string.IsNullOrWhiteSpace(indexData?.City))
                {
                    var cityKey = $"{CITY_INDEX_KEY}{indexData.City.ToLower()}";
                    tasks.Add(db.SetRemoveAsync(cityKey, propertyId.ToString()));
                }
                
                // حذف من فهرس النوع
                if (indexData?.PropertyTypeId != Guid.Empty)
                {
                    var typeKey = $"{TYPE_INDEX_KEY}{indexData.PropertyTypeId}";
                    tasks.Add(db.SetRemoveAsync(typeKey, propertyId.ToString()));
                }
                
                await Task.WhenAll(tasks);
            }
        }

        /// <summary>
        /// تحديث مجاميع العقار
        /// </summary>
        private async Task UpdatePropertyAggregatesAsync(Guid propertyId, CancellationToken cancellationToken)
        {
            using var scope = _serviceProvider.CreateScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<YemenBookingDbContext>();
            
            var property = await dbContext.Properties
                .Include(p => p.Units)
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == propertyId, cancellationToken);
            
            if (property != null)
            {
                var db = _redisManager.GetDatabase();
                var propertyKey = $"{PROPERTY_KEY_PREFIX}{propertyId}";
                
                // تحديث الأسعار
                decimal minPrice = 0;
                decimal maxPrice = 0;
                
                if (property.Units?.Any() == true)
                {
                    minPrice = property.Units.Min(u => u.BasePrice?.Amount ?? 0);
                    maxPrice = property.Units.Max(u => u.BasePrice?.Amount ?? 0);
                }
                
                // تحديث فهرس السعر
                if (minPrice > 0)
                {
                    await db.SortedSetAddAsync(PRICE_INDEX_KEY, propertyId.ToString(), (double)minPrice);
                }
            }
        }

        /// <summary>
        /// تحديث فهرس السعر
        /// </summary>
        private async Task UpdatePriceIndexAsync(Guid unitId, Guid propertyId, List<PricingRule> pricingRules, CancellationToken cancellationToken)
        {
            if (pricingRules?.Any() == true)
            {
                var minPrice = pricingRules.Min(r => r.PriceAmount);
                var db = _redisManager.GetDatabase();
                
                // تحديث فهرس السعر للعقار
                await db.SortedSetAddAsync(PRICE_INDEX_KEY, propertyId.ToString(), (double)minPrice);
            }
        }

        /// <summary>
        /// مسح جميع الفهارس
        /// </summary>
        private async Task ClearAllIndexesAsync(CancellationToken cancellationToken)
        {
            var server = _redisManager.GetServer();
            var db = _redisManager.GetDatabase();
            
            // الحصول على جميع المفاتيح
            var keys = server.Keys(pattern: "*").ToArray();
            
            if (keys.Length > 0)
            {
                await db.KeyDeleteAsync(keys);
            }
            
            _logger.LogInformation("Cleared {Count} keys from indexes", keys.Length);
        }

        #endregion

        #region Disposal

        public void Dispose()
        {
            if (_disposed) return;
            
            _disposed = true;
            _indexingLock?.Dispose();
        }

        #endregion
    }

    #region Index Data Models

    /// <summary>
    /// بيانات فهرسة العقار
    /// </summary>
    internal class PropertyIndexData
    {
        public Guid Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public string City { get; set; }
        public string Address { get; set; }
        public Guid PropertyTypeId { get; set; }
        public string PropertyTypeName { get; set; }
        public Guid OwnerId { get; set; }
        public bool IsActive { get; set; }
        public bool IsApproved { get; set; }
        public decimal AverageRating { get; set; }
        public int TotalReviews { get; set; }
        public decimal MinPrice { get; set; }
        public decimal MaxPrice { get; set; }
        public int TotalUnits { get; set; }
        public List<string> Amenities { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? UpdatedAt { get; set; }
    }

    /// <summary>
    /// بيانات فهرسة الوحدة
    /// </summary>
    internal class UnitIndexData
    {
        public Guid Id { get; set; }
        public Guid PropertyId { get; set; }
        public string Name { get; set; }
        public Guid UnitTypeId { get; set; }
        public string UnitTypeName { get; set; }
        public int MaxCapacity { get; set; }
        public int AdultsCapacity { get; set; }
        public int ChildrenCapacity { get; set; }
        public decimal BasePrice { get; set; }
        public string Currency { get; set; }
        public bool IsActive { get; set; }
    }

    #endregion
}
