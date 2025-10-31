// RedisIndexingService.cs
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using MessagePack;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Units.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Infrastructure.Indexing.Models;
using YemenBooking.Core.Indexing.Models;
using System.Diagnostics;
using System.Text;
using MessagePack.Resolvers;
using System.Globalization;
using Microsoft.Extensions.Caching.Memory;
using System.Collections.Concurrent;

namespace YemenBooking.Infrastructure.Services
{
    public class RedisIndexingService : IIndexingService
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUnitRepository _unitRepository;
        private readonly IAvailabilityService _availabilityService;
        private readonly IPricingService _pricingService;
        private readonly IUnitFieldValueRepository _unitFieldValueRepository;
        private readonly IUnitTypeFieldRepository _unitTypeFieldRepository;
        private readonly ICurrencyExchangeRepository _currencyExchangeRepository;
        private readonly ILogger<RedisIndexingService> _logger;
        private readonly SemaphoreSlim _writeLimiter = new(5, 5);
        private readonly SemaphoreSlim _searchLimiter = new(50, 50);
        private readonly IMemoryCache _memoryCache;
        private readonly IDatabase _db;

        // Redis Keys Prefixes
        private const string PROPERTY_KEY = "property:";
        private const string PROPERTY_SET = "properties:all";
        private const string CITY_SET = "city:";
        private const string TYPE_SET = "type:";
        private const string AMENITY_SET = "amenity:";
        private const string SERVICE_SET = "service:";
        private const string PRICE_SORTED_SET = "properties:by_price";
        private const string RATING_SORTED_SET = "properties:by_rating";
        private const string CREATED_SORTED_SET = "properties:by_created";
        private const string BOOKING_SORTED_SET = "properties:by_bookings";
        private const string GEO_KEY = "properties:geo";
        private const string AVAILABILITY_KEY = "availability:";
        private const string PRICING_KEY = "pricing:";
        private const string SEARCH_INDEX = "idx:properties";
        private const string DYNAMIC_FIELD_KEY = "dynamic:";
        private const string UNIT_KEY = "unit:";
        private const string PROPERTY_UNITS_SET = "property:units:";

        public RedisIndexingService(
            IRedisConnectionManager redisManager,
            IPropertyRepository propertyRepository,
            IUnitRepository unitRepository,
            IAvailabilityService availabilityService,
            IPricingService pricingService,
            ICurrencyExchangeRepository currencyExchangeRepository,
            IUnitFieldValueRepository unitFieldValueRepository,
            IUnitTypeFieldRepository unitTypeFieldRepository,
            ILogger<RedisIndexingService> logger,
            IMemoryCache memoryCache)
        {
            _redisManager = redisManager;
            _propertyRepository = propertyRepository;
            _unitRepository = unitRepository;
            _availabilityService = availabilityService;
            _pricingService = pricingService;
            _currencyExchangeRepository = currencyExchangeRepository;
            _unitFieldValueRepository = unitFieldValueRepository;
            _unitTypeFieldRepository = unitTypeFieldRepository;
            _logger = logger;
            _memoryCache = memoryCache;
            _db = _redisManager.GetDatabase();

            InitializeRedisIndexes();
        }

        private async Task<decimal> GetUnitPricePerNightCachedAsync(Guid unitId, DateTime checkIn, DateTime checkOut, int nights)
        {
            var key = $"tmp:price:{unitId}:{checkIn.Ticks}:{checkOut.Ticks}";
            var cached = await _db.StringGetAsync(key);
            if (!cached.IsNullOrEmpty && decimal.TryParse(cached.ToString(), NumberStyles.Number, CultureInfo.InvariantCulture, out var dec))
            {
                return dec;
            }

            var total = await _pricingService.CalculatePriceAsync(unitId, checkIn, checkOut);
            var perNight = Math.Round(total / Math.Max(1, nights), 2);
            await _db.StringSetAsync(key, perNight.ToString(CultureInfo.InvariantCulture), TimeSpan.FromHours(1));
            return perNight;
        }

        private async Task<decimal?> GetExchangeRateCachedAsync(string from, string to)
        {
            if (string.IsNullOrWhiteSpace(from) || string.IsNullOrWhiteSpace(to)) return null;
            var key = $"fx:{from.ToUpperInvariant()}:{to.ToUpperInvariant()}";
            if (_memoryCache.TryGetValue(key, out decimal cached)) return cached;
            var rateObj = await _currencyExchangeRepository.GetExchangeRateAsync(from, to);
            if (rateObj == null || rateObj.Rate <= 0) return null;
            _memoryCache.Set(key, rateObj.Rate, TimeSpan.FromHours(1));
            return rateObj.Rate;
        }

        private static string SanitizeForRediSearch(string input)
        {
            var s = input.Trim();
            var chars = new[] { '"', '\'', ';', '\\', '|', '(', ')', '[', ']', '{', '}', '@', ':' };
            foreach (var c in chars) s = s.Replace(c.ToString(), " ");
            return s;
        }

        #region Initialization

        private void InitializeRedisIndexes()
        {
            try
            {
                // إنشاء فهارس Redis Search إذا كانت متاحة
                CreateSearchIndexes();
                _logger.LogInformation("تم تهيئة فهارس Redis بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Redis Search غير متاح، سيتم استخدام الفهرسة اليدوية");
            }
        }

        private void CreateSearchIndexes()
        {
            // إنشاء فهرس RediSearch للبحث المتقدم (يتطلب RediSearch module)
            try
            {
                var cmdInfo = _db.Execute("COMMAND", "INFO", "FT.CREATE");
                if (cmdInfo.IsNull)
                {
                    _logger.LogDebug("CreateSearchIndexes: FT.CREATE command not available");
                    return;
                }

                // حذف الفهرس القديم إن وجد
                try
                {
                    _db.Execute("FT.DROPINDEX", "idx:properties");
                    _logger.LogInformation("تم حذف الفهرس القديم idx:properties");
                }
                catch
                {
                    // الفهرس غير موجود - لا مشكلة
                }

                // إنشاء الفهرس الجديد
                _db.Execute("FT.CREATE", "idx:properties", 
                    "ON", "HASH", 
                    "PREFIX", "1", "property:", 
                    "SCHEMA", 
                    "name", "TEXT", "WEIGHT", "5.0", "SORTABLE",
                    "name_lower", "TEXT",
                    "description", "TEXT", "WEIGHT", "2.0",
                    "city", "TAG", "SORTABLE",
                    "property_type", "TAG", "SORTABLE",
                    "min_price", "NUMERIC", "SORTABLE",
                    "max_price", "NUMERIC", "SORTABLE",
                    "average_rating", "NUMERIC", "SORTABLE",
                    "reviews_count", "NUMERIC", "SORTABLE",
                    "booking_count", "NUMERIC", "SORTABLE",
                    "max_capacity", "NUMERIC", "SORTABLE",
                    "is_active", "TAG",
                    "is_approved", "TAG",
                    "is_featured", "TAG",
                    "created_at", "NUMERIC", "SORTABLE",
                    "updated_at", "NUMERIC", "SORTABLE",
                    "latitude", "NUMERIC",
                    "longitude", "NUMERIC"
                );
                
                _logger.LogInformation("تم إنشاء فهرس RediSearch بنجاح: idx:properties");
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل إنشاء فهرس RediSearch - سيتم استخدام البحث اليدوي");
            }
        }

        #endregion

        #region Property CRUD Operations

