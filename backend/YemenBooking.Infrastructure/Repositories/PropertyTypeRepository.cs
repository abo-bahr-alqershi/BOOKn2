using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع أنواع الكيانات
    /// Property type repository implementation
    /// </summary>
    public class PropertyTypeRepository : BaseRepository<PropertyType>, IPropertyTypeRepository
    {
        public PropertyTypeRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<PropertyType> CreatePropertyTypeAsync(PropertyType propertyType, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(propertyType, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return propertyType;
        }

        public async Task<PropertyType?> GetPropertyTypeByIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await _dbSet.FindAsync(new object[]{propertyTypeId}, cancellationToken);

        public async Task<IEnumerable<PropertyType>> GetAllPropertyTypesAsync(CancellationToken cancellationToken = default)
            => await _dbSet.Include(pt => pt.UnitTypes).ToListAsync(cancellationToken);

        public async Task<PropertyType?> GetPropertyTypeWithAmenitiesAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await _dbSet.Include(pt => pt.PropertyTypeAmenities)
                .ThenInclude(pta => pta.Amenity)
                .FirstOrDefaultAsync(pt => pt.Id == propertyTypeId, cancellationToken);

        public async Task<PropertyType> UpdatePropertyTypeAsync(PropertyType propertyType, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(propertyType);
            await _context.SaveChangesAsync(cancellationToken);
            return propertyType;
        }

        public async Task<bool> DeletePropertyTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
        {
            var pt = await GetPropertyTypeByIdAsync(propertyTypeId, cancellationToken);
            if (pt == null) return false;
            _dbSet.Remove(pt);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
} 