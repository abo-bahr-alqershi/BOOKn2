using System;
using System.Globalization;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Observability;
using YemenBooking.Infrastructure.Caching;

namespace YemenBooking.Infrastructure.Services
{
    public class PriceCacheService : IPriceCacheService
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly ICurrencyExchangeRepository _currencyExchangeRepository;
        private readonly IPricingService _pricingService;
        private readonly IMemoryCache _memoryCache;

        public PriceCacheService(
            IRedisConnectionManager redisManager,
            ICurrencyExchangeRepository currencyExchangeRepository,
            IMemoryCache memoryCache,
            IPricingService pricingService)
        {
            _redisManager = redisManager;
            _currencyExchangeRepository = currencyExchangeRepository;
            _memoryCache = memoryCache;
            _pricingService = pricingService;
        }

        public async Task<decimal> GetUnitPricePerNightAsync(Guid unitId, DateTime checkIn, DateTime checkOut, int nights)
        {
            var db = _redisManager.GetDatabase();
            var key = $"tmp:price:{unitId}:{checkIn.Ticks}:{checkOut.Ticks}";
            var cached = await db.StringGetAsync(key);
            if (!cached.IsNullOrEmpty && decimal.TryParse(cached.ToString(), NumberStyles.Number, CultureInfo.InvariantCulture, out var dec))
            {
                AppMetrics.RecordPriceHit(true);
                return dec;
            }

            // Compute total via pricing service and cache per-night value for 1 hour
            var total = await _pricingService.CalculatePriceAsync(unitId, checkIn, checkOut);
            var perNight = Math.Round(total / Math.Max(1, nights), 2);
            await db.StringSetAsync(key, perNight.ToString(CultureInfo.InvariantCulture), TTLPolicy.PriceCache);
            AppMetrics.RecordPriceHit(false);
            return perNight;
        }

        public async Task<decimal?> GetExchangeRateAsync(string from, string to)
        {
            if (string.IsNullOrWhiteSpace(from) || string.IsNullOrWhiteSpace(to)) return null;
            var key = $"fx:{from.ToUpperInvariant()}:{to.ToUpperInvariant()}";
            if (_memoryCache.TryGetValue(key, out decimal cached))
            {
                AppMetrics.RecordFxHit(true);
                return cached;
            }
            var rateObj = await _currencyExchangeRepository.GetExchangeRateAsync(from, to);
            if (rateObj == null || rateObj.Rate <= 0) return null;
            _memoryCache.Set(key, rateObj.Rate, TimeSpan.FromHours(1));
            AppMetrics.RecordFxHit(false);
            return rateObj.Rate;
        }
    }
}
