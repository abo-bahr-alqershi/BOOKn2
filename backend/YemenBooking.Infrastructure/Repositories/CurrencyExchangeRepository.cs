using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    public class CurrencyExchangeRepository : BaseRepository<CurrencyExchangeRate>, ICurrencyExchangeRepository
    {
        public CurrencyExchangeRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<bool> AreRatesExpiredAsync(int maxAgeHours = 24)
        {
            var last = await GetLastUpdateDateAsync();
            if (last == null) return true;
            return (DateTime.UtcNow - last.Value).TotalHours > maxAgeHours;
        }

        public async Task<bool> BulkUpdateRatesAsync(List<CurrencyExchangeRate> rates)
        {
            if (rates == null || rates.Count == 0) return true;

            var all = await _context.Currencies.ToListAsync();
            var def = all.FirstOrDefault(c => c.IsDefault);
            if (def == null) throw new InvalidOperationException("No default currency found.");

            var map = all.ToDictionary(c => c.Code.ToUpperInvariant());
            var now = DateTime.UtcNow;

            foreach (var r in rates)
            {
                var from = r.FromCurrency.ToUpperInvariant();
                var to = r.ToCurrency.ToUpperInvariant();
                var rate = r.Rate;
                if (rate <= 0) continue;

                map.TryGetValue(from, out var fromC);
                map.TryGetValue(to, out var toC);

                if (toC != null && to.Equals(def.Code, StringComparison.OrdinalIgnoreCase))
                {
                    // from -> default
                    if (fromC == null) continue;
                    fromC.ExchangeRate = rate;
                    fromC.LastUpdated = now;
                }
                else if (fromC != null && from.Equals(def.Code, StringComparison.OrdinalIgnoreCase))
                {
                    // default -> to
                    if (toC == null) continue;
                    toC.ExchangeRate = 1m / rate;
                    toC.LastUpdated = now;
                }
                else if (fromC != null && fromC.ExchangeRate.HasValue)
                {
                    // derive to relative to default: exTo = exFrom / rate
                    if (toC == null) continue;
                    toC.ExchangeRate = fromC.ExchangeRate.Value / rate;
                    toC.LastUpdated = now;
                }
                else if (toC != null && toC.ExchangeRate.HasValue)
                {
                    // derive from relative to default: exFrom = rate * exTo
                    if (fromC == null) continue;
                    fromC.ExchangeRate = rate * toC.ExchangeRate.Value;
                    fromC.LastUpdated = now;
                }
                // else: insufficient info to set
            }

            await _context.SaveChangesAsync();
            return true;
        }

        public async Task<decimal> ConvertAmountAsync(decimal amount, string fromCurrency, string toCurrency)
        {
            if (string.Equals(fromCurrency, toCurrency, StringComparison.OrdinalIgnoreCase))
            {
                return amount;
            }
            var rate = await GetExchangeRateAsync(fromCurrency, toCurrency);
            if (rate == null || rate.Rate <= 0) throw new InvalidOperationException($"Exchange rate not found for {fromCurrency}->{toCurrency}");
            return amount * rate.Rate;
        }

        public async Task<List<CurrencyExchangeRate>> GetAllCurrentRatesAsync()
        {
            var all = await _context.Currencies.AsNoTracking().ToListAsync();
            if (all.Count == 0) return new List<CurrencyExchangeRate>();
            var def = all.FirstOrDefault(c => c.IsDefault) ?? all.First();
            var result = new List<CurrencyExchangeRate>();

            foreach (var c in all)
            {
                if (c.Code.Equals(def.Code, StringComparison.OrdinalIgnoreCase)) continue;
                if (!c.ExchangeRate.HasValue || c.ExchangeRate.Value <= 0) continue;

                // c -> default
                result.Add(new CurrencyExchangeRate
                {
                    Id = Guid.NewGuid(),
                    FromCurrency = c.Code,
                    ToCurrency = def.Code,
                    Rate = c.ExchangeRate.Value,
                    LastUpdated = c.LastUpdated ?? DateTime.UtcNow,
                    Source = "DB",
                    IsActive = true
                });

                // default -> c
                result.Add(new CurrencyExchangeRate
                {
                    Id = Guid.NewGuid(),
                    FromCurrency = def.Code,
                    ToCurrency = c.Code,
                    Rate = 1m / c.ExchangeRate.Value,
                    LastUpdated = c.LastUpdated ?? DateTime.UtcNow,
                    Source = "DB",
                    IsActive = true
                });
            }
            return result;
        }

        public async Task<CurrencyExchangeRate?> GetExchangeRateAsync(string fromCurrency, string toCurrency)
        {
            var from = fromCurrency.ToUpperInvariant();
            var to = toCurrency.ToUpperInvariant();
            if (from == to)
            {
                return new CurrencyExchangeRate
                {
                    Id = Guid.NewGuid(),
                    FromCurrency = from,
                    ToCurrency = to,
                    Rate = 1m,
                    LastUpdated = DateTime.UtcNow,
                    Source = "DB",
                    IsActive = true
                };
            }

            var currencies = await _context.Currencies.AsNoTracking()
                .Where(c => c.Code == from || c.Code == to)
                .ToListAsync();

            var fromC = currencies.FirstOrDefault(c => c.Code == from);
            var toC = currencies.FirstOrDefault(c => c.Code == to);
            if (fromC == null || toC == null) return null;

            var exFrom = fromC.IsDefault ? 1m : (fromC.ExchangeRate ?? 0m);
            var exTo = toC.IsDefault ? 1m : (toC.ExchangeRate ?? 0m);
            if (exFrom <= 0 || exTo <= 0) return null;

            var rate = exFrom / exTo;
            var last = new DateTime?[] { fromC.LastUpdated, toC.LastUpdated }
                .Where(d => d.HasValue).Max() ?? DateTime.UtcNow;

            return new CurrencyExchangeRate
            {
                Id = Guid.NewGuid(),
                FromCurrency = from,
                ToCurrency = to,
                Rate = Math.Round(rate, 6),
                LastUpdated = last,
                Source = "DB",
                IsActive = true
            };
        }

        public async Task<DateTime?> GetLastUpdateDateAsync()
        {
            return await _context.Currencies.MaxAsync(c => c.LastUpdated);
        }

        public async Task<List<CurrencyExchangeRate>> GetLatestRatesForCurrencyAsync(string baseCurrency)
        {
            var baseCode = baseCurrency.ToUpperInvariant();
            var all = await _context.Currencies.AsNoTracking().ToListAsync();
            var baseC = all.FirstOrDefault(c => c.Code.Equals(baseCode, StringComparison.OrdinalIgnoreCase));
            if (baseC == null) return new List<CurrencyExchangeRate>();

            decimal exBase = baseC.IsDefault ? 1m : (baseC.ExchangeRate ?? 0m);
            if (exBase <= 0) return new List<CurrencyExchangeRate>();

            var result = new List<CurrencyExchangeRate>();
            var now = DateTime.UtcNow;
            foreach (var c in all)
            {
                if (c.Code.Equals(baseCode, StringComparison.OrdinalIgnoreCase)) continue;
                var exTo = c.IsDefault ? 1m : (c.ExchangeRate ?? 0m);
                if (exTo <= 0) continue;
                var rate = exBase / exTo;
                result.Add(new CurrencyExchangeRate
                {
                    Id = Guid.NewGuid(),
                    FromCurrency = baseCode,
                    ToCurrency = c.Code,
                    Rate = Math.Round(rate, 6),
                    LastUpdated = c.LastUpdated ?? baseC.LastUpdated ?? now,
                    Source = "DB",
                    IsActive = true
                });
            }
            return result;
        }

        public async Task<List<string>> GetSupportedCurrenciesAsync()
        {
            return await _context.Currencies
                .AsNoTracking()
                .Select(c => c.Code)
                .Distinct()
                .ToListAsync();
        }

        public async Task<bool> UpdateExchangeRateAsync(string fromCurrency, string toCurrency, decimal rate)
        {
            if (rate <= 0) return false;

            var from = fromCurrency.ToUpperInvariant();
            var to = toCurrency.ToUpperInvariant();
            var all = await _context.Currencies.ToListAsync();
            var def = all.FirstOrDefault(c => c.IsDefault);
            if (def == null) throw new InvalidOperationException("No default currency found.");

            var fromC = all.FirstOrDefault(c => c.Code == from);
            var toC = all.FirstOrDefault(c => c.Code == to);
            if (fromC == null || toC == null) return false;

            var now = DateTime.UtcNow;

            if (to.Equals(def.Code, StringComparison.OrdinalIgnoreCase))
            {
                // from -> default
                fromC.ExchangeRate = rate;
                fromC.LastUpdated = now;
            }
            else if (from.Equals(def.Code, StringComparison.OrdinalIgnoreCase))
            {
                // default -> to
                toC.ExchangeRate = 1m / rate;
                toC.LastUpdated = now;
            }
            else if (fromC.ExchangeRate.HasValue)
            {
                // derive to: exTo = exFrom / rate
                toC.ExchangeRate = fromC.ExchangeRate.Value / rate;
                toC.LastUpdated = now;
            }
            else if (toC.ExchangeRate.HasValue)
            {
                // derive from: exFrom = rate * exTo
                fromC.ExchangeRate = rate * toC.ExchangeRate.Value;
                fromC.LastUpdated = now;
            }
            else
            {
                return false;
            }

            await _context.SaveChangesAsync();
            return true;
        }

        // Note: No hardcoded fallbacks; rates are derived from Currencies table relative to the default currency.

        // public async Task<CurrencyExchangeRate?> GetExchangeRateAsync(string fromCurrency, string toCurrency)
        //     => await _context.CurrencyExchangeRates
        //         .Where(r => r.FromCurrency == fromCurrency && r.ToCurrency == toCurrency && r.IsActive)
        //         .OrderByDescending(r => r.LastUpdated)
        //         .FirstOrDefaultAsync();

        // public async Task<List<CurrencyExchangeRate>> GetLatestRatesForCurrencyAsync(string baseCurrency)
        //     => await _context.CurrencyExchangeRates
        //         .Where(r => r.FromCurrency == baseCurrency && r.IsActive)
        //         .GroupBy(r => r.ToCurrency)
        //         .Select(g => g.OrderByDescending(r => r.LastUpdated).First())
        //         .ToListAsync();

        // public async Task<List<CurrencyExchangeRate>> GetAllCurrentRatesAsync()
        //     => await _context.CurrencyExchangeRates
        //         .Where(r => r.IsActive)
        //         .GroupBy(r => new { r.FromCurrency, r.ToCurrency })
        //         .Select(g => g.OrderByDescending(r => r.LastUpdated).First())
        //         .ToListAsync();

        // public async Task<bool> UpdateExchangeRateAsync(string fromCurrency, string toCurrency, decimal rate)
        // {
        //     var entity = await GetExchangeRateAsync(fromCurrency, toCurrency);
        //     if (entity != null)
        //     {
        //         entity.Rate = rate;
        //         entity.LastUpdated = DateTime.UtcNow;
        //         await _context.SaveChangesAsync();
        //         return true;
        //     }
        //     return false;
        // }

        // public async Task<bool> BulkUpdateRatesAsync(List<CurrencyExchangeRate> rates)
        // {
        //     foreach (var rateEntity in rates)
        //     {
        //         var existing = await _context.CurrencyExchangeRates
        //             .FirstOrDefaultAsync(r => r.FromCurrency == rateEntity.FromCurrency && r.ToCurrency == rateEntity.ToCurrency);
        //         if (existing != null)
        //         {
        //             existing.Rate = rateEntity.Rate;
        //             existing.LastUpdated = DateTime.UtcNow;
        //         }
        //         else
        //         {
        //             await _context.CurrencyExchangeRates.AddAsync(rateEntity);
        //         }
        //     }
        //     await _context.SaveChangesAsync();
        //     return true;
        // }

        // public async Task<DateTime?> GetLastUpdateDateAsync()
        //     => await _context.CurrencyExchangeRates
        //         .Where(r => r.IsActive)
        //         .MaxAsync(r => (DateTime?)r.LastUpdated);

        // public async Task<bool> AreRatesExpiredAsync(int maxAgeHours = 24)
        // {
        //     var last = await GetLastUpdateDateAsync();
        //     return last == null || (DateTime.UtcNow - last.Value).TotalHours > maxAgeHours;
        // }

        // public async Task<decimal> ConvertAmountAsync(decimal amount, string fromCurrency, string toCurrency)
        // {
        //     var rate = await GetExchangeRateAsync(fromCurrency, toCurrency);
        //     if (rate != null)
        //         return amount * rate.Rate;
        //     throw new InvalidOperationException($"Exchange rate not found for {fromCurrency}->{toCurrency}");
        // }

        // public async Task<List<string>> GetSupportedCurrenciesAsync()
        //     => await _context.CurrencyExchangeRates
        //         .Where(r => r.IsActive)
        //         .Select(r => r.FromCurrency)
        //         .Distinct()
        //         .ToListAsync();
    }
}
