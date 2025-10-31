using System;
using System.Globalization;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Memory;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Infrastructure.Services
{
    public class PriceCacheService : IPriceCacheService
    {
        private readonly IRedisConnectionManager _redisManager;
        private readonly ICurrencyExchangeRepository _currencyExchangeRepository;
        private readonly IMemoryCache _memoryCache;

        public PriceCacheService(
            IRedisConnectionManager redisManager,
            ICurrencyExchangeRepository currencyExchangeRepository,
            IMemoryCache memoryCache)
        {
            _redisManager = redisManager;
            _currencyExchangeRepository = currencyExchangeRepository;
            _memoryCache = memoryCache;
        }

        public async Task<decimal> GetUnitPricePerNightAsync(Guid unitId, DateTime checkIn, DateTime checkOut, int nights)
        {
            var db = _redisManager.GetDatabase();
            var key = $"tmp:price:{unitId}:{checkIn.Ticks}:{checkOut.Ticks}";
            var cached = await db.StringGetAsync(key);
            if (!cached.IsNullOrEmpty && decimal.TryParse(cached.ToString(), NumberStyles.Number, CultureInfo.InvariantCulture, out var dec))
            {
                return dec;
            }

            // NOTE: pricing calculation lives in a separate service; this cache service should not compute pricing.
            // We assume caller computes and sets if needed; however for compatibility we return cached value only.
            // To preserve previous behavior, we return 0 here; caller must compute when 0 and set back.
            return 0m;
        }

        public async Task<decimal?> GetExchangeRateAsync(string from, string to)
        {
            if (string.IsNullOrWhiteSpace(from) || string.IsNullOrWhiteSpace(to)) return null;
            var key = $"fx:{from.ToUpperInvariant()}:{to.ToUpperInvariant()}";
            if (_memoryCache.TryGetValue(key, out decimal cached)) return cached;
            var rateObj = await _currencyExchangeRepository.GetExchangeRateAsync(from, to);
            if (rateObj == null || rateObj.Rate <= 0) return null;
            _memoryCache.Set(key, rateObj.Rate, TimeSpan.FromHours(1));
            return rateObj.Rate;
        }
    }
}
