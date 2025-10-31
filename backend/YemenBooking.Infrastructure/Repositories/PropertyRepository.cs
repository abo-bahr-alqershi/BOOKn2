using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Core.Enums;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع الكيانات
    /// Property repository implementation
    /// </summary>
    public class PropertyRepository : BaseRepository<Property>, IPropertyRepository
    {
        public PropertyRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<Property> CreatePropertyAsync(Property property, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(property, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return property;
        }

        public async Task<Property?> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _dbSet
                .Include(p => p.PropertyType)
                .Include(p => p.Amenities)
                .Include(p => p.Services)
                .Include(p => p.Images)
                .Include(p => p.Reviews)
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.Id == propertyId, cancellationToken);

        public async Task<Property?> GetPropertyWithUnitsAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _dbSet
                .Include(p => p.Units)
                .FirstOrDefaultAsync(p => p.Id == propertyId, cancellationToken);

        public async Task<Property?> GetPropertyWithAmenitiesAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _dbSet
                .Include(p => p.Amenities)
                .FirstOrDefaultAsync(p => p.Id == propertyId, cancellationToken);

        public async Task<Property> UpdatePropertyAsync(Property property, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(property);
            await _context.SaveChangesAsync(cancellationToken);
            return property;
        }

        public async Task<bool> ApprovePropertyAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            var prop = await GetPropertyByIdAsync(propertyId, cancellationToken);
            if (prop == null) return false;
            prop.IsApproved = true;
            _dbSet.Update(prop);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> RejectPropertyAsync(Guid propertyId, string reason, CancellationToken cancellationToken = default)
        {
            var prop = await GetPropertyByIdAsync(propertyId, cancellationToken);
            if (prop == null) return false;
            prop.IsApproved = false;
            _dbSet.Update(prop);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> DeletePropertyAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            var prop = await GetPropertyByIdAsync(propertyId, cancellationToken);
            if (prop == null) return false;
            _dbSet.Remove(prop);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<Property>> GetPropertiesByOwnerAsync(Guid ownerId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(p => p.OwnerId == ownerId).ToListAsync(cancellationToken);

        public async Task<IEnumerable<Property>> GetPropertiesByTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(p => p.TypeId == propertyTypeId).ToListAsync(cancellationToken);

        public async Task<IEnumerable<Property>> GetPropertiesByCityAsync(string city, CancellationToken cancellationToken = default)
            => await _dbSet.Where(p => p.City == city).ToListAsync(cancellationToken);

        public async Task<IEnumerable<Property>> SearchPropertiesAsync(string searchTerm, CancellationToken cancellationToken = default)
            => await _dbSet.Where(p => p.Name.Contains(searchTerm) || p.Description.Contains(searchTerm)).ToListAsync(cancellationToken);

        public async Task<IEnumerable<Property>> GetPropertiesNearLocationAsync(double latitude, double longitude, double radiusKm, CancellationToken cancellationToken = default)
        {
            return await _dbSet
                .Where(p => (Math.Pow((double)p.Latitude - latitude, 2) + Math.Pow((double)p.Longitude - longitude, 2)) <= radiusKm * radiusKm)
                .ToListAsync(cancellationToken);
        }

        public async Task<bool> CheckActiveBookingsAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<Booking>()
                .AnyAsync(b => b.Unit.PropertyId == propertyId && b.Status == BookingStatus.Confirmed, cancellationToken);
        }
        /// <summary>
        /// الحصول على عدد الحجوزات للعقار
        /// Get total booking count for a property
        /// </summary>
        /// <param name="propertyId">معرف العقار</param>
        /// <param name="cancellationToken">رمز الإلغاء</param>
        /// <returns>عدد الحجوزات</returns>
        public async Task<int> GetPropertyBookingCountAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<Booking>()
                .CountAsync(b => b.Unit.PropertyId == propertyId, cancellationToken);
        }

        public async Task<int> GetUnitsCountAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _context.Set<Unit>().CountAsync(u => u.PropertyId == propertyId, cancellationToken);

        public async Task<int> GetServicesCountAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _context.Set<PropertyService>().CountAsync(s => s.PropertyId == propertyId, cancellationToken);

        public async Task<int> GetAmenitiesCountAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _context.Set<PropertyAmenity>().CountAsync(a => a.PropertyId == propertyId, cancellationToken);

        public async Task<int> GetPaymentsCountAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _context.Set<Payment>().CountAsync(p => p.Booking.Unit.PropertyId == propertyId, cancellationToken);

        public async Task<IEnumerable<PropertyAmenity>> GetPropertyAmenitiesAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => (await _context.Set<PropertyAmenity>().Where(a => a.PropertyId == propertyId).ToListAsync(cancellationToken));

        public async Task<bool> UpdatePropertyAmenityAsync(Guid propertyId, Guid amenityId, bool isAvailable, decimal? additionalCost = null, CancellationToken cancellationToken = default)
        {
            var amenity = await _context.Set<PropertyAmenity>().FirstOrDefaultAsync(a => a.PropertyId == propertyId && a.PtaId == amenityId, cancellationToken);
            if (amenity == null) return false;
            amenity.IsAvailable = isAvailable;
            if (additionalCost.HasValue)
                amenity.ExtraCost = Money.Yer(additionalCost.Value);
            _context.Set<PropertyAmenity>().Update(amenity);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<object> CalculatePerformanceMetricsAsync(Guid propertyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            var totalBookings = await _context.Set<Booking>()
                .CountAsync(b => b.Unit.PropertyId == propertyId && b.BookedAt >= fromDate && b.BookedAt <= toDate, cancellationToken);
            var totalRevenue = await _context.Set<Payment>()
                .Where(p => p.Booking.Unit.PropertyId == propertyId && p.PaymentDate >= fromDate && p.PaymentDate <= toDate)
                .SumAsync(p => p.Amount.Amount, cancellationToken);
            return new { totalBookings, totalRevenue };
        }

        public async Task<IEnumerable<Property>> GetPendingPropertiesAsync(CancellationToken cancellationToken = default)
            => await _dbSet.Where(p => !p.IsApproved).ToListAsync(cancellationToken);

        public async Task<IEnumerable<Property>> GetPopularDestinationsAsync(int count, CancellationToken cancellationToken = default)
        {
            return await _dbSet
                .GroupJoin(_context.Set<Booking>(), p => p.Id, b => b.Unit.PropertyId, (p, bs) => new { Property = p, Count = bs.Count() })
                .OrderByDescending(x => x.Count)
                .Take(count)
                .Select(x => x.Property)
                .ToListAsync(cancellationToken);
        }

        public async Task<IEnumerable<Property>> GetRecommendedPropertiesAsync(Guid userId, int count, CancellationToken cancellationToken = default)
        {
            var userPropertyIds = await _context.Set<Booking>()
                .Where(b => b.UserId == userId)
                .Select(b => b.Unit.PropertyId)
                .Distinct()
                .ToListAsync(cancellationToken);
            return await _dbSet
                .Where(p => !userPropertyIds.Contains(p.Id))
                .OrderByDescending(p => p.CreatedAt)
                .Take(count)
                .ToListAsync(cancellationToken);
        }

        public async Task<User?> GetOwnerByIdAsync(Guid ownerId, CancellationToken cancellationToken = default)
            => await _context.Users.FindAsync(new object[]{ownerId}, cancellationToken);

        public async Task<PropertyType?> GetPropertyTypeByIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default)
            => await _context.Set<PropertyType>().FindAsync(new object[]{propertyTypeId}, cancellationToken);

        public async Task<IEnumerable<Property>> GetTopPerformingPropertiesAsync(int count, CancellationToken cancellationToken = default)
        {
            return await _dbSet
                .GroupJoin(_context.Set<Booking>(), p => p.Id, b => b.Unit.PropertyId, (p, bs) => new { Property = p, Count = bs.Count() })
                .OrderByDescending(x => x.Count)
                .Take(count)
                .Select(x => x.Property)
                .ToListAsync(cancellationToken);
        }

        public async Task<PropertyPolicy?> GetCancellationPolicyAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            // TODO: implement actual cancellation policy retrieval logic
            return await _context.Set<PropertyPolicy>()
                .FirstOrDefaultAsync(p => p.PropertyId == propertyId && p.Type == PolicyType.Cancellation, cancellationToken);
        }
    }
}
