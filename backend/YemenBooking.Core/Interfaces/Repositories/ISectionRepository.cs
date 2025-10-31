using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;

namespace YemenBooking.Core.Interfaces.Repositories;

public interface ISectionRepository : IRepository<Section>
{
	Task<Section> CreateAsync(Section section, CancellationToken cancellationToken = default);
	Task<Section> UpdateAsync(Section section, CancellationToken cancellationToken = default);
	Task<bool> DeleteAsync(Guid sectionId, CancellationToken cancellationToken = default);
    Task<(IEnumerable<Section> Items, int TotalCount)> GetPagedAsync(int pageNumber, int pageSize, SectionTarget? target, SectionType? type, CancellationToken cancellationToken = default);
    Task<(IEnumerable<Section> Items, int TotalCount)> GetPagedAsync(int pageNumber, int pageSize, SectionTarget? target, SectionType? type, string? cityName, CancellationToken cancellationToken = default);
	Task AssignPropertiesAsync(Guid sectionId, IEnumerable<Guid> propertyIds, CancellationToken cancellationToken = default);
	Task AssignUnitsAsync(Guid sectionId, IEnumerable<Guid> unitIds, CancellationToken cancellationToken = default);
	Task AddPropertiesAsync(Guid sectionId, IEnumerable<Guid> propertyIds, CancellationToken cancellationToken = default);
	Task AddUnitsAsync(Guid sectionId, IEnumerable<Guid> unitIds, CancellationToken cancellationToken = default);
    Task RemoveItemAsync(Guid sectionId, Guid itemId, CancellationToken cancellationToken = default);
    Task ReorderItemsAsync(Guid sectionId, IReadOnlyList<(Guid ItemId, int SortOrder)> orders, CancellationToken cancellationToken = default);

    // Rich content
    Task<IEnumerable<PropertyInSection>> GetPropertyItemsAsync(Guid sectionId, CancellationToken cancellationToken = default);
    Task<IEnumerable<UnitInSection>> GetUnitItemsAsync(Guid sectionId, CancellationToken cancellationToken = default);
    Task AssignPropertyItemsAsync(Guid sectionId, IEnumerable<PropertyInSection> items, CancellationToken cancellationToken = default);
    Task AssignUnitItemsAsync(Guid sectionId, IEnumerable<UnitInSection> items, CancellationToken cancellationToken = default);
}