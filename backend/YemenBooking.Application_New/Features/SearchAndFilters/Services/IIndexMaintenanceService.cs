using System.Threading;
using System.Threading.Tasks;

namespace YemenBooking.Application.Features.SearchAndFilters.Services
{
    public interface IIndexMaintenanceService
    {
        Task OptimizeDatabaseAsync(CancellationToken cancellationToken = default);
        Task RebuildIndexAsync(CancellationToken cancellationToken = default);
    }
}
