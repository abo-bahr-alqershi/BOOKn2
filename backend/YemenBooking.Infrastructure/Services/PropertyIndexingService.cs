using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MessagePack;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Infrastructure.Indexing.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Pricing.Services;

namespace YemenBooking.Infrastructure.Services
{
    public class PropertyIndexingService : IPropertyIndexingService
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUnitRepository _unitRepository;
        private readonly IPricingService _pricingService;
        private readonly ILogger<PropertyIndexingService> _logger;
        private readonly IDatabase _db;

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
        private const string DYNAMIC_FIELD_KEY = "dynamic:";
        private const string UNIT_KEY = "unit:";
        private const string PROPERTY_UNITS_SET = "property:units:";

        public PropertyIndexingService(
            IRedisConnectionManager redisConnectionManager,
            IPropertyRepository propertyRepository,
            IUnitRepository unitRepository,
            IPricingService pricingService,
            ILogger<PropertyIndexingService> logger)
        {
            _redisManager = redisConnectionManager;
            _propertyRepository = propertyRepository;
            _unitRepository = unitRepository;
            _pricingService = pricingService;
            _logger = logger;
            _db = _redisManager.GetDatabase();
        }

        public async Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            _logger.LogInformation("OnPropertyCreatedAsync: بدء فهرسة العقار {PropertyId}", propertyId);
            try
            {
                var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                if (property == null)
                {
                    _logger.LogWarning("OnPropertyCreatedAsync: العقار {PropertyId} غير موجود", propertyId);
                    return;
                }

                var indexModel = await BuildPropertyIndexModel(property, cancellationToken);
                var key = $"{PROPERTY_KEY}{propertyId}";

                var tran = _db.CreateTransaction();

                var unitsSetKey = $"{PROPERTY_UNITS_SET}{propertyId}";
                foreach (var uid in indexModel.UnitIds)
                {
                    _ = tran.SetAddAsync(unitsSetKey, uid);
                }

                _ = tran.HashSetAsync(key, indexModel.ToHashEntries());
                _ = tran.SetAddAsync(PROPERTY_SET, propertyId.ToString());
                _ = tran.SetAddAsync($"{CITY_SET}{property.City}", propertyId.ToString());
                _ = tran.SetAddAsync($"{TYPE_SET}{indexModel.PropertyType}", propertyId.ToString());
                _ = tran.SortedSetAddAsync(PRICE_SORTED_SET, propertyId.ToString(), (double)indexModel.MinPrice);
                _ = tran.SortedSetAddAsync(RATING_SORTED_SET, propertyId.ToString(), (double)indexModel.AverageRating);
                _ = tran.SortedSetAddAsync(CREATED_SORTED_SET, propertyId.ToString(), indexModel.CreatedAt.Ticks);
                _ = tran.SortedSetAddAsync(BOOKING_SORTED_SET, propertyId.ToString(), indexModel.BookingCount);
                _ = tran.GeoAddAsync(GEO_KEY, new GeoEntry(indexModel.Longitude, indexModel.Latitude, propertyId.ToString()));

                foreach (var amenityId in indexModel.AmenityIds)
                {
                    _ = tran.SetAddAsync($"{AMENITY_SET}{amenityId}", propertyId.ToString());
                }

                foreach (var serviceId in indexModel.ServiceIds)
                {
                    _ = tran.SetAddAsync($"{SERVICE_SET}{serviceId}", propertyId.ToString());
                }

                var serialized = MessagePackSerializer.Serialize(indexModel);
                _ = tran.StringSetAsync($"{key}:bin", serialized);

                var result = await tran.ExecuteAsync();

                if (result)
                {
                    // Mark as indexed in DB
                    try
                    {
                        var persisted = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                        if (persisted != null && !persisted.IsIndexed)
                        {
                            persisted.IsIndexed = true;
                            await _propertyRepository.UpdatePropertyAsync(persisted, cancellationToken);
                        }
                    }
                    catch { }
                    _logger.LogInformation("تم إنشاء فهرس للعقار {PropertyId} في Redis", propertyId);
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
            try
            {
                var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                if (property == null)
                {
                    await OnPropertyDeletedAsync(propertyId, cancellationToken);
                    return;
                }

                var key = $"{PROPERTY_KEY}{propertyId}";
                var oldDataHash = await _db.HashGetAllAsync(key);
                PropertyIndexModel oldModel = null;
                if (oldDataHash.Length > 0)
                {
                    oldModel = PropertyIndexModel.FromHashEntries(oldDataHash);
                }

                var newModel = await BuildPropertyIndexModel(property, cancellationToken);
                var tran = _db.CreateTransaction();

                _ = tran.HashSetAsync(key, newModel.ToHashEntries());

                if (oldModel != null)
                {
                    if (oldModel.City != newModel.City)
                    {
                        _ = tran.SetRemoveAsync($"{CITY_SET}{oldModel.City}", propertyId.ToString());
                        _ = tran.SetAddAsync($"{CITY_SET}{newModel.City}", propertyId.ToString());
                    }

                    if (oldModel.PropertyType != newModel.PropertyType)
                    {
                        _ = tran.SetRemoveAsync($"{TYPE_SET}{oldModel.PropertyType}", propertyId.ToString());
                        _ = tran.SetAddAsync($"{TYPE_SET}{newModel.PropertyType}", propertyId.ToString());
                    }

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

                _ = tran.SortedSetAddAsync(PRICE_SORTED_SET, propertyId.ToString(), (double)newModel.MinPrice, SortedSetWhen.Always);
                _ = tran.SortedSetAddAsync(RATING_SORTED_SET, propertyId.ToString(), (double)newModel.AverageRating, SortedSetWhen.Always);
                _ = tran.SortedSetAddAsync(BOOKING_SORTED_SET, propertyId.ToString(), newModel.BookingCount, SortedSetWhen.Always);

                _ = tran.GeoAddAsync(GEO_KEY, new GeoEntry(newModel.Longitude, newModel.Latitude, propertyId.ToString()));

                var serialized = MessagePackSerializer.Serialize(newModel);
                _ = tran.StringSetAsync($"{key}:bin", serialized);

                var result = await tran.ExecuteAsync();
                if (result)
                {
                    // Mark as indexed in DB
                    try
                    {
                        var persisted = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                        if (persisted != null && !persisted.IsIndexed)
                        {
                            persisted.IsIndexed = true;
                            await _propertyRepository.UpdatePropertyAsync(persisted, cancellationToken);
                        }
                    }
                    catch { }
                    _logger.LogInformation("تم تحديث فهرس العقار {PropertyId}", propertyId);
                    await PublishEventAsync("property:updated", propertyId.ToString());
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث فهرس العقار {PropertyId}", propertyId);
                throw;
            }
        }

        public async Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            try
            {
                var key = $"{PROPERTY_KEY}{propertyId}";
                var dataHash = await _db.HashGetAllAsync(key);
                if (dataHash.Length > 0)
                {
                    var model = PropertyIndexModel.FromHashEntries(dataHash);
                    var tran = _db.CreateTransaction();

                    _ = tran.SetRemoveAsync(PROPERTY_SET, propertyId.ToString());
                    _ = tran.SetRemoveAsync($"{CITY_SET}{model.City}", propertyId.ToString());
                    _ = tran.SetRemoveAsync($"{TYPE_SET}{model.PropertyType}", propertyId.ToString());

                    foreach (var amenityId in model.AmenityIds)
                    {
                        _ = tran.SetRemoveAsync($"{AMENITY_SET}{amenityId}", propertyId.ToString());
                    }
                    foreach (var serviceId in model.ServiceIds)
                    {
                        _ = tran.SetRemoveAsync($"{SERVICE_SET}{serviceId}", propertyId.ToString());
                    }

                    _ = tran.SortedSetRemoveAsync(PRICE_SORTED_SET, propertyId.ToString());
                    _ = tran.SortedSetRemoveAsync(RATING_SORTED_SET, propertyId.ToString());
                    _ = tran.SortedSetRemoveAsync(CREATED_SORTED_SET, propertyId.ToString());
                    _ = tran.SortedSetRemoveAsync(BOOKING_SORTED_SET, propertyId.ToString());

                    _ = tran.GeoRemoveAsync(GEO_KEY, propertyId.ToString());

                    _ = tran.KeyDeleteAsync(key);
                    _ = tran.KeyDeleteAsync($"{key}:bin");

                    var unitsKey = $"{PROPERTY_UNITS_SET}{propertyId}";
                    var unitIds = await _db.SetMembersAsync(unitsKey);
                    foreach (var uid in unitIds)
                    {
                        _ = tran.KeyDeleteAsync($"{UNIT_KEY}{uid}");
                        _ = tran.KeyDeleteAsync($"availability:{uid}");
                        _ = tran.KeyDeleteAsync($"pricing:{uid}");
                    }
                    _ = tran.KeyDeleteAsync(unitsKey);

                    var result = await tran.ExecuteAsync();

                    if (result)
                    {
                        // Mark as not indexed in DB (if still exists)
                        try
                        {
                            var persisted = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                            if (persisted != null && persisted.IsIndexed)
                            {
                                persisted.IsIndexed = false;
                                await _propertyRepository.UpdatePropertyAsync(persisted, cancellationToken);
                            }
                        }
                        catch { }
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
        }

        public async Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName, string fieldValue, bool isAdd, CancellationToken cancellationToken = default)
        {
            try
            {
                var propertyKey = $"{PROPERTY_KEY}{propertyId}";
                var dynamicKey = $"{DYNAMIC_FIELD_KEY}{fieldName}:{fieldValue}";
                var tran = _db.CreateTransaction();

                if (isAdd)
                {
                    _ = tran.HashSetAsync(propertyKey, $"df_{fieldName}", fieldValue);
                    _ = tran.SetAddAsync(dynamicKey, propertyId.ToString());
                }
                else
                {
                    _ = tran.HashDeleteAsync(propertyKey, $"df_{fieldName}");
                    _ = tran.SetRemoveAsync(dynamicKey, propertyId.ToString());
                }

                var result = await tran.ExecuteAsync();
                if (result)
                {
                    _logger.LogInformation("تم تحديث الحقل الديناميكي {FieldName} للعقار {PropertyId}", fieldName, propertyId);
                    await PublishEventAsync("dynamic:changed", $"{propertyId}:{fieldName}:{fieldValue}:{isAdd}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث الحقل الديناميكي {FieldName} للعقار {PropertyId}", fieldName, propertyId);
                throw;
            }
        }

        private async Task<PropertyIndexModel> BuildPropertyIndexModel(Property property, CancellationToken cancellationToken)
        {
            try
            {
                var units = await _unitRepository.GetByPropertyIdAsync(property.Id, cancellationToken);
                var unitsList = units.ToList();

                var typeName = property.PropertyType?.Name;
                if (string.IsNullOrWhiteSpace(typeName))
                {
                    var type = await _propertyRepository.GetPropertyTypeByIdAsync(property.TypeId, cancellationToken);
                    typeName = type?.Name ?? string.Empty;
                }

                var amenityList = property.Amenities?.ToList();
                if (amenityList == null || amenityList.Count == 0)
                {
                    var amenities = await _propertyRepository.GetPropertyAmenitiesAsync(property.Id, cancellationToken);
                    amenityList = amenities?.ToList() ?? new List<PropertyAmenity>();
                }

                var amenityIds = amenityList.Where(a => a.IsAvailable).Select(a => a.PtaId.ToString()).ToList();

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
                        var perNight = Math.Round(total, 2);
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
                    catch { }
                }

                if (minPrice == decimal.MaxValue) minPrice = 0m;
                if (maxPrice == decimal.MinValue) maxPrice = 0m;

                return new PropertyIndexModel
                {
                    Id = property.Id.ToString(),
                    Name = property.Name,
                    NameLower = property.Name.ToLower(),
                    Description = property.Description ?? string.Empty,
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
                    ImageUrls = property.Images?.OrderByDescending(i => i.IsMain).Select(i => i.Url).ToList() ?? new List<string>(),
                    DynamicFields = new Dictionary<string, string>(),
                    CreatedAt = property.CreatedAt,
                    UpdatedAt = DateTime.UtcNow,
                    LastModifiedTicks = DateTime.UtcNow.Ticks
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "BuildPropertyIndexModel: خطأ في بناء IndexModel للعقار {PropertyId}", property.Id);
                throw;
            }
        }

        private async Task RecalculatePropertyPricesAsync(Guid propertyId)
        {
            var units = await _unitRepository.GetByPropertyIdAsync(propertyId);
            if (!units.Any()) return;

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
                new("min_price", minPrice.ToString(CultureInfo.InvariantCulture)),
                new("max_price", maxPrice.ToString(CultureInfo.InvariantCulture)),
                new("currency", currency)
            });
            await _db.SortedSetAddAsync(PRICE_SORTED_SET, propertyId.ToString(), (double)minPrice, SortedSetWhen.Always);

            var hash = await _db.HashGetAllAsync(propertyKey);
            if (hash.Length > 0)
            {
                var index = PropertyIndexModel.FromHashEntries(hash);
                index.MinPrice = minPrice;
                index.MaxPrice = maxPrice;
                index.Currency = currency;
                var serialized = MessagePackSerializer.Serialize(index);
                await _db.StringSetAsync($"{propertyKey}:bin", serialized);
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
    }
}
