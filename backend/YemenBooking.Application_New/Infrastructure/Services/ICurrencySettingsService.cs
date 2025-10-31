using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Infrastructure.Services
{
    /// <summary>
    /// Service for managing currency settings (read and save)
    /// </summary>
    public interface ICurrencySettingsService
    {
        /// <summary>
        /// Get the list of currencies
        /// </summary>
        Task<List<CurrencyDto>> GetCurrenciesAsync(CancellationToken cancellationToken = default);

        /// <summary>
        /// Save or update the list of currencies
        /// </summary>
        Task SaveCurrenciesAsync(List<CurrencyDto> currencies, CancellationToken cancellationToken = default);

        /// <summary>
        /// Delete a currency permanently after verifying there are no references.
        /// Throws InvalidOperationException with a descriptive message if deletion is not allowed.
        /// </summary>
        Task DeleteCurrencyAsync(string code, CancellationToken cancellationToken = default);
    }
} 