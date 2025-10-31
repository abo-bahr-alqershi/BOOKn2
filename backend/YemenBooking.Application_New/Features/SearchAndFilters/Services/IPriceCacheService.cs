using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.SearchAndFilters.Services
{
    public interface IPriceCacheService
    {
        Task<decimal> GetUnitPricePerNightAsync(Guid unitId, DateTime checkIn, DateTime checkOut, int nights);
        Task<decimal?> GetExchangeRateAsync(string from, string to);
    }
}
