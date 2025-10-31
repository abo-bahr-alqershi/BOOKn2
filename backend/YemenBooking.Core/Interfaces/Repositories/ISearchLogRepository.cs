using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories
{
    /// <summary>
    /// مستودع سجل عمليات البحث
    /// Repository for search logs
    /// </summary>
    public interface ISearchLogRepository
    {
        IQueryable<SearchLog> GetQueryable();
        Task AddAsync(SearchLog log, CancellationToken cancellationToken = default);
    }
} 