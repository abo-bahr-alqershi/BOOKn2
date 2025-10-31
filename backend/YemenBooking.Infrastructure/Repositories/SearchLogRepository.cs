using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// مستودع سجل عمليات البحث
    /// Repository implementation for search logs
    /// </summary>
    public class SearchLogRepository : ISearchLogRepository
    {
        private readonly YemenBookingDbContext _context;

        public SearchLogRepository(YemenBookingDbContext context)
        {
            _context = context;
        }

        public IQueryable<SearchLog> GetQueryable()
        {
            return _context.SearchLogs.AsNoTracking();
        }

        public async Task AddAsync(SearchLog log, CancellationToken cancellationToken = default)
        {
            await _context.SearchLogs.AddAsync(log, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
        }
    }
} 