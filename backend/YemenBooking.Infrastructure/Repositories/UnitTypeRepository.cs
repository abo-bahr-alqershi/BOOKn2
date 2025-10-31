using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;
using System.Linq;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع أنواع الوحدات
    /// Unit type repository implementation
    /// </summary>
    public class UnitTypeRepository : BaseRepository<UnitType>, IUnitTypeRepository
    {
        public UnitTypeRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<UnitType> CreateUnitTypeAsync(UnitType unitType, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(unitType, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return unitType;
        }

        public async Task<UnitType?> GetUnitTypeByIdAsync(Guid unitTypeId, CancellationToken cancellationToken = default)
            => await _dbSet.FindAsync(new object[]{unitTypeId}, cancellationToken);

        public async Task<IEnumerable<UnitType>> GetByPropertyTypeIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await GetUnitTypesByPropertyTypeAsync(propertyTypeId, cancellationToken);

        public async Task<IEnumerable<UnitType>> GetUnitTypesByPropertyTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await _dbSet
                .Include(ut => ut.UnitTypeFields)
                .Where(ut => ut.PropertyTypeId == propertyTypeId)
                .ToListAsync(cancellationToken);

        public async Task<IEnumerable<UnitType>> GetAllUnitTypesAsync(CancellationToken cancellationToken = default)
            => await _dbSet.ToListAsync(cancellationToken);

        public async Task<UnitType> UpdateUnitTypeAsync(UnitType unitType, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(unitType);
            await _context.SaveChangesAsync(cancellationToken);
            return unitType;
        }

        public async Task<bool> DeleteUnitTypeAsync(Guid unitTypeId, CancellationToken cancellationToken = default)
        {
            var ut = await GetUnitTypeByIdAsync(unitTypeId, cancellationToken);
            if (ut == null) return false;
            _dbSet.Remove(ut);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<PropertyType?> GetPropertyTypeByIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await _context.Set<PropertyType>().FirstOrDefaultAsync(pt => pt.Id == propertyTypeId, cancellationToken);
    }
} 