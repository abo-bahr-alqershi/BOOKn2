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
    /// تنفيذ مستودع مرافق أنواع الكيانات
    /// Property type amenity repository implementation
    /// </summary>
    public class PropertyTypeAmenityRepository : BaseRepository<PropertyTypeAmenity>, IPropertyTypeAmenityRepository
    {
        public PropertyTypeAmenityRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<PropertyTypeAmenity> AssignAmenityToPropertyTypeAsync(PropertyTypeAmenity propertyTypeAmenity, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(propertyTypeAmenity, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return propertyTypeAmenity;
        }

        public async Task<bool> RemoveAmenityFromPropertyTypeAsync(Guid propertyTypeId, Guid amenityId, CancellationToken cancellationToken = default)
        {
            var ptA = await _dbSet.FirstOrDefaultAsync(a => a.PropertyTypeId == propertyTypeId && a.AmenityId == amenityId, cancellationToken);
            if (ptA == null) return false;
            _dbSet.Remove(ptA);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<PropertyTypeAmenity>> GetAmenitiesByPropertyTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(a => a.PropertyTypeId == propertyTypeId).ToListAsync(cancellationToken);

        public async Task<IEnumerable<PropertyTypeAmenity>> GetPropertyTypesByAmenityAsync(Guid amenityId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(a => a.AmenityId == amenityId).ToListAsync(cancellationToken);

        public async Task<bool> PropertyTypeHasAmenityAsync(Guid propertyTypeId, Guid amenityId, CancellationToken cancellationToken = default)
            => await _dbSet.AnyAsync(a => a.PropertyTypeId == propertyTypeId && a.AmenityId == amenityId, cancellationToken);
    }
} 