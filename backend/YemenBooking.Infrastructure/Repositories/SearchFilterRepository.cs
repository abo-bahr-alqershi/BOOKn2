using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories;

/// <summary>
/// تنفيذ مستودع فلاتر البحث
/// SearchFilter repository implementation
/// </summary>
public class SearchFilterRepository : BaseRepository<SearchFilter>, ISearchFilterRepository
{
    public SearchFilterRepository(YemenBookingDbContext context) : base(context)
    {
    }

    public async Task<SearchFilter> CreateSearchFilterAsync(SearchFilter searchFilter, CancellationToken cancellationToken = default)
    {
        await _dbSet.AddAsync(searchFilter, cancellationToken);
        await _context.SaveChangesAsync(cancellationToken);
        return searchFilter;
    }

    public async Task<SearchFilter?> GetSearchFilterByIdAsync(Guid filterId, CancellationToken cancellationToken = default)
        => await _dbSet.FindAsync(new object[] { filterId }, cancellationToken);

    public async Task<SearchFilter> UpdateSearchFilterAsync(SearchFilter searchFilter, CancellationToken cancellationToken = default)
    {
        _dbSet.Update(searchFilter);
        await _context.SaveChangesAsync(cancellationToken);
        return searchFilter;
    }

    public async Task<bool> DeleteSearchFilterAsync(Guid filterId, CancellationToken cancellationToken = default)
    {
        var entity = await GetSearchFilterByIdAsync(filterId, cancellationToken);
        if (entity == null) return false;

        _dbSet.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<IEnumerable<SearchFilter>> GetFiltersByFieldIdAsync(Guid fieldId, CancellationToken cancellationToken = default)
        => await _dbSet.Where(sf => sf.FieldId == fieldId).ToListAsync(cancellationToken);
} 