using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة ضمان وجود العملة
    /// </summary>
    public class CurrencyEnsureService : ICurrencyEnsureService
    {
        private readonly YemenBookingDbContext _db;

        public CurrencyEnsureService(YemenBookingDbContext db)
        {
            _db = db;
        }

        public async Task EnsureCurrencyExistsAsync(string currencyCode, CancellationToken cancellationToken = default)
        {
            if (string.IsNullOrWhiteSpace(currencyCode)) return;
            var code = currencyCode.Trim().ToUpperInvariant();
            var exists = await _db.Currencies.AnyAsync(c => c.Code == code, cancellationToken);
            if (exists) return;

            // إنشاء عملة افتراضية ببيانات أولية بسيطة
            var currency = new Currency
            {
                Code = code,
                ArabicCode = code,
                Name = code,
                ArabicName = code,
                IsDefault = false,
                ExchangeRate = 1m,
                LastUpdated = DateTime.UtcNow
            };
            await _db.Currencies.AddAsync(currency, cancellationToken);
            await _db.SaveChangesAsync(cancellationToken);
        }
    }
}

