using System;
using System.Collections.Generic;
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
    /// تنفيذ مستودع مرافق الكيانات
    /// Property amenity repository implementation
    /// </summary>
    public class PropertyAmenityRepository : BaseRepository<PropertyAmenity>, IPropertyAmenityRepository
    {
        public PropertyAmenityRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<PropertyAmenity> UpdatePropertyAmenityAsync(PropertyAmenity propertyAmenity, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(propertyAmenity);
            await _context.SaveChangesAsync(cancellationToken);
            return propertyAmenity;
        }

        public async Task<PropertyAmenity> AddAmenityToPropertyAsync(PropertyAmenity propertyAmenity, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(propertyAmenity, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return propertyAmenity;
        }

        public async Task<bool> RemoveAmenityFromPropertyAsync(Guid propertyId, Guid ptaId, CancellationToken cancellationToken = default)
        {
            var pa = await _dbSet.FirstOrDefaultAsync(pa => pa.PropertyId == propertyId && pa.PtaId == ptaId, cancellationToken);
            if (pa == null) return false;
            _dbSet.Remove(pa);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<PropertyAmenity>> GetPropertyAmenitiesAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            return await _dbSet
                .Include(pa => pa.PropertyTypeAmenity)
                .ThenInclude(pta => pta.Amenity)
                .Where(pa => pa.PropertyId == propertyId)
                .ToListAsync(cancellationToken);
        }

        public async Task<IEnumerable<PropertyAmenity>> GetAmenitiesByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            return await _dbSet.Where(pa => pa.PropertyId == propertyId).ToListAsync(cancellationToken);
        }
    }
} 