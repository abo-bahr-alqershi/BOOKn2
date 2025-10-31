using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع فلاتر البحث
/// SearchFilter repository interface
/// </summary>
public interface ISearchFilterRepository : IRepository<SearchFilter>
{
    Task<SearchFilter> CreateSearchFilterAsync(SearchFilter searchFilter, CancellationToken cancellationToken = default);

    Task<SearchFilter?> GetSearchFilterByIdAsync(Guid filterId, CancellationToken cancellationToken = default);

    Task<SearchFilter> UpdateSearchFilterAsync(SearchFilter searchFilter, CancellationToken cancellationToken = default);

    Task<bool> DeleteSearchFilterAsync(Guid filterId, CancellationToken cancellationToken = default);

    Task<IEnumerable<SearchFilter>> GetFiltersByFieldIdAsync(Guid fieldId, CancellationToken cancellationToken = default);
} 