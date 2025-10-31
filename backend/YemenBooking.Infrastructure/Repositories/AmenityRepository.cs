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
    /// تنفيذ مستودع المرافق
    /// Amenity repository implementation
    /// </summary>
    public class AmenityRepository : BaseRepository<Amenity>, IAmenityRepository
    {
        public AmenityRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<Amenity> CreateAmenityAsync(Amenity amenity, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(amenity, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return amenity;
        }

        public async Task<Amenity?> GetAmenityByIdAsync(Guid amenityId, CancellationToken cancellationToken = default)
            => await _dbSet.FindAsync(new object[]{amenityId}, cancellationToken);

        public async Task<Amenity> UpdateAmenityAsync(Amenity amenity, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(amenity);
            await _context.SaveChangesAsync(cancellationToken);
            return amenity;
        }

        public async Task<bool> DeleteAmenityAsync(Guid amenityId, CancellationToken cancellationToken = default)
        {
            var amenity = await GetAmenityByIdAsync(amenityId, cancellationToken);
            if (amenity == null) return false;
            _dbSet.Remove(amenity);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<Amenity>> GetAllAmenitiesAsync(CancellationToken cancellationToken = default)
            => await _dbSet.ToListAsync(cancellationToken);

        public async Task<PropertyType?> GetPropertyTypeByIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await _context.Set<PropertyType>().FirstOrDefaultAsync(pt => pt.Id == propertyTypeId, cancellationToken);

        public async Task<PropertyTypeAmenity> AssignAmenityToPropertyTypeAsync(Guid propertyTypeId, Guid amenityId, bool isDefault = false, CancellationToken cancellationToken = default)
        {
            var entity = new PropertyTypeAmenity { PropertyTypeId = propertyTypeId, AmenityId = amenityId, IsDefault = isDefault };
            await _context.Set<PropertyTypeAmenity>().AddAsync(entity, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return entity;
        }

        public async Task<IEnumerable<PropertyTypeAmenity>> GetAmenitiesByPropertyTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await _context.Set<PropertyTypeAmenity>().Where(a => a.PropertyTypeId == propertyTypeId).ToListAsync(cancellationToken);

        public async Task<IEnumerable<PropertyAmenity>> GetAmenitiesByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<PropertyAmenity>()
                .Include(pa => pa.PropertyTypeAmenity).ThenInclude(pta => pta.Amenity)
                .Where(pa => pa.PropertyId == propertyId)
                .ToListAsync(cancellationToken);
        }

        // Retrieves all property-amenity assignments including navigation for filtering
        public async Task<IEnumerable<PropertyAmenity>> GetAllPropertyAmenitiesAsync(CancellationToken cancellationToken = default)
        {
            return await _context.Set<PropertyAmenity>()
                .Include(pa => pa.PropertyTypeAmenity).ThenInclude(pta => pta.Amenity)
                .ToListAsync(cancellationToken);
        }
    }
} 