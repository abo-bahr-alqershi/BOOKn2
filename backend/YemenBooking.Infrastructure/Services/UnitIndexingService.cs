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
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Infrastructure.Services
{
    public class UnitIndexingService : IUnitIndexingService
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly IUnitRepository _unitRepository;
        private readonly IPricingService _pricingService;
        private readonly ILogger<UnitIndexingService> _logger;
        private readonly IDatabase _db;

        private const string PROPERTY_KEY = "property:";
        private const string PROPERTY_UNITS_SET = "property:units:";
        private const string UNIT_KEY = "unit:";
        private const string AVAILABILITY_KEY = "availability:";
        private const string PRICING_KEY = "pricing:";
        private const string PRICE_SORTED_SET = "properties:by_price";

        public UnitIndexingService(
            IRedisConnectionManager redisConnectionManager,
            IUnitRepository unitRepository,
            IPricingService pricingService,
            ILogger<UnitIndexingService> logger)
        {
            _redisManager = redisConnectionManager;
            _unitRepository = unitRepository;
            _pricingService = pricingService;
            _logger = logger;
            _db = _redisManager.GetDatabase();
        }

        public async Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            try
            {
                var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
                if (unit == null) return;

                var tran = _db.CreateTransaction();
                _ = tran.SetAddAsync($"{PROPERTY_UNITS_SET}{propertyId}", unitId.ToString());

                var unitKey = $"{UNIT_KEY}{unitId}";
                var unitData = new HashEntry[]
                {
                    new("id", unitId.ToString()),
                    new("property_id", propertyId.ToString()),
                    new("name", unit.Name),
                    new("unit_type_id", unit.UnitTypeId.ToString()),
                    new("max_capacity", unit.MaxCapacity),
                    new("base_price", unit.BasePrice.Amount.ToString(CultureInfo.InvariantCulture)),
                    new("currency", unit.BasePrice.Currency)
                };
                _ = tran.HashSetAsync(unitKey, unitData);

                var propertyKey = $"{PROPERTY_KEY}{propertyId}";
                _ = tran.HashIncrementAsync(propertyKey, "units_count", 1);

                var currentMaxCapacity = await _db.HashGetAsync(propertyKey, "max_capacity");
                if (currentMaxCapacity.IsNullOrEmpty || unit.MaxCapacity > (int)currentMaxCapacity)
                {
                    _ = tran.HashSetAsync(propertyKey, "max_capacity", unit.MaxCapacity);
                }

                await UpdatePropertyMinPriceAsync(tran, propertyId, unit.BasePrice.Amount);

                var result = await tran.ExecuteAsync();
                if (result)
                {
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
        }

        public async Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            try
            {
                var unit = await _unitRepository.GetUnitByIdAsync(unitId, cancellationToken);
                if (unit == null) return;

                var tran = _db.CreateTransaction();
                var unitKey = $"{UNIT_KEY}{unitId}";
                var unitData = new HashEntry[]
                {
                    new("name", unit.Name),
                    new("unit_type_id", unit.UnitTypeId.ToString()),
                    new("max_capacity", unit.MaxCapacity),
                    new("base_price", unit.BasePrice.Amount.ToString(CultureInfo.InvariantCulture)),
                    new("currency", unit.BasePrice.Currency),
                    new("updated_at", DateTime.UtcNow.Ticks)
                };
                _ = tran.HashSetAsync(unitKey, unitData);

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
        }

        public async Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            try
            {
                var tran = _db.CreateTransaction();
                _ = tran.SetRemoveAsync($"{PROPERTY_UNITS_SET}{propertyId}", unitId.ToString());
                _ = tran.KeyDeleteAsync($"{UNIT_KEY}{unitId}");
                _ = tran.KeyDeleteAsync($"{AVAILABILITY_KEY}{unitId}");
                _ = tran.KeyDeleteAsync($"{PRICING_KEY}{unitId}");
                _ = tran.HashDecrementAsync($"{PROPERTY_KEY}{propertyId}", "units_count", 1);

                var result = await tran.ExecuteAsync();
                if (result)
                {
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
        }

        public async Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId, List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default)
        {
            try
            {
                var key = $"{AVAILABILITY_KEY}{unitId}";
                var batch = _db.CreateBatch();
                var tasks = new List<Task>();
                tasks.Add(batch.KeyDeleteAsync(key));
                foreach (var range in availableRanges)
                {
                    var rangeData = $"{range.Start.Ticks}:{range.End.Ticks}";
                    tasks.Add(batch.SortedSetAddAsync(key, rangeData, range.Start.Ticks));
                }
                batch.Execute();
                await Task.WhenAll(tasks);
                _logger.LogInformation("تم تحديث إتاحة الوحدة {UnitId}", unitId);
                await PublishEventAsync("availability:changed", $"{propertyId}:{unitId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث إتاحة الوحدة {UnitId}", unitId);
                throw;
            }
        }

        public async Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId, List<PricingRule> pricingRules, CancellationToken cancellationToken = default)
        {
            try
            {
                var key = $"{PRICING_KEY}{unitId}";
                var batch = _db.CreateBatch();
                var tasks = new List<Task>();
                tasks.Add(batch.KeyDeleteAsync(key));
                foreach (var rule in pricingRules)
                {
                    var ruleData = MessagePackSerializer.Serialize(new
                    {
                        StartDate = rule.StartDate,
                        EndDate = rule.EndDate,
                        Price = rule.PriceAmount,
                        Type = rule.PriceType
                    });
                    tasks.Add(batch.HashSetAsync(key, $"{rule.StartDate.Ticks}:{rule.EndDate.Ticks}", ruleData));
                }
                batch.Execute();
                await Task.WhenAll(tasks);
                await RecalculatePropertyPricesAsync(propertyId);
                _logger.LogInformation("تم تحديث تسعير الوحدة {UnitId}", unitId);
                await PublishEventAsync("pricing:changed", $"{propertyId}:{unitId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في تحديث تسعير الوحدة {UnitId}", unitId);
                throw;
            }
        }

        private async Task UpdatePropertyMinPriceAsync(ITransaction tran, Guid propertyId, decimal newPrice)
        {
            var propertyKey = $"{PROPERTY_KEY}{propertyId}";
            var currentMinPrice = await _db.HashGetAsync(propertyKey, "min_price");
            if (currentMinPrice.IsNullOrEmpty || newPrice < (decimal)currentMinPrice)
            {
                _ = tran.HashSetAsync(propertyKey, "min_price", newPrice.ToString(CultureInfo.InvariantCulture));
                _ = tran.SortedSetAddAsync(PRICE_SORTED_SET, propertyId.ToString(), (double)newPrice, SortedSetWhen.Always);
            }
        }

        private async Task RecalculatePropertyPricesAsync(Guid propertyId)
        {
            var units = await _unitRepository.GetByPropertyIdAsync(propertyId);
            if (!units.Any())
            {
                await _db.HashSetAsync($"{PROPERTY_KEY}{propertyId}", new HashEntry[]{ new("min_price", 0), new("max_price", 0) });
                return;
            }
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
        }

        private async Task RecalculatePropertyCapacityAsync(Guid propertyId)
        {
            var units = await _unitRepository.GetByPropertyIdAsync(propertyId);
            if (units.Any())
            {
                var maxCapacity = units.Max(u => u.MaxCapacity);
                await _db.HashSetAsync($"{PROPERTY_KEY}{propertyId}", "max_capacity", maxCapacity);
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