        public async Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("OnPropertyCreatedAsync: بدء فهرسة العقار {PropertyId}", propertyId);
            try
            {
                _logger.LogInformation("OnPropertyCreatedAsync: بدء المعالجة للعقار {PropertyId}", propertyId);
                var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                if (property == null)
                {
                    _logger.LogWarning("OnPropertyCreatedAsync: العقار {PropertyId} غير موجود", propertyId);
                    return;
                }

                _logger.LogInformation("OnPropertyCreatedAsync: بدء بناء IndexModel للعقار {PropertyId}", propertyId);
                var indexModel = await BuildPropertyIndexModel(property, cancellationToken);
                _logger.LogInformation("OnPropertyCreatedAsync: تم بناء IndexModel للعقار {PropertyId}", propertyId);
                var key = $"{PROPERTY_KEY}{propertyId}";

                // تشغيل المعاملة
                var tran = _db.CreateTransaction();

                var unitsSetKey = $"{PROPERTY_UNITS_SET}{propertyId}";
                foreach (var uid in indexModel.UnitIds)
                {
                    _ = tran.SetAddAsync(unitsSetKey, uid);
                }

                // 1. حفظ بيانات العقار في Hash
                _ = tran.HashSetAsync(key, indexModel.ToHashEntries());

                // 2. إضافة للمجموعة الرئيسية
                _ = tran.SetAddAsync(PROPERTY_SET, propertyId.ToString());

                // 3. إضافة لمجموعة المدينة
                _ = tran.SetAddAsync($"{CITY_SET}{property.City}", propertyId.ToString());

                // 4. إضافة لمجموعة نوع العقار
                _ = tran.SetAddAsync($"{TYPE_SET}{indexModel.PropertyType}", propertyId.ToString());

                // 5. إضافة للفهارس المرتبة
                _ = tran.SortedSetAddAsync(PRICE_SORTED_SET, propertyId.ToString(), (double)indexModel.MinPrice);
                _ = tran.SortedSetAddAsync(RATING_SORTED_SET, propertyId.ToString(), (double)indexModel.AverageRating);
                _ = tran.SortedSetAddAsync(CREATED_SORTED_SET, propertyId.ToString(), indexModel.CreatedAt.Ticks);
                _ = tran.SortedSetAddAsync(BOOKING_SORTED_SET, propertyId.ToString(), indexModel.BookingCount);

                // 6. إضافة للموقع الجغرافي
                _ = tran.GeoAddAsync(GEO_KEY, new GeoEntry(
                    indexModel.Longitude,
                    indexModel.Latitude,
                    propertyId.ToString()));

                // 7. إضافة للمرافق
                foreach (var amenityId in indexModel.AmenityIds)
                {
                    _ = tran.SetAddAsync($"{AMENITY_SET}{amenityId}", propertyId.ToString());
                }

                // 8. إضافة للخدمات
                foreach (var serviceId in indexModel.ServiceIds)
                {
                    _ = tran.SetAddAsync($"{SERVICE_SET}{serviceId}", propertyId.ToString());
                }

                // 9. حفظ البيانات المسلسلة للبحث السريع
                var serialized = MessagePackSerializer.Serialize(indexModel);
                _ = tran.StringSetAsync($"{key}:bin", serialized);

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    // Ensure currency aligns with new min price
                    await RecalculatePropertyPricesAsync(propertyId);
                    _logger.LogInformation("تم إنشاء فهرس للعقار {PropertyId} في Redis", propertyId);

                    // نشر حدث للمشتركين
                    await PublishEventAsync("property:created", propertyId.ToString());
                }
                else
                {
                    _logger.LogError("فشل في إنشاء فهرس للعقار {PropertyId}", propertyId);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إنشاء فهرس للعقار {PropertyId}", propertyId);
                throw;
            }
        }

        public async Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                if (property == null)
                {
                    await OnPropertyDeletedAsync(propertyId, cancellationToken);
                    return;
                }

                var key = $"{PROPERTY_KEY}{propertyId}";

                // جلب البيانات القديمة للمقارنة
                var oldDataHash = await _db.HashGetAllAsync(key);
                PropertyIndexModel oldModel = null;

                if (oldDataHash.Length > 0)
                {
                    oldModel = PropertyIndexModel.FromHashEntries(oldDataHash);
                }

                var newModel = await BuildPropertyIndexModel(property, cancellationToken);
                var tran = _db.CreateTransaction();

                // تحديث البيانات الأساسية
                _ = tran.HashSetAsync(key, newModel.ToHashEntries());

                // تحديث المجموعات إذا تغيرت
                if (oldModel != null)
                {
                    // تحديث المدينة إذا تغيرت
                    if (oldModel.City != newModel.City)
                    {
                        _ = tran.SetRemoveAsync($"{CITY_SET}{oldModel.City}", propertyId.ToString());
                        _ = tran.SetAddAsync($"{CITY_SET}{newModel.City}", propertyId.ToString());
                    }

                    // تحديث النوع إذا تغير
                    if (oldModel.PropertyType != newModel.PropertyType)
                    {
                        _ = tran.SetRemoveAsync($"{TYPE_SET}{oldModel.PropertyType}", propertyId.ToString());
                        _ = tran.SetAddAsync($"{TYPE_SET}{newModel.PropertyType}", propertyId.ToString());
                    }

                    // تحديث المرافق
                    var removedAmenities = oldModel.AmenityIds.Except(newModel.AmenityIds);
                    var addedAmenities = newModel.AmenityIds.Except(oldModel.AmenityIds);

                    foreach (var amenityId in removedAmenities)
                    {
                        _ = tran.SetRemoveAsync($"{AMENITY_SET}{amenityId}", propertyId.ToString());
                    }

                    foreach (var amenityId in addedAmenities)
                    {
                        _ = tran.SetAddAsync($"{AMENITY_SET}{amenityId}", propertyId.ToString());
                    }

                    // تحديث الخدمات
                    var removedServices = oldModel.ServiceIds.Except(newModel.ServiceIds);
                    var addedServices = newModel.ServiceIds.Except(oldModel.ServiceIds);

                    foreach (var serviceId in removedServices)
                    {
                        _ = tran.SetRemoveAsync($"{SERVICE_SET}{serviceId}", propertyId.ToString());
                    }

                    foreach (var serviceId in addedServices)
                    {
                        _ = tran.SetAddAsync($"{SERVICE_SET}{serviceId}", propertyId.ToString());
                    }
                }

                // تحديث الفهارس المرتبة
                _ = tran.SortedSetAddAsync(PRICE_SORTED_SET, propertyId.ToString(),
                    (double)newModel.MinPrice, SortedSetWhen.Always);
                _ = tran.SortedSetAddAsync(RATING_SORTED_SET, propertyId.ToString(),
                    (double)newModel.AverageRating, SortedSetWhen.Always);
                _ = tran.SortedSetAddAsync(BOOKING_SORTED_SET, propertyId.ToString(),
                    newModel.BookingCount, SortedSetWhen.Always);

                // تحديث الموقع الجغرافي
                _ = tran.GeoAddAsync(GEO_KEY, new GeoEntry(
                    newModel.Longitude,
                    newModel.Latitude,
                    propertyId.ToString()));

                // تحديث البيانات المسلسلة
                var serialized = MessagePackSerializer.Serialize(newModel);
                _ = tran.StringSetAsync($"{key}:bin", serialized);

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    _logger.LogInformation("تم تحديث فهرس العقار {PropertyId}", propertyId);
                    await PublishEventAsync("property:updated", propertyId.ToString());
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث فهرس العقار {PropertyId}", propertyId);
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        public async Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                var key = $"{PROPERTY_KEY}{propertyId}";

                // جلب البيانات للحذف من المجموعات
                var dataHash = await _db.HashGetAllAsync(key);
                if (dataHash.Length > 0)
                {
                    var model = PropertyIndexModel.FromHashEntries(dataHash);
                    var tran = _db.CreateTransaction();

                    // حذف من المجموعات
                    _ = tran.SetRemoveAsync(PROPERTY_SET, propertyId.ToString());
                    _ = tran.SetRemoveAsync($"{CITY_SET}{model.City}", propertyId.ToString());
                    _ = tran.SetRemoveAsync($"{TYPE_SET}{model.PropertyType}", propertyId.ToString());

                    // حذف من المرافق
                    foreach (var amenityId in model.AmenityIds)
                    {
                        _ = tran.SetRemoveAsync($"{AMENITY_SET}{amenityId}", propertyId.ToString());
                    }

                    // حذف من الخدمات
                    foreach (var serviceId in model.ServiceIds)
                    {
                        _ = tran.SetRemoveAsync($"{SERVICE_SET}{serviceId}", propertyId.ToString());
                    }

                    // حذف من الفهارس المرتبة
                    _ = tran.SortedSetRemoveAsync(PRICE_SORTED_SET, propertyId.ToString());
                    _ = tran.SortedSetRemoveAsync(RATING_SORTED_SET, propertyId.ToString());
                    _ = tran.SortedSetRemoveAsync(CREATED_SORTED_SET, propertyId.ToString());
                    _ = tran.SortedSetRemoveAsync(BOOKING_SORTED_SET, propertyId.ToString());

                    // حذف من الموقع الجغرافي
                    _ = tran.GeoRemoveAsync(GEO_KEY, propertyId.ToString());

                    // حذف البيانات الأساسية
                    _ = tran.KeyDeleteAsync(key);
                    _ = tran.KeyDeleteAsync($"{key}:bin");

                    // حذف بيانات الوحدات (hash + availability + pricing) ثم حذف مجموعة الوحدات
                    var unitsKey = $"{PROPERTY_UNITS_SET}{propertyId}";
                    var unitIds = await _db.SetMembersAsync(unitsKey);
                    foreach (var uid in unitIds)
                    {
                        _ = tran.KeyDeleteAsync($"{UNIT_KEY}{uid}");
                        _ = tran.KeyDeleteAsync($"{AVAILABILITY_KEY}{uid}");
                        _ = tran.KeyDeleteAsync($"{PRICING_KEY}{uid}");
                    }
                    _ = tran.KeyDeleteAsync(unitsKey);

                    var result = await tran.ExecuteAsync();

                    if (result)
                    {
                        _logger.LogInformation("تم حذف فهرس العقار {PropertyId}", propertyId);
                        await PublishEventAsync("property:deleted", propertyId.ToString());
                    }
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في حذف فهرس العقار {PropertyId}", propertyId);
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        #endregion

        #region Unit Operations

        public async Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
                if (unit == null) return;

                var tran = _db.CreateTransaction();

                // إضافة للوحدات الخاصة بالعقار
                _ = tran.SetAddAsync($"{PROPERTY_UNITS_SET}{propertyId}", unitId.ToString());

                // حفظ بيانات الوحدة
                var unitKey = $"{UNIT_KEY}{unitId}";
                var unitData = new HashEntry[]
                {
                    new("id", unitId.ToString()),
                    new("property_id", propertyId.ToString()),
                    new("name", unit.Name),
                    new("max_capacity", unit.MaxCapacity),
                    new("base_price", unit.BasePrice.Amount.ToString()),
                    new("currency", unit.BasePrice.Currency)
                };
                _ = tran.HashSetAsync(unitKey, unitData);

                // تحديث بيانات العقار
                var propertyKey = $"{PROPERTY_KEY}{propertyId}";

                // تحديث عدد الوحدات
                _ = tran.HashIncrementAsync(propertyKey, "units_count", 1);

                // تحديث السعة القصوى إذا لزم
                var currentMaxCapacity = await _db.HashGetAsync(propertyKey, "max_capacity");
                if (currentMaxCapacity.IsNullOrEmpty || unit.MaxCapacity > (int)currentMaxCapacity)
                {
                    _ = tran.HashSetAsync(propertyKey, "max_capacity", unit.MaxCapacity);
                }

                // تحديث السعر الأدنى
                await UpdatePropertyMinPriceAsync(tran, propertyId, unit.BasePrice.Amount);

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    // Ensure property prices and currency cached fields are up-to-date
                    await RecalculatePropertyPricesAsync(propertyId);
                    _logger.LogInformation("تم إنشاء فهرس للوحدة {UnitId}", unitId);
                    await PublishEventAsync("unit:created", $"{propertyId}:{unitId}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إنشاء فهرس للوحدة {UnitId}", unitId);
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        public async Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
                if (unit == null) return;

                var tran = _db.CreateTransaction();

                // تحديث بيانات الوحدة
                var unitKey = $"{UNIT_KEY}{unitId}";
                var unitData = new HashEntry[]
                {
                    new("name", unit.Name),
                    new("max_capacity", unit.MaxCapacity),
                    new("base_price", unit.BasePrice.Amount.ToString()),
                    new("currency", unit.BasePrice.Currency),
                    new("updated_at", DateTime.UtcNow.Ticks)
                };
                _ = tran.HashSetAsync(unitKey, unitData);

                // إعادة حساب أسعار العقار
                await RecalculatePropertyPricesAsync(propertyId);

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    _logger.LogInformation("تم تحديث فهرس الوحدة {UnitId}", unitId);
                    await PublishEventAsync("unit:updated", $"{propertyId}:{unitId}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث فهرس الوحدة {UnitId}", unitId);
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        public async Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                var tran = _db.CreateTransaction();

                // حذف من مجموعة وحدات العقار
                _ = tran.SetRemoveAsync($"{PROPERTY_UNITS_SET}{propertyId}", unitId.ToString());

                // حذف بيانات الوحدة
                _ = tran.KeyDeleteAsync($"{UNIT_KEY}{unitId}");

                // حذف الإتاحة والتسعير
                _ = tran.KeyDeleteAsync($"{AVAILABILITY_KEY}{unitId}");
                _ = tran.KeyDeleteAsync($"{PRICING_KEY}{unitId}");

                // تحديث عدد الوحدات
                _ = tran.HashDecrementAsync($"{PROPERTY_KEY}{propertyId}", "units_count", 1);

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    // إعادة حساب السعة والأسعار
                    await RecalculatePropertyCapacityAsync(propertyId);
                    await RecalculatePropertyPricesAsync(propertyId);

                    _logger.LogInformation("تم حذف فهرس الوحدة {UnitId}", unitId);
                    await PublishEventAsync("unit:deleted", $"{propertyId}:{unitId}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في حذف فهرس الوحدة {UnitId}", unitId);
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        #endregion

        #region Availability & Pricing

        public async Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId,
            List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                var key = $"{AVAILABILITY_KEY}{unitId}";
                var tran = _db.CreateTransaction();

                // حذف البيانات القديمة
                _ = tran.KeyDeleteAsync(key);

                // إضافة النطاقات الجديدة
                foreach (var range in availableRanges)
                {
                    var rangeData = $"{range.Start.Ticks}:{range.End.Ticks}";
                    _ = tran.SortedSetAddAsync(key, rangeData, range.Start.Ticks);
                }

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    _logger.LogInformation("تم تحديث إتاحة الوحدة {UnitId}", unitId);
                    await PublishEventAsync("availability:changed", $"{propertyId}:{unitId}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث إتاحة الوحدة {UnitId}", unitId);
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        public async Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId,
            List<PricingRule> pricingRules, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                var key = $"{PRICING_KEY}{unitId}";
                var tran = _db.CreateTransaction();

                // حذف القواعد القديمة
                _ = tran.KeyDeleteAsync(key);

                // إضافة القواعد الجديدة
                foreach (var rule in pricingRules)
                {
                    var ruleData = MessagePackSerializer.Serialize(new
                    {
                        StartDate = rule.StartDate,
                        EndDate = rule.EndDate,
                        Price = rule.PriceAmount,
                        Type = rule.PriceType
                    });
                    _ = tran.HashSetAsync(key, $"{rule.StartDate.Ticks}:{rule.EndDate.Ticks}", ruleData);
                }

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    await RecalculatePropertyPricesAsync(propertyId);
                    _logger.LogInformation("تم تحديث تسعير الوحدة {UnitId}", unitId);
                    await PublishEventAsync("pricing:changed", $"{propertyId}:{unitId}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث تسعير الوحدة {UnitId}", unitId);
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        #endregion

        #region Dynamic Fields

        public async Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName,
            string fieldValue, bool isAdd, CancellationToken cancellationToken = default)
        {
            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                var propertyKey = $"{PROPERTY_KEY}{propertyId}";
                var dynamicKey = $"{DYNAMIC_FIELD_KEY}{fieldName}:{fieldValue}";
                var tran = _db.CreateTransaction();

                if (isAdd)
                {
                    // إضافة الحقل للعقار
                    _ = tran.HashSetAsync(propertyKey, $"df_{fieldName}", fieldValue);

                    // إضافة العقار لمجموعة الحقل الديناميكي
                    _ = tran.SetAddAsync(dynamicKey, propertyId.ToString());
                }
                else
                {
                    // حذف الحقل من العقار
                    _ = tran.HashDeleteAsync(propertyKey, $"df_{fieldName}");

                    // حذف العقار من مجموعة الحقل الديناميكي
                    _ = tran.SetRemoveAsync(dynamicKey, propertyId.ToString());
                }

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    _logger.LogInformation("تم تحديث الحقل الديناميكي {FieldName} للعقار {PropertyId}",
                        fieldName, propertyId);
                    await PublishEventAsync("dynamic:changed",
                        $"{propertyId}:{fieldName}:{fieldValue}:{isAdd}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث الحقل الديناميكي {FieldName} للعقار {PropertyId}",
                    fieldName, propertyId);
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        #endregion

        #region Helper Methods

        private async Task<PropertyIndexModel> BuildPropertyIndexModel(Property property,
            CancellationToken cancellationToken)
        {
            using var cts = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
            cts.CancelAfter(TimeSpan.FromSeconds(30));
            
            try
            {
                _logger.LogInformation("BuildPropertyIndexModel: بدء بناء نموذج للعقار {PropertyId}", property.Id);
                
                var units = await _unitRepository.GetByPropertyIdAsync(property.Id, cts.Token);
                var unitsList = units.ToList();
                
                _logger.LogInformation("BuildPropertyIndexModel: تم جلب {Count} وحدة للعقار {PropertyId}", 
                    unitsList.Count, property.Id);

                var typeName = property.PropertyType?.Name;
                if (string.IsNullOrWhiteSpace(typeName))
                {
                    var type = await _propertyRepository.GetPropertyTypeByIdAsync(property.TypeId, cts.Token);
                    typeName = type?.Name ?? string.Empty;
                }

                var amenityList = property.Amenities?.ToList();
                if (amenityList == null || amenityList.Count == 0)
                {
                    var amenities = await _propertyRepository.GetPropertyAmenitiesAsync(property.Id, cts.Token);
                    amenityList = amenities?.ToList() ?? new List<PropertyAmenity>();
                }

                var amenityIds = amenityList
                    .Where(a => a.IsAvailable)
                    .Select(a => a.PtaId.ToString())
                    .ToList();

                _logger.LogInformation("BuildPropertyIndexModel: اكتمل بناء النموذج للعقار {PropertyId}", property.Id);

                // Determine min/max using pricing rules (per-night today) instead of static base price
                var today = DateTime.UtcNow.Date;
                var tomorrow = today.AddDays(1);

                decimal minPrice = decimal.MaxValue;
                decimal maxPrice = decimal.MinValue;
                string? minCurrency = property.Currency;

                foreach (var u in unitsList)
                {
                    try
                    {
                        var total = await _pricingService.CalculatePriceAsync(u.Id, today, tomorrow);
                        var perNight = Math.Round(total, 2); // ليلة واحدة
                        if (perNight < minPrice)
                        {
                            minPrice = perNight;
                            minCurrency = u.BasePrice.Currency ?? property.Currency;
                        }
                        if (perNight > maxPrice)
                        {
                            maxPrice = perNight;
                        }
                    }
                    catch
                    {
                        // تجاهل الوحدة عند فشل التسعير
                    }
                }

                if (minPrice == decimal.MaxValue) minPrice = 0m;
                if (maxPrice == decimal.MinValue) maxPrice = 0m;

                return new PropertyIndexModel
                {
                    Id = property.Id.ToString(),
                    Name = property.Name,
                    NameLower = property.Name.ToLower(),
                    Description = property.Description ?? "",
                    City = property.City,
                    Address = property.Address,
                    PropertyType = typeName,
                    PropertyTypeId = property.TypeId,
                    OwnerId = property.OwnerId,
                    MinPrice = minPrice,
                    MaxPrice = maxPrice,
                    Currency = minCurrency ?? property.Currency,
                    StarRating = property.StarRating,
                    AverageRating = property.Reviews?.Any() == true ? (decimal)property.Reviews.Average(r => r.AverageRating) : 0,
                    ReviewsCount = property.Reviews?.Count ?? 0,
                    ViewCount = property.ViewCount,
                    BookingCount = property.BookingCount,
                    Latitude = (double)property.Latitude,
                    Longitude = (double)property.Longitude,
                    MaxCapacity = unitsList.Any() ? unitsList.Max(u => u.MaxCapacity) : 0,
                    UnitsCount = unitsList.Count,
                    IsActive = true,
                    IsFeatured = property.IsFeatured,
                    IsApproved = property.IsApproved,
                    UnitIds = unitsList.Select(u => u.Id.ToString()).ToList(),
                    AmenityIds = amenityIds,
                    ServiceIds = property.Services?.Select(s => s.Id.ToString()).ToList() ?? new List<string>(),
                    ImageUrls = property.Images?.OrderByDescending(i => i.IsMain)
                        .Select(i => i.Url).ToList() ?? new List<string>(),
                    DynamicFields = new Dictionary<string, string>(),
                    CreatedAt = property.CreatedAt,
                    UpdatedAt = DateTime.UtcNow,
                    LastModifiedTicks = DateTime.UtcNow.Ticks
                };
            }
            catch (OperationCanceledException)
            {
                _logger.LogError("BuildPropertyIndexModel: انتهت مهلة بناء IndexModel للعقار {PropertyId} (timeout 30s)", property.Id);
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "BuildPropertyIndexModel: خطأ في بناء IndexModel للعقار {PropertyId}", property.Id);
                throw;
            }
        }

        private async Task UpdatePropertyMinPriceAsync(ITransaction tran, Guid propertyId, decimal newPrice)
        {
            var propertyKey = $"{PROPERTY_KEY}{propertyId}";
            var currentMinPrice = await _db.HashGetAsync(propertyKey, "min_price");

            if (currentMinPrice.IsNullOrEmpty || newPrice < (decimal)currentMinPrice)
            {
                _ = tran.HashSetAsync(propertyKey, "min_price", newPrice.ToString());
                _ = tran.SortedSetAddAsync(PRICE_SORTED_SET, propertyId.ToString(),
                    (double)newPrice, SortedSetWhen.Always);
            }
        }

        private async Task RecalculatePropertyPricesAsync(Guid propertyId)
        {
            var units = await _unitRepository.GetByPropertyIdAsync(propertyId);

            if (units.Any())
            {
                var today = DateTime.UtcNow.Date;
                var tomorrow = today.AddDays(1);
                decimal minPrice = decimal.MaxValue;
                decimal maxPrice = decimal.MinValue;
                string? currency = null;

                foreach (var u in units)
                {
                    try
                    {
                        var total = await _pricingService.CalculatePriceAsync(u.Id, today, tomorrow);
                        var perNight = Math.Round(total, 2);
                        if (perNight < minPrice)
                        {
                            minPrice = perNight;
                            currency = u.BasePrice.Currency;
                        }
                        if (perNight > maxPrice)
                        {
                            maxPrice = perNight;
                        }
                    }
                    catch { }
                }

                if (minPrice == decimal.MaxValue) minPrice = 0m;
                if (maxPrice == decimal.MinValue) maxPrice = 0m;
                if (string.IsNullOrWhiteSpace(currency)) currency = units.First().BasePrice.Currency;

                var propertyKey = $"{PROPERTY_KEY}{propertyId}";

                await _db.HashSetAsync(propertyKey, new HashEntry[]
                {
                    new("min_price", minPrice.ToString()),
                    new("max_price", maxPrice.ToString()),
                    new("currency", currency)
                });

                await _db.SortedSetAddAsync(PRICE_SORTED_SET, propertyId.ToString(),
                    (double)minPrice, SortedSetWhen.Always);

                // Update serialized snapshot
                var index = await GetPropertyFromRedis(propertyId.ToString());
                if (index != null)
                {
                    index.MinPrice = minPrice;
                    index.MaxPrice = maxPrice;
                    index.Currency = currency;
                    var serialized = MessagePackSerializer.Serialize(index);
                    await _db.StringSetAsync($"{PROPERTY_KEY}{propertyId}:bin", serialized);
                }
            }
        }

        private async Task RecalculatePropertyCapacityAsync(Guid propertyId)
        {
            var units = await _unitRepository.GetByPropertyIdAsync(propertyId);

            if (units.Any())
            {
                var maxCapacity = units.Max(u => u.MaxCapacity);
                var propertyKey = $"{PROPERTY_KEY}{propertyId}";
                await _db.HashSetAsync(propertyKey, "max_capacity", maxCapacity);
            }
        }

        private async Task PublishEventAsync(string channel, string message)
        {
            try
            {
                var subscriber = _redisManager.GetSubscriber();
                await subscriber.PublishAsync(channel, message);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل في نشر الحدث {Channel}: {Message}", channel, message);
            }
        }

        /// <summary>
        /// تنفيذ البحث المطلوب في Interface
        /// </summary>
        public async Task<PropertySearchResult> SearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken = default)
        {
            try
            {
                // التحقق من الكاش أولاً
                var cacheKey = $"search:{GenerateSearchCacheKey(request)}";
                var cachedResult = await GetCachedSearchResult(cacheKey);
                if (cachedResult != null)
                {
                    _logger.LogDebug("إرجاع نتائج البحث من الكاش");
                    return cachedResult;
                }

                // البحث الفعلي
                var result = await PerformSearchAsync(request, cancellationToken);

                // حفظ النتائج في الكاش
                await CacheSearchResult(cacheKey, result, TimeSpan.FromMinutes(10));

                return result;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في البحث");
                throw;
            }
        }

        private async Task<PropertySearchResult> PerformSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            var stopwatch = Stopwatch.StartNew();

            try
            {
                // محاولة استخدام RediSearch إن وجد
                if (await IsRediSearchAvailable())
                {
                    return await SearchWithRediSearchAsync(request, cancellationToken);
                }

                // البحث اليدوي باستخدام Redis structures
                return await ManualRedisSearchAsync(request, cancellationToken);
            }
            finally
            {
                _logger.LogInformation("وقت البحث: {ElapsedMs}ms", stopwatch.ElapsedMilliseconds);
            }
        }

        private async Task<PropertySearchResult> ManualRedisSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            // 1. البدء بجميع العقارات المعتمدة
            var propertyIds = await GetFilteredPropertyIds(request);

            // 2. جلب التفاصيل
            var bag = new ConcurrentBag<PropertyIndexModel>();
            var tasks = propertyIds.Select(async id =>
            {
                await _searchLimiter.WaitAsync(cancellationToken);
                try
                {
                    var data = await GetPropertyFromRedis(id);
                    if (data != null) bag.Add(data);
                }
                finally
                {
                    _searchLimiter.Release();
                }
            });

            await Task.WhenAll(tasks);
            var properties = bag.ToList();

            // 3. تطبيق الفلاتر المتقدمة
            properties = await ApplyAdvancedFilters(properties, request);

            // 4. الترتيب
            properties = await ApplySortingAsync(properties, request);

            // 5. التصفح
            var totalCount = properties.Count;
            var pagedProperties = properties
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToList();

            return BuildSearchResult(pagedProperties, totalCount, request);
        }

        private async Task<HashSet<string>> GetFilteredPropertyIds(PropertySearchRequest request)
        {
            var sets = new List<string>();
            var shouldIntersect = new List<string>();

            // العقارات المعتمدة
            sets.Add(PROPERTY_SET);

            // فلترة المدينة
            if (!string.IsNullOrWhiteSpace(request.City))
            {
                shouldIntersect.Add($"{CITY_SET}{request.City}");
            }

            // فلترة النوع
            if (!string.IsNullOrWhiteSpace(request.PropertyType))
            {
                shouldIntersect.Add($"{TYPE_SET}{request.PropertyType}");
            }

            // فلترة المرافق
            if (request.RequiredAmenityIds?.Any() == true)
            {
                foreach (var amenityId in request.RequiredAmenityIds)
                {
                    shouldIntersect.Add($"{AMENITY_SET}{amenityId}");
                }
            }

            // فلترة الخدمات
            if (request.ServiceIds?.Any() == true)
            {
                foreach (var serviceId in request.ServiceIds)
                {
                    shouldIntersect.Add($"{SERVICE_SET}{serviceId}");
                }
            }

            // تنفيذ التقاطع
            if (shouldIntersect.Any())
            {
                sets.AddRange(shouldIntersect);
                var resultKey = $"temp:search:{Guid.NewGuid()}";
                await _db.SetCombineAndStoreAsync(
                    SetOperation.Intersect,
                    resultKey,
                    sets.Select(s => (RedisKey)s).ToArray());

                var members = await _db.SetMembersAsync(resultKey);
                await _db.KeyDeleteAsync(resultKey); // تنظيف

                return members.Select(m => m.ToString()).ToHashSet();
            }

            var allMembers = await _db.SetMembersAsync(PROPERTY_SET);
            return allMembers.Select(m => m.ToString()).ToHashSet();
        }

        private async Task<List<PropertyIndexModel>> ApplyAdvancedFilters(
            List<PropertyIndexModel> properties,
            PropertySearchRequest request)
        {
            var filtered = properties.AsEnumerable();

            // فلترة النص
            if (!string.IsNullOrWhiteSpace(request.SearchText))
            {
                var searchLower = request.SearchText.ToLower();
                filtered = filtered.Where(p =>
                    p.NameLower.Contains(searchLower) ||
                    p.Description.ToLower().Contains(searchLower) ||
                    p.Address.ToLower().Contains(searchLower));
            }

            // فلترة السعر
            if (request.MinPrice.HasValue || request.MaxPrice.HasValue)
            {
                var preferred = string.IsNullOrWhiteSpace(request.PreferredCurrency)
                    ? "YER" : request.PreferredCurrency!.ToUpperInvariant();

                var hasUnitConstraintsLocal = !string.IsNullOrWhiteSpace(request.UnitTypeId)
                                              || request.GuestsCount.HasValue
                                              || (request.CheckIn.HasValue && request.CheckOut.HasValue);

                if (!hasUnitConstraintsLocal)
                {
                    // لا توجد قيود على المستوى الوحدة -> استخدم فلترة مستوى العقار (أسرع)
                    var currencies = filtered.Select(p => p.Currency)
                        .Where(c => !string.IsNullOrWhiteSpace(c))
                        .Distinct(StringComparer.OrdinalIgnoreCase)
                        .ToList();

                    var rangeMap = new Dictionary<string, (decimal min, decimal max)>(StringComparer.OrdinalIgnoreCase);
                    foreach (var cur in currencies)
                    {
                        try
                        {
                            decimal minC = decimal.MinValue;
                            decimal maxC = decimal.MaxValue;
                            var rate = await GetExchangeRateCachedAsync(preferred, cur);
                            if (rate.HasValue)
                            {
                                if (request.MinPrice.HasValue) minC = Math.Round(request.MinPrice.Value * rate.Value, 2);
                                if (request.MaxPrice.HasValue) maxC = Math.Round(request.MaxPrice.Value * rate.Value, 2);
                                rangeMap[cur] = (minC, maxC);
                            }
                            else
                            {
                                continue;
                            }
                        }
                        catch { }
                    }

                    filtered = filtered.Where(p =>
                    {
                        if (string.IsNullOrWhiteSpace(p.Currency)) return false;
                        if (!rangeMap.TryGetValue(p.Currency, out var rng)) return false;
                        return p.MinPrice >= rng.min && p.MinPrice <= rng.max;
                    });
                }
                else
                {
                    // قيود على مستوى الوحدة -> يجب التأكد من وجود وحدة تطابق النوع/السعة/الإتاحة والسعر ضمن المدى
                    var unitTypeFilter = !string.IsNullOrWhiteSpace(request.UnitTypeId) && Guid.TryParse(request.UnitTypeId, out var unitTypeIdGuid)
                        ? (Guid?)unitTypeIdGuid : null;
                    var guests = request.GuestsCount ?? 1;
                    var useAvailability = request.CheckIn.HasValue && request.CheckOut.HasValue;
                    var checkIn = request.CheckIn ?? DateTime.UtcNow.Date;
                    var checkOut = request.CheckOut ?? checkIn.AddDays(1);
                    var nights = Math.Max(1, (checkOut - checkIn).Days);

                    // كاش لتحويل حدود الأسعار لكل عملة
                    var rangeMap = new Dictionary<string, (decimal min, decimal max)>(StringComparer.OrdinalIgnoreCase);

                    var props = filtered.ToList();
                    var kept = new List<PropertyIndexModel>(props.Count);

                    foreach (var p in props)
                    {
                        var propId = Guid.Parse(p.Id);
                        var units = await _unitRepository.GetByPropertyIdAsync(propId);
                        var unitsList = units
                            .Where(u => (!unitTypeFilter.HasValue || u.UnitTypeId == unitTypeFilter.Value)
                                     && (!request.GuestsCount.HasValue || u.MaxCapacity >= guests))
                            .ToList();

                        if (!unitsList.Any()) continue;

                        // تحقق الإتاحة إذا طُلبت
                        HashSet<Guid>? available = null;
                        if (useAvailability)
                        {
                            var avail = await _availabilityService.GetAvailableUnitsInPropertyAsync(propId, checkIn, checkOut, guests, CancellationToken.None);
                            available = avail != null ? avail.ToHashSet() : new HashSet<Guid>();
                            unitsList = unitsList.Where(u => available.Contains(u.Id)).ToList();
                            if (!unitsList.Any()) continue;
                        }

                        bool anyMatch = false;
                        foreach (var u in unitsList)
                        {
                            var cur = u.BasePrice.Currency;
                            if (string.IsNullOrWhiteSpace(cur)) continue;
                            if (!rangeMap.TryGetValue(cur, out var rng))
                            {
                                try
                                {
                                    decimal minC = decimal.MinValue;
                                    decimal maxC = decimal.MaxValue;
                                    var rate = await GetExchangeRateCachedAsync(preferred, cur);
                                    if (rate.HasValue)
                                    {
                                        if (request.MinPrice.HasValue) minC = Math.Round(request.MinPrice.Value * rate.Value, 2);
                                        if (request.MaxPrice.HasValue) maxC = Math.Round(request.MaxPrice.Value * rate.Value, 2);
                                        rng = (minC, maxC);
                                        rangeMap[cur] = rng;
                                    }
                                    else
                                    {
                                        continue;
                                    }
                                }
                                catch
                                {
                                    continue;
                                }
                            }

                            decimal priceToCheck;
                            if (useAvailability)
                            {
                                priceToCheck = await GetUnitPricePerNightCachedAsync(u.Id, checkIn, checkOut, nights);
                            }
                            else
                            {
                                priceToCheck = u.BasePrice.Amount;
                            }

                            if (priceToCheck >= rng.min && priceToCheck <= rng.max)
                            {
                                anyMatch = true;
                                break;
                            }
                        }

                        if (anyMatch) kept.Add(p);
                    }

                    filtered = kept;
                }
            }

            // فلترة التقييم
            if (request.MinRating.HasValue)
            {
                filtered = filtered.Where(p => p.AverageRating >= request.MinRating.Value);
            }

            // فلترة السعة
            if (request.GuestsCount.HasValue)
            {
                filtered = filtered.Where(p => p.MaxCapacity >= request.GuestsCount.Value);
            }

            // فلترة الإتاحة
            if (request.CheckIn.HasValue && request.CheckOut.HasValue)
            {
                var bagAvail = new System.Collections.Concurrent.ConcurrentBag<PropertyIndexModel>();
                var availTasks = filtered.Select(async p =>
                {
                    await _searchLimiter.WaitAsync(CancellationToken.None);
                    try
                    {
                        var isAvailable = await CheckPropertyAvailability(
                            p.Id, request.CheckIn.Value, request.CheckOut.Value);
                        if (isAvailable) bagAvail.Add(p);
                    }
                    finally
                    {
                        _searchLimiter.Release();
                    }
                });

                await Task.WhenAll(availTasks);
                filtered = bagAvail;
            }

            // فلترة الحقول الديناميكية
            if (request.DynamicFieldFilters?.Any() == true)
            {
                foreach (var filter in request.DynamicFieldFilters)
                {
                    filtered = filtered.Where(p =>
                        p.DynamicFields.ContainsKey(filter.Key) &&
                        p.DynamicFields[filter.Key] == filter.Value);
                }
            }

            // البحث الجغرافي
            if (request.Latitude.HasValue && request.Longitude.HasValue && request.RadiusKm.HasValue)
            {
                // استخدام Redis GEO
                var nearbyIds = await GetNearbyProperties(
                    request.Latitude.Value,
                    request.Longitude.Value,
                    request.RadiusKm.Value);

                filtered = filtered.Where(p => nearbyIds.Contains(p.Id));
            }

            return filtered.ToList();
        }

        private async Task<HashSet<string>> GetNearbyProperties(double lat, double lon, double radiusKm)
        {
            var results = await _db.GeoRadiusAsync(
                GEO_KEY,
                lon,
                lat,
                radiusKm,
                GeoUnit.Kilometers,
                options: GeoRadiusOptions.WithCoordinates);

            return results.Select(r => r.Member.ToString()).ToHashSet();
        }

        private async Task<bool> CheckPropertyAvailability(
            string propertyId,
            DateTime checkIn,
            DateTime checkOut)
        {
            // جلب وحدات العقار
            var unitIds = await _db.SetMembersAsync($"{PROPERTY_UNITS_SET}{propertyId}");

            // فحص إتاحة كل وحدة
            foreach (var unitId in unitIds)
            {
                var availabilityKey = $"{AVAILABILITY_KEY}{unitId}";
                var ranges = await _db.SortedSetRangeByScoreAsync(
                    availabilityKey,
                    0,
                    checkOut.Ticks);

                if (ranges == null || ranges.Length == 0)
                {
                    return true;
                }

                foreach (var range in ranges)
                {
                    var parts = range.ToString().Split(':');
                    if (parts.Length == 2)
                    {
                        var start = new DateTime(long.Parse(parts[0]));
                        var end = new DateTime(long.Parse(parts[1]));

                        if (start <= checkIn && end >= checkOut)
                        {
                            return true; // وجدنا وحدة متاحة
                        }
                    }
                }
            }

            return false;
        }

        #endregion

        #region Database Optimization - الدالة المفقودة الثانية

        /// <summary>
        /// تحسين وصيانة قاعدة بيانات Redis
        /// </summary>
        public async Task OptimizeDatabaseAsync()
        {
            await _writeLimiter.WaitAsync();
            try
            {
                _logger.LogInformation("بدء تحسين قاعدة بيانات Redis");

                var server = _redisManager.GetServer();
                var db = _redisManager.GetDatabase();

                // 1. تحليل استخدام الذاكرة
                await AnalyzeMemoryUsageAsync(server);

                // 2. تنظيف المفاتيح المنتهية
                await CleanupExpiredKeysAsync(db, server);

                // 3. تنظيف البيانات القديمة
                await CleanupOldDataAsync(db, server);

                // 4. إعادة بناء الفهارس التالفة
                await RebuildCorruptedIndexesAsync(db);

                // 5. تحسين الأداء
                await OptimizePerformanceAsync(server);

                // 6. إنشاء نقطة حفظ
                await CreateBackupPointAsync(server);

                _logger.LogInformation("اكتمل تحسين قاعدة بيانات Redis بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحسين قاعدة بيانات Redis");
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        private async Task AnalyzeMemoryUsageAsync(IServer server)
        {
            var info = await server.InfoAsync("memory");
            var memorySection = info.FirstOrDefault(s => s.Key == "Memory");

            if (memorySection.Any())
            {
                var stats = new Dictionary<string, string>();
                foreach (var item in memorySection)
                {
                    stats[item.Key] = item.Value;
                }

                var usedMemory = stats.GetValueOrDefault("used_memory_human", "N/A");
                var peakMemory = stats.GetValueOrDefault("used_memory_peak_human", "N/A");
                var fragmentation = stats.GetValueOrDefault("mem_fragmentation_ratio", "N/A");

                _logger.LogInformation(
                    "تحليل الذاكرة - المستخدم: {Used}, الذروة: {Peak}, التجزئة: {Frag}",
                    usedMemory, peakMemory, fragmentation);

                // تحذير إذا كانت نسبة التجزئة عالية
                if (double.TryParse(fragmentation, out var fragRatio) && fragRatio > 1.5)
                {
                    _logger.LogWarning("نسبة تجزئة الذاكرة عالية: {Ratio}", fragRatio);
                    await server.ExecuteAsync("MEMORY", "PURGE");
                }
            }
        }

        private async Task CleanupExpiredKeysAsync(IDatabase db, IServer server)
        {
            _logger.LogInformation("بدء تنظيف المفاتيح المنتهية");

            // فرض تنظيف المفاتيح المنتهية
            await server.ExecuteAsync("MEMORY", "DOCTOR");

            // تنظيف مفاتيح البحث المؤقتة
            var tempKeys = server.Keys(pattern: "temp:*");
            var keysToDelete = new List<RedisKey>();

            foreach (var key in tempKeys.Take(1000)) // معالجة دفعات
            {
                keysToDelete.Add(key);
            }

            if (keysToDelete.Any())
            {
                await db.KeyDeleteAsync(keysToDelete.ToArray());
                _logger.LogInformation("تم حذف {Count} مفتاح مؤقت", keysToDelete.Count);
            }
        }

        private async Task CleanupOldDataAsync(IDatabase db, IServer server)
        {
            var cutoffDate = DateTime.UtcNow.AddDays(-90);
            var deletedCount = 0;

            // تنظيف بيانات الإتاحة القديمة
            var availabilityKeys = server.Keys(pattern: $"{AVAILABILITY_KEY}*");

            foreach (var key in availabilityKeys.Take(500))
            {
                var ranges = await db.SortedSetRangeByScoreAsync(
                    key,
                    0,
                    cutoffDate.Ticks);

                if (ranges.Length > 0)
                {
                    await db.SortedSetRemoveRangeByScoreAsync(
                        key,
                        0,
                        cutoffDate.Ticks);
                    deletedCount += ranges.Length;
                }
            }

            // تنظيف بيانات التسعير القديمة
            var pricingKeys = server.Keys(pattern: $"{PRICING_KEY}*");

            foreach (var key in pricingKeys.Take(500))
            {
                var hash = await db.HashGetAllAsync(key);
                var toRemove = new List<RedisValue>();

                foreach (var entry in hash)
                {
                    var parts = entry.Name.ToString().Split(':');
                    if (parts.Length == 2)
                    {
                        var endDate = new DateTime(long.Parse(parts[1]));
                        if (endDate < cutoffDate)
                        {
                            toRemove.Add(entry.Name);
                        }
                    }
                }

                if (toRemove.Any())
                {
                    await db.HashDeleteAsync(key, toRemove.ToArray());
                    deletedCount += toRemove.Count;
                }
            }

            _logger.LogInformation("تم تنظيف {Count} عنصر قديم", deletedCount);
        }

        private async Task RebuildCorruptedIndexesAsync(IDatabase db)
        {
            _logger.LogInformation("فحص وإصلاح الفهارس");

            // فحص تناسق الفهارس
            var propertyCount = await db.SetLengthAsync(PROPERTY_SET);
            var priceIndexCount = await db.SortedSetLengthAsync(PRICE_SORTED_SET);
            var ratingIndexCount = await db.SortedSetLengthAsync(RATING_SORTED_SET);
            var geoIndexCount = await db.SortedSetLengthAsync(GEO_KEY);

            _logger.LogInformation(
                "إحصائيات الفهارس - العقارات: {Props}, السعر: {Price}, التقييم: {Rating}, الموقع: {Geo}",
                propertyCount, priceIndexCount, ratingIndexCount, geoIndexCount);

            // إصلاح عدم التطابق
            if (Math.Abs(propertyCount - priceIndexCount) > 10)
            {
                _logger.LogWarning("اكتشاف عدم تطابق في فهرس الأسعار، جاري الإصلاح...");
                await RebuildPriceIndexAsync(db);
            }

            if (Math.Abs(propertyCount - ratingIndexCount) > 10)
            {
                _logger.LogWarning("اكتشاف عدم تطابق في فهرس التقييم، جاري الإصلاح...");
                await RebuildRatingIndexAsync(db);
            }
        }

        private async Task RebuildPriceIndexAsync(IDatabase db)
        {
            var members = await db.SetMembersAsync(PROPERTY_SET);
            var tran = db.CreateTransaction();

            // مسح الفهرس القديم
            _ = tran.KeyDeleteAsync(PRICE_SORTED_SET);

            // إعادة بناء
            foreach (var propertyId in members)
            {
                var minPrice = await db.HashGetAsync($"{PROPERTY_KEY}{propertyId}", "min_price");
                if (!minPrice.IsNullOrEmpty)
                {
                    _ = tran.SortedSetAddAsync(
                        PRICE_SORTED_SET,
                        propertyId,
                        double.Parse(minPrice));
                }
            }

            await tran.ExecuteAsync();
            _logger.LogInformation("تم إعادة بناء فهرس الأسعار");
        }

        private async Task RebuildRatingIndexAsync(IDatabase db)
        {
            var members = await db.SetMembersAsync(PROPERTY_SET);
            var tran = db.CreateTransaction();

            // مسح الفهرس القديم
            _ = tran.KeyDeleteAsync(RATING_SORTED_SET);

            // إعادة بناء
            foreach (var propertyId in members)
            {
                var rating = await db.HashGetAsync($"{PROPERTY_KEY}{propertyId}", "average_rating");
                if (!rating.IsNullOrEmpty)
                {
                    _ = tran.SortedSetAddAsync(
                        RATING_SORTED_SET,
                        propertyId,
                        double.Parse(rating));
                }
            }

            await tran.ExecuteAsync();
            _logger.LogInformation("تم إعادة بناء فهرس التقييمات");
        }

        private async Task OptimizePerformanceAsync(IServer server)
        {
            _logger.LogInformation("تحسين أداء Redis");

            // 1. إعادة كتابة AOF في الخلفية
            try
            {
                await server.ExecuteAsync("BGREWRITEAOF");
                _logger.LogInformation("بدء إعادة كتابة AOF");
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "AOF غير مفعل أو جاري العمل عليه");
            }

            // 2. حفظ RDB في الخلفية
            try
            {
                await server.ExecuteAsync("BGSAVE");
                _logger.LogInformation("بدء حفظ RDB");
            }
            catch (Exception ex)
            {
                _logger.LogDebug(ex, "حفظ RDB جاري بالفعل");
            }

            // 3. تحسين استخدام الذاكرة
            await server.ExecuteAsync("MEMORY", "PURGE");

            // 4. جلب إحصائيات الأوامر البطيئة
            var slowLog = await server.SlowlogGetAsync(10);
            if (slowLog.Any())
            {
                _logger.LogWarning("تم اكتشاف {Count} أمر بطيء:", slowLog.Length);
                foreach (var entry in slowLog.Take(5))
                {
                    _logger.LogWarning(
                        "أمر بطيء: {Command} - الوقت: {Duration}μs",
                        string.Join(" ", entry.Arguments),
                        entry.Duration.TotalMicroseconds);
                }
            }
        }

        private async Task CreateBackupPointAsync(IServer server)
        {
            try
            {
                var lastSave = await server.LastSaveAsync();
                var timeSinceLastSave = DateTime.UtcNow - lastSave;

                if (timeSinceLastSave > TimeSpan.FromHours(1))
                {
                    await server.SaveAsync(SaveType.BackgroundSave);
                    _logger.LogInformation("تم إنشاء نقطة حفظ جديدة");
                }
                else
                {
                    _logger.LogDebug(
                        "آخر نقطة حفظ كانت قبل {Minutes} دقيقة",
                        timeSinceLastSave.TotalMinutes);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشل في إنشاء نقطة الحفظ");
            }
        }

        #endregion

        #region إعادة بناء الفهرس الكامل

        /// <summary>
        /// إعادة بناء الفهرس بالكامل من PostgreSQL
        /// </summary>
        public async Task RebuildIndexAsync(CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("بدء إعادة بناء فهرس Redis بالكامل");

            await _writeLimiter.WaitAsync(cancellationToken);
            try
            {
                // 1. مسح البيانات القديمة
                await ClearAllIndexesAsync();

                // 2. جلب جميع العقارات النشطة
                var properties = await _propertyRepository.GetActivePropertiesAsync(cancellationToken);
                var propertiesList = properties.ToList();
                var totalCount = propertiesList.Count;
                
                _logger.LogInformation("تم جلب {Count} عقار من قاعدة البيانات", totalCount);
                
                var processed = 0;
                var failed = 0;

                if (totalCount == 0)
                {
                    _logger.LogWarning("لا توجد عقارات معتمدة للفهرسة");
                    return;
                }

                // 3. معالجة على دفعات
                var batches = propertiesList.Chunk(50); // دفعات من 50 عقار

                _logger.LogInformation("بدء معالجة {Count} عقار على دفعات", totalCount);
                
                foreach (var batch in batches)
                {
                    cancellationToken.ThrowIfCancellationRequested();

                    _logger.LogDebug("معالجة دفعة من {Count} عقار", batch.Count());

                    foreach (var property in batch)
                    {
                        try
                        {
                            _logger.LogInformation("RebuildIndex: بدء فهرسة العقار {PropertyId} - {PropertyName}", property.Id, property.Name);
                            await IndexPropertyAsync(property.Id, cancellationToken);
                            processed++;
                            _logger.LogInformation("RebuildIndex: تمت فهرسة العقار {PropertyId} بنجاح", property.Id);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "RebuildIndex: فشل في فهرسة العقار {PropertyId}", property.Id);
                            failed++;
                        }
                    }

                    _logger.LogInformation(
                        "تقدم إعادة البناء: {Processed}/{Total} (فشل: {Failed})",
                        processed, totalCount, failed);
                }

                // 4. تحسين بعد إعادة البناء
                await OptimizeDatabaseAsync();

                _logger.LogInformation(
                    "اكتملت إعادة بناء الفهرس. تمت معالجة {Processed} عقار، فشل {Failed}",
                    processed, failed);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في إعادة بناء الفهرس");
                throw;
            }
            finally
            {
                _writeLimiter.Release();
            }
        }

        private async Task ClearAllIndexesAsync()
        {
            _logger.LogWarning("مسح جميع الفهارس الحالية");

            var server = _redisManager.GetServer();

            // يمكن استخدام FLUSHDB لمسح قاعدة البيانات بالكامل
            // أو مسح مفاتيح محددة فقط

            var patterns = new[]
            {
                $"{PROPERTY_KEY}*",
                $"{PROPERTY_SET}",
                $"{CITY_SET}*",
                $"{TYPE_SET}*",
                $"{AMENITY_SET}*",
                $"{SERVICE_SET}*",
                $"{PRICE_SORTED_SET}",
                $"{RATING_SORTED_SET}",
                $"{CREATED_SORTED_SET}",
                $"{BOOKING_SORTED_SET}",
                $"{GEO_KEY}",
                $"{AVAILABILITY_KEY}*",
                $"{PRICING_KEY}*",
                $"{DYNAMIC_FIELD_KEY}*",
                $"{UNIT_KEY}*",
                $"{PROPERTY_UNITS_SET}*"
            };

            foreach (var pattern in patterns)
            {
                var keys = server.Keys(pattern: pattern).ToArray();
                if (keys.Any())
                {
                    await _db.KeyDeleteAsync(keys);
                    _logger.LogDebug("تم حذف {Count} مفتاح من نمط {Pattern}", keys.Length, pattern);
                }
            }
        }

        private async Task IndexPropertyAsync(Guid propertyId, CancellationToken cancellationToken)
        {
            // استخدام الدالة الموجودة
            await OnPropertyCreatedAsync(propertyId, cancellationToken);
        }

        #endregion

        #region Helper Methods - إضافات للدوال المساعدة

        private string GenerateSearchCacheKey(PropertySearchRequest request)
        {
            var key = new StringBuilder();
            key.Append(request.SearchText ?? "");
            key.Append($"_{request.City ?? ""}");
            key.Append($"_{request.PropertyType ?? ""}");
            key.Append($"_{request.MinPrice?.ToString() ?? ""}");
            key.Append($"_{request.MaxPrice?.ToString() ?? ""}");
            key.Append($"_{request.MinRating?.ToString() ?? ""}");
            key.Append($"_{request.GuestsCount?.ToString() ?? ""}");
            key.Append($"_{request.CheckIn?.Ticks}");
            key.Append($"_{request.CheckOut?.Ticks}");
            key.Append($"_{request.PageNumber}_{request.PageSize}");
            key.Append($"_{request.SortBy ?? "default"}");

            // إضافة hash للحقول الديناميكية
            if (request.DynamicFieldFilters?.Any() == true)
            {
                var dynamicHash = string.Join(",",
                    request.DynamicFieldFilters.Select(f => $"{f.Key}:{f.Value}"));
                key.Append($"_{dynamicHash.GetHashCode()}");
            }

            // إضافة hash للمرافق
            if (request.RequiredAmenityIds?.Any() == true)
            {
                var amenityHash = string.Join(",", request.RequiredAmenityIds.OrderBy(a => a));
                key.Append($"_{amenityHash.GetHashCode()}");
            }

            return Convert.ToBase64String(
                System.Text.Encoding.UTF8.GetBytes(key.ToString()));
        }

        private async Task<PropertySearchResult> GetCachedSearchResult(string cacheKey)
        {
            var cached = await _db.StringGetAsync(cacheKey);
            if (!cached.IsNullOrEmpty)
            {
                var options = MessagePackSerializerOptions.Standard.WithResolver(ContractlessStandardResolver.Instance);
                return MessagePackSerializer.Deserialize<PropertySearchResult>(cached, options);
            }
            return null;
        }

        private async Task CacheSearchResult(
            string cacheKey,
            PropertySearchResult result,
            TimeSpan expiry)
        {
            var options = MessagePackSerializerOptions.Standard.WithResolver(ContractlessStandardResolver.Instance);
            var serialized = MessagePackSerializer.Serialize(result, options);
            await _db.StringSetAsync(cacheKey, serialized, expiry);
        }

        private async Task<PropertyIndexModel> GetPropertyFromRedis(string propertyId)
        {
            // محاولة جلب البيانات المسلسلة أولاً
            var serialized = await _db.StringGetAsync($"{PROPERTY_KEY}{propertyId}:bin");
            if (!serialized.IsNullOrEmpty)
            {
                return MessagePackSerializer.Deserialize<PropertyIndexModel>(serialized);
            }

            // جلب من Hash
            var hashData = await _db.HashGetAllAsync($"{PROPERTY_KEY}{propertyId}");
            if (hashData.Length > 0)
            {
                return PropertyIndexModel.FromHashEntries(hashData);
            }

            return null;
        }

        private async Task<List<PropertyIndexModel>> ApplySortingAsync(
            List<PropertyIndexModel> properties,
            PropertySearchRequest request)
        {
            var sort = request.SortBy?.ToLower();
            if (sort == "price_asc" || sort == "price_desc")
            {
                const string baseCurrency = "YER";
                var currencies = properties.Select(p => p.Currency)
                    .Where(c => !string.IsNullOrWhiteSpace(c) && !string.Equals(c, baseCurrency, StringComparison.OrdinalIgnoreCase))
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .ToList();

                var rateMap = new Dictionary<string, decimal>(StringComparer.OrdinalIgnoreCase)
                {
                    { baseCurrency, 1m }
                };

                foreach (var cur in currencies)
                {
                    var rate = await GetExchangeRateCachedAsync(cur, baseCurrency);
                    if (rate.HasValue && rate.Value > 0)
                        rateMap[cur] = rate.Value;
                }

                decimal Convert(decimal amount, string currency)
                {
                    if (string.IsNullOrWhiteSpace(currency) || currency.Equals(baseCurrency, StringComparison.OrdinalIgnoreCase))
                        return amount;
                    if (!rateMap.TryGetValue(currency, out var r) || r <= 0) return decimal.MaxValue;
                    return Math.Round(amount * r, 2);
                }

                return sort == "price_asc"
                    ? properties.OrderBy(p => Convert(p.MinPrice, p.Currency)).ToList()
                    : properties.OrderByDescending(p => Convert(p.MinPrice, p.Currency)).ToList();
            }

            if (sort == "rating")
            {
                return properties.OrderByDescending(p => p.AverageRating)
                    .ThenByDescending(p => p.ReviewsCount).ToList();
            }
            if (sort == "newest")
            {
                return properties.OrderByDescending(p => p.CreatedAt).ToList();
            }
            if (sort == "popularity")
            {
                return properties.OrderByDescending(p => p.BookingCount)
                    .ThenByDescending(p => p.ViewCount).ToList();
            }
            if (sort == "distance" && request.Latitude.HasValue && request.Longitude.HasValue)
            {
                return properties.OrderBy(p => CalculateDistance(
                        request.Latitude.Value,
                        request.Longitude.Value,
                        p.Latitude,
                        p.Longitude)).ToList();
            }

            return properties.OrderByDescending(p => p.AverageRating)
                .ThenByDescending(p => p.ReviewsCount).ToList();
        }

        private PropertySearchResult BuildSearchResult(
            List<PropertyIndexModel> properties,
            int totalCount,
            PropertySearchRequest request)
        {
            return new PropertySearchResult
            {
                Properties = properties.Select(p => new PropertySearchItem
                {
                    Id = p.Id,
                    Name = p.Name,
                    City = p.City,
                    PropertyType = p.PropertyType,
                    MinPrice = p.MinPrice,
                    Currency = p.Currency,
                    AverageRating = p.AverageRating,
                    StarRating = p.StarRating,
                    ImageUrls = p.ImageUrls,
                    MaxCapacity = p.MaxCapacity,
                    UnitsCount = p.UnitsCount,
                    DynamicFields = p.DynamicFields,
                    Latitude = p.Latitude,
                    Longitude = p.Longitude
                }).ToList(),
                TotalCount = totalCount,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = (int)Math.Ceiling((double)totalCount / request.PageSize)
            };
        }

        private async Task<bool> IsRediSearchAvailable()
        {
            try
            {
                var result = await _db.ExecuteAsync("COMMAND", "INFO", "FT.SEARCH");
                if (result.IsNull)
                {
                    _logger.LogDebug("IsRediSearchAvailable: RediSearch NOT available (IsNull)");
                    return false;
                }
                
                if (result.Type == ResultType.Array)
                {
                    var resultArray = (RedisResult[])result;
                    var available = resultArray != null && resultArray.Length > 0;
                    _logger.LogInformation("IsRediSearchAvailable: RediSearch available={Available}", available);
                    return available;
                }
                
                _logger.LogDebug("IsRediSearchAvailable: RediSearch NOT available (not array)");
                return false;
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "IsRediSearchAvailable: Exception checking RediSearch");
                return false;
            }
        }

        private async Task<PropertySearchResult> SearchWithRediSearchAsync(
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            // تنفيذ البحث باستخدام RediSearch
            // هذا يتطلب تثبيت RediSearch module على خادم Redis

            var query = await BuildRediSearchQueryAsync(request, cancellationToken);
            var offset = (request.PageNumber - 1) * request.PageSize;

            var args = new List<object> { SEARCH_INDEX, query };
            // إضافة الترتيب إذا طُلب
            var sortBy = request.SortBy?.ToLower();
            if (sortBy == "price_asc") { args.AddRange(new object[] { "SORTBY", "min_price", "ASC" }); }
            else if (sortBy == "price_desc") { args.AddRange(new object[] { "SORTBY", "min_price", "DESC" }); }
            else if (sortBy == "rating") { args.AddRange(new object[] { "SORTBY", "average_rating", "DESC" }); }
            else if (sortBy == "newest") { args.AddRange(new object[] { "SORTBY", "created_at", "DESC" }); }
            else if (sortBy == "popularity") { args.AddRange(new object[] { "SORTBY", "booking_count", "DESC" }); }

            // LIMIT
            args.AddRange(new object[] { "LIMIT", offset.ToString(), request.PageSize.ToString() });

            var result = await _db.ExecuteAsync("FT.SEARCH", args.ToArray());

            return await ParseRediSearchResultsAsync(result, request, cancellationToken);
        }

        private async Task<string> BuildRediSearchQueryAsync(PropertySearchRequest request, CancellationToken cancellationToken)
        {
            var queryParts = new List<string>();

            if (!string.IsNullOrWhiteSpace(request.SearchText))
            {
                var st = SanitizeForRediSearch(request.SearchText);
                queryParts.Add($"(@name:{st}* | @description:{st}*)");
            }

            if (!string.IsNullOrWhiteSpace(request.City))
            {
                var city = SanitizeForRediSearch(request.City);
                queryParts.Add($"@city:{{{city}}}");
            }

            if (!string.IsNullOrWhiteSpace(request.PropertyType))
            {
                var ptype = SanitizeForRediSearch(request.PropertyType);
                queryParts.Add($"@property_type:{{{ptype}}}");
            }

            // فلترة السعر في RediSearch باستخدام OR متعدد العملات (فقط عندما لا توجد قيود على مستوى الوحدة)
            var hasUnitConstraints = !string.IsNullOrWhiteSpace(request.UnitTypeId)
                                      || request.GuestsCount.HasValue
                                      || (request.CheckIn.HasValue && request.CheckOut.HasValue)
                                      || (request.DynamicFieldFilters?.Any() == true);
            if ((request.MinPrice.HasValue || request.MaxPrice.HasValue) && !hasUnitConstraints)
            {
                var preferred = string.IsNullOrWhiteSpace(request.PreferredCurrency)
                    ? "YER"
                    : request.PreferredCurrency!.ToUpperInvariant();

                var currencies = await _currencyExchangeRepository.GetSupportedCurrenciesAsync();
                var orBlocks = new List<string>();

                foreach (var cur in currencies.Distinct(StringComparer.OrdinalIgnoreCase))
                {
                    try
                    {
                        var minBound = "-inf";
                        var maxBound = "+inf";

                        if (request.MinPrice.HasValue)
                        {
                            var minConv = await _currencyExchangeRepository.ConvertAmountAsync(request.MinPrice.Value, preferred, cur);
                            minBound = Math.Round(minConv, 2).ToString(CultureInfo.InvariantCulture);
                        }
                        if (request.MaxPrice.HasValue)
                        {
                            var maxConv = await _currencyExchangeRepository.ConvertAmountAsync(request.MaxPrice.Value, preferred, cur);
                            maxBound = Math.Round(maxConv, 2).ToString(CultureInfo.InvariantCulture);
                        }

                        // قيد العملة + نطاق السعر لهذه العملة
                        var block = $"(@currency:{{{cur}}} @min_price:[{minBound} {maxBound}])";
                        orBlocks.Add(block);
                    }
                    catch
                    {
                        // إذا فشل تحويل عملة معينة، نتجاهلها
                    }
                }

                if (orBlocks.Count > 0)
                {
                    queryParts.Add($"({string.Join(" | ", orBlocks)})");
                }
            }

            queryParts.Add("@is_approved:{True}");

            return queryParts.Any() ? string.Join(" ", queryParts) : "*";
        }

        private string GetSortByClause(string? sortBy)
        {
            return sortBy?.ToLower() switch
            {
                // تجنب الفرز بالأسعار في RediSearch لأن القيم ليست موحّدة العملة
                "price_asc" => "",
                "price_desc" => "",
                "rating" => "SORTBY average_rating DESC",
                "newest" => "SORTBY created_at DESC",
                "popularity" => "SORTBY booking_count DESC",
                _ => ""
            };
        }

        private async Task<PropertySearchResult> ParseRediSearchResultsAsync(
            RedisResult result,
            PropertySearchRequest request,
            CancellationToken cancellationToken)
        {
            // FT.SEARCH returns: [total, key1, [field, value, ...], key2, [ ... ], ...]
            var totalCount = 0;
            var propertyIds = new List<string>();

            if (result.Type == ResultType.Array)
            {
                var arr = (RedisResult[])result;
                if (arr.Length > 0 && (arr[0].Type == ResultType.Integer || int.TryParse(arr[0].ToString(), out _)))
                {
                    totalCount = (arr[0].Type == ResultType.Integer)
                        ? (int)(long)arr[0]
                        : int.Parse(arr[0].ToString()!);

                    for (int i = 1; i < arr.Length; i++)
                    {
                        var key = arr[i].ToString();
                        if (string.IsNullOrWhiteSpace(key)) continue;
                        // Expect next element to be fields array; skip parsing fields and use our snapshot for consistency
                        if (key.StartsWith(PROPERTY_KEY, StringComparison.Ordinal))
                        {
                            var id = key.Substring(PROPERTY_KEY.Length);
                            propertyIds.Add(id);
                        }
                        // advance by 2 when next is fields array
                        if (i + 1 < arr.Length && arr[i + 1].Type == ResultType.Array) i++;
                    }
                }
            }

            // Fetch property snapshots with bounded parallelism
            var bag = new System.Collections.Concurrent.ConcurrentBag<PropertyIndexModel>();
            var tasks = propertyIds.Select(async pid =>
            {
                await _searchLimiter.WaitAsync(cancellationToken);
                try
                {
                    var model = await GetPropertyFromRedis(pid);
                    if (model != null) bag.Add(model);
                }
                finally
                {
                    _searchLimiter.Release();
                }
            });

            await Task.WhenAll(tasks);
            var properties = bag.ToList();

            return BuildSearchResult(properties, totalCount, request);
        }

        private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
        {
            const double R = 6371; // كيلومتر
            var dLat = ToRadians(lat2 - lat1);
            var dLon = ToRadians(lon2 - lon1);
            var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                    Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                    Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
            var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
            return R * c;
        }

        private double ToRadians(double degrees) => degrees * Math.PI / 180;
        
        #endregion
    }
}
