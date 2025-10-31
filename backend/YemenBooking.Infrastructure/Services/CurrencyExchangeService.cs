using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// خدمة أسعار صرف العملات الخارجية
    /// Stub implementation of ICurrencyExchangeService
    /// </summary>
    public class CurrencyExchangeService : ICurrencyExchangeService
    {
        public Task<decimal?> GetExchangeRateAsync(string fromCurrency, string toCurrency, CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException("CurrencyExchangeService.GetExchangeRateAsync is not implemented yet.");
        }

        public Task<Dictionary<string, decimal>> GetAllExchangeRatesAsync(string baseCurrency, CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException("CurrencyExchangeService.GetAllExchangeRatesAsync is not implemented yet.");
        }

        public bool IsValidCurrencyCode(string currencyCode)
        {
            // Simple validation: currency code must be exactly 3 letters
            if (string.IsNullOrWhiteSpace(currencyCode) || currencyCode.Length != 3)
                return false;
            return true;
        }

        public Task<IEnumerable<string>> GetSupportedCurrenciesAsync()
        {
            throw new NotImplementedException("CurrencyExchangeService.GetSupportedCurrenciesAsync is not implemented yet.");
        }
    }
}