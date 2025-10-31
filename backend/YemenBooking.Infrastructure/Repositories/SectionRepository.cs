using Microsoft.EntityFrameworkCore;
using System.Linq;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
	public class SectionRepository : BaseRepository<Section>, ISectionRepository
	{
		public SectionRepository(YemenBookingDbContext context) : base(context) { }

		public async Task<Section> CreateAsync(Section section, CancellationToken cancellationToken = default)
		{
			await _dbSet.AddAsync(section, cancellationToken);
			await _context.SaveChangesAsync(cancellationToken);
			return section;
		}

		public async Task<Section> UpdateAsync(Section section, CancellationToken cancellationToken = default)
		{
			_dbSet.Update(section);
			await _context.SaveChangesAsync(cancellationToken);
			return section;
		}

        public async Task<bool> DeleteAsync(Guid sectionId, CancellationToken cancellationToken = default)
        {
            var entity = await _dbSet
                .Include(s => s.PropertyItems)
                .Include(s => s.UnitItems)
                .FirstOrDefaultAsync(s => s.Id == sectionId, cancellationToken);
            if (entity == null) return false;
            _context.RemoveRange(entity.PropertyItems);
            _context.RemoveRange(entity.UnitItems);
            _dbSet.Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

		public async Task<(IEnumerable<Section> Items, int TotalCount)> GetPagedAsync(int pageNumber, int pageSize, SectionTarget? target, SectionType? type, CancellationToken cancellationToken = default)
		{
			return await GetPagedAsync(pageNumber, pageSize, target, type, null, cancellationToken);
		}

        public async Task<(IEnumerable<Section> Items, int TotalCount)> GetPagedAsync(int pageNumber, int pageSize, SectionTarget? target, SectionType? type, string? cityName, CancellationToken cancellationToken = default)
        {
            var query = _dbSet.AsQueryable();
            if (target.HasValue) query = query.Where(s => s.Target == target);
            if (type.HasValue) query = query.Where(s => s.Type == type);
            if (!string.IsNullOrWhiteSpace(cityName))
            {
                var cn = cityName!.Trim();
                query = query.Where(s => s.CityName != null && s.CityName == cn);
            }
            var total = await query.CountAsync(cancellationToken);
            var items = await query
                .OrderBy(s => s.DisplayOrder)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);
            return (items, total);
        }

        // Legacy GetItemsAsync removed along with SectionItem

		public async Task<IEnumerable<PropertyInSection>> GetPropertyItemsAsync(Guid sectionId, CancellationToken cancellationToken = default)
		{
			return await _context.PropertyInSections
				.Where(i => i.SectionId == sectionId)
				.OrderBy(i => i.DisplayOrder)
				.ToListAsync(cancellationToken);
		}

		public async Task<IEnumerable<UnitInSection>> GetUnitItemsAsync(Guid sectionId, CancellationToken cancellationToken = default)
		{
			return await _context.UnitInSections
				.Where(i => i.SectionId == sectionId)
				.OrderBy(i => i.DisplayOrder)
				.ToListAsync(cancellationToken);
		}

        public async Task AssignPropertiesAsync(Guid sectionId, IEnumerable<Guid> propertyIds, CancellationToken cancellationToken = default)
        {
            // No-op: use AssignPropertyItemsAsync with rich items instead
            // Clear existing rich items and add records built from ids with minimal fields
            var existing = await _context.PropertyInSections.Where(i => i.SectionId == sectionId).ToListAsync(cancellationToken);
            _context.PropertyInSections.RemoveRange(existing);
            var toAdd = propertyIds.Distinct().Select(pid => new PropertyInSection { SectionId = sectionId, PropertyId = pid }).ToList();
            await _context.PropertyInSections.AddRangeAsync(toAdd, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
        }

        public async Task AssignUnitsAsync(Guid sectionId, IEnumerable<Guid> unitIds, CancellationToken cancellationToken = default)
        {
            var existing = await _context.UnitInSections.Where(i => i.SectionId == sectionId).ToListAsync(cancellationToken);
            _context.UnitInSections.RemoveRange(existing);

            var distinctIds = unitIds.Distinct().ToList();
            if (distinctIds.Count == 0)
            {
                await _context.SaveChangesAsync(cancellationToken);
                return;
            }

            var units = await _context.Units
                .AsNoTracking()
                .Where(u => distinctIds.Contains(u.Id))
                .Include(u => u.Property)
                .Include(u => u.UnitType)
                .ToListAsync(cancellationToken);

            var items = new List<UnitInSection>(units.Count);
            foreach (var u in units)
            {
                var p = u.Property;
                var ut = u.UnitType;
                if (p == null || ut == null) continue;

                items.Add(new UnitInSection
                {
                    SectionId = sectionId,
                    UnitId = u.Id,
                    PropertyId = u.PropertyId,

                    UnitName = u.Name,
                    PropertyName = p.Name,
                    UnitTypeId = u.UnitTypeId,
                    UnitTypeName = ut.Name,
                    UnitTypeIcon = ut.Icon,

                    MaxCapacity = u.MaxCapacity,
                    BasePrice = u.BasePrice.Amount,
                    Currency = u.BasePrice.Currency,
                    PricingMethod = u.PricingMethod,
                    AdultsCapacity = u.AdultsCapacity,
                    ChildrenCapacity = u.ChildrenCapacity,

                    PropertyAddress = p.Address,
                    PropertyCity = p.City,
                    Latitude = p.Latitude,
                    Longitude = p.Longitude,
                    PropertyStarRating = p.StarRating,
                    PropertyAverageRating = p.AverageRating,

                    // Defaults handled by entity defaults
                });
            }

            if (items.Count > 0)
            {
                await _context.UnitInSections.AddRangeAsync(items, cancellationToken);
            }
            await _context.SaveChangesAsync(cancellationToken);
        }

		public async Task AssignPropertyItemsAsync(Guid sectionId, IEnumerable<PropertyInSection> items, CancellationToken cancellationToken = default)
		{
			var existing = await _context.PropertyInSections.Where(i => i.SectionId == sectionId).ToListAsync(cancellationToken);
			_context.PropertyInSections.RemoveRange(existing);
			foreach (var item in items)
			{
				item.SectionId = sectionId;
			}
			await _context.PropertyInSections.AddRangeAsync(items, cancellationToken);
			await _context.SaveChangesAsync(cancellationToken);
		}

		public async Task AssignUnitItemsAsync(Guid sectionId, IEnumerable<UnitInSection> items, CancellationToken cancellationToken = default)
		{
			var existing = await _context.UnitInSections.Where(i => i.SectionId == sectionId).ToListAsync(cancellationToken);
			_context.UnitInSections.RemoveRange(existing);
			foreach (var item in items)
			{
				item.SectionId = sectionId;
			}
			await _context.UnitInSections.AddRangeAsync(items, cancellationToken);
			await _context.SaveChangesAsync(cancellationToken);
		}

        public async Task AddPropertiesAsync(Guid sectionId, IEnumerable<Guid> propertyIds, CancellationToken cancellationToken = default)
        {
            var existingKeys = await _context.PropertyInSections.Where(i => i.SectionId == sectionId).Select(i => i.PropertyId).ToListAsync(cancellationToken);
            var toAdd = propertyIds.Distinct().Except(existingKeys).Select(pid => new PropertyInSection { SectionId = sectionId, PropertyId = pid }).ToList();
            if (toAdd.Count > 0)
            {
                await _context.PropertyInSections.AddRangeAsync(toAdd, cancellationToken);
                await _context.SaveChangesAsync(cancellationToken);
            }
        }

        public async Task AddUnitsAsync(Guid sectionId, IEnumerable<Guid> unitIds, CancellationToken cancellationToken = default)
        {
            var existingKeys = await _context.UnitInSections.Where(i => i.SectionId == sectionId).Select(i => i.UnitId).ToListAsync(cancellationToken);
            var newUnitIds = unitIds.Distinct().Except(existingKeys).ToList();

            if (newUnitIds.Count == 0)
                return;

            var units = await _context.Units
                .AsNoTracking()
                .Where(u => newUnitIds.Contains(u.Id))
                .Include(u => u.Property)
                .Include(u => u.UnitType)
                .ToListAsync(cancellationToken);

            var items = new List<UnitInSection>(units.Count);
            foreach (var u in units)
            {
                var p = u.Property;
                var ut = u.UnitType;
                if (p == null || ut == null) continue;

                items.Add(new UnitInSection
                {
                    SectionId = sectionId,
                    UnitId = u.Id,
                    PropertyId = u.PropertyId,

                    UnitName = u.Name,
                    PropertyName = p.Name,
                    UnitTypeId = u.UnitTypeId,
                    UnitTypeName = ut.Name,
                    UnitTypeIcon = ut.Icon,

                    MaxCapacity = u.MaxCapacity,
                    BasePrice = u.BasePrice.Amount,
                    Currency = u.BasePrice.Currency,
                    PricingMethod = u.PricingMethod,
                    AdultsCapacity = u.AdultsCapacity,
                    ChildrenCapacity = u.ChildrenCapacity,

                    PropertyAddress = p.Address,
                    PropertyCity = p.City,
                    Latitude = p.Latitude,
                    Longitude = p.Longitude,
                    PropertyStarRating = p.StarRating,
                    PropertyAverageRating = p.AverageRating,

                    // Defaults handled by entity defaults
                });
            }

            if (items.Count > 0)
            {
                await _context.UnitInSections.AddRangeAsync(items, cancellationToken);
                await _context.SaveChangesAsync(cancellationToken);
            }
        }

        public async Task RemoveItemAsync(Guid sectionId, Guid itemId, CancellationToken cancellationToken = default)
        {
            // Try remove from rich tables
            var propItem = await _context.PropertyInSections.FirstOrDefaultAsync(i => i.SectionId == sectionId && i.Id == itemId, cancellationToken);
            if (propItem != null)
            {
                _context.PropertyInSections.Remove(propItem);
                await _context.SaveChangesAsync(cancellationToken);
                return;
            }
            var unitItem = await _context.UnitInSections.FirstOrDefaultAsync(i => i.SectionId == sectionId && i.Id == itemId, cancellationToken);
            if (unitItem != null)
            {
                _context.UnitInSections.Remove(unitItem);
                await _context.SaveChangesAsync(cancellationToken);
            }
        }

        public async Task ReorderItemsAsync(Guid sectionId, IReadOnlyList<(Guid ItemId, int SortOrder)> orders, CancellationToken cancellationToken = default)
        {
            var itemIds = orders.Select(o => o.ItemId).ToList();
            var propItems = await _context.PropertyInSections.Where(i => i.SectionId == sectionId && itemIds.Contains(i.Id)).ToListAsync(cancellationToken);
            foreach (var item in propItems)
            {
                var ord = orders.First(o => o.ItemId == item.Id).SortOrder;
                item.DisplayOrder = ord;
            }

            var unitItems = await _context.UnitInSections.Where(i => i.SectionId == sectionId && itemIds.Contains(i.Id)).ToListAsync(cancellationToken);
            foreach (var item in unitItems)
            {
                var ord = orders.First(o => o.ItemId == item.Id).SortOrder;
                item.DisplayOrder = ord;
            }
            await _context.SaveChangesAsync(cancellationToken);
        }
	}
}