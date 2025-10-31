using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Enums;
using System.Linq.Expressions;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع الوحدات
    /// Unit repository implementation
    /// </summary>
    public class UnitRepository : BaseRepository<Unit>, IUnitRepository
    {
        public UnitRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<Unit> CreateUnitAsync(Unit unit, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(unit, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return unit;
        }

        public async Task<Unit?> GetUnitByIdAsync(Guid unitId, CancellationToken cancellationToken = default)
            => await _dbSet.FindAsync(new object[] { unitId }, cancellationToken);

        public async Task<Unit?> GetByIdWithRelatedDataAsync(Guid unitId, CancellationToken cancellationToken = default)
        {
            // الحصول على الوحدة مع البيانات المرتبطة (الحقول الديناميكية، قواعد التسعير، الإتاحة)
            return await _dbSet
                .Include(u => u.FieldValues)
                    .ThenInclude(fv => fv.UnitTypeField)
                .Include(u => u.PricingRules)
                .Include(u => u.UnitAvailabilities)
                .Include(u => u.Property)
                .Include(u => u.UnitType)
                .FirstOrDefaultAsync(u => u.Id == unitId, cancellationToken);
        }

        public async Task<Unit> UpdateUnitAsync(Unit unit, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(unit);
            await _context.SaveChangesAsync(cancellationToken);
            return unit;
        }

        public async Task<bool> DeleteUnitAsync(Guid unitId, CancellationToken cancellationToken = default)
        {
            var unit = await GetUnitByIdAsync(unitId, cancellationToken);
            if (unit == null) return false;
            _dbSet.Remove(unit);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<Unit>> GetUnitsByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _dbSet
                .AsNoTracking()
                .Where(u => u.PropertyId == propertyId && !u.IsDeleted)
                .ToListAsync(cancellationToken);

        public async Task<IEnumerable<Unit>> GetAvailableUnitsAsync(Guid propertyId, DateTime checkIn, DateTime checkOut, int guestCount, CancellationToken cancellationToken = default)
        {
            var units = await GetUnitsByPropertyAsync(propertyId, cancellationToken);
            var result = new List<Unit>();
            foreach (var u in units)
            {
                var overlapping = await _context.Bookings.AnyAsync(b => b.UnitId == u.Id && b.CheckIn < checkOut && b.CheckOut > checkIn, cancellationToken);
                if (!overlapping) result.Add(u);
            }
            return result;
        }

        public async Task<IEnumerable<Unit>> GetUnitsByTypeAsync(Guid unitTypeId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(u => u.UnitTypeId == unitTypeId).ToListAsync(cancellationToken);

        /// <summary>
        /// الحصول على الوحدات المتاحة (نشطة) لعقار معين
        /// Get active (available) units for a property
        /// </summary>
        public async Task<IEnumerable<Unit>> GetActiveByPropertyIdAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(u => u.PropertyId == propertyId && u.IsAvailable).ToListAsync(cancellationToken);

        public async Task<Property?> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _context.Set<Property>().FirstOrDefaultAsync(p => p.Id == propertyId, cancellationToken);

        public async Task<UnitType?> GetUnitTypeByIdAsync(Guid unitTypeId, CancellationToken cancellationToken = default)
            => await _context.Set<UnitType>().FirstOrDefaultAsync(ut => ut.Id == unitTypeId, cancellationToken);

        public async Task<bool> UpdateAvailabilityAsync(Guid unitId, DateTime fromDate, DateTime toDate, bool isAvailable, CancellationToken cancellationToken = default)
        {
            // تحديث حالة التوفر العام للوحدة
            var unit = await GetUnitByIdAsync(unitId, cancellationToken);
            if (unit == null) return false;
            unit.IsAvailable = isAvailable;
            _dbSet.Update(unit);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> CheckActiveBookingsAsync(Guid unitId, CancellationToken cancellationToken = default)
            => await _context.Bookings.AnyAsync(b => b.UnitId == unitId && b.Status == BookingStatus.Confirmed, cancellationToken);

        /// <summary>
        /// التحقق من وجود أي حجوزات للوحدة (بغض النظر عن الحالة)
        /// </summary>
        public async Task<bool> HasAnyBookingsAsync(Guid unitId, CancellationToken cancellationToken = default)
        {
            return await _context.Bookings.AnyAsync(b => b.UnitId == unitId, cancellationToken);
        }

        /// <summary>
        /// التحقق من وجود أي مدفوعات مرتبطة بحجوزات هذه الوحدة (حتى وإن كانت مستردة)
        /// </summary>
        public async Task<bool> HasAnyPaymentsAsync(Guid unitId, CancellationToken cancellationToken = default)
        {
            return await _context.Payments
                .Include(p => p.Booking)
                .AnyAsync(p => p.Booking.UnitId == unitId, cancellationToken);
        }

        public async Task<IDictionary<DateTime, bool>> GetUnitAvailabilityAsync(Guid unitId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            var dict = new Dictionary<DateTime, bool>();
            for (var date = fromDate.Date; date <= toDate.Date; date = date.AddDays(1))
            {
                var overlapping = await _context.Bookings.AnyAsync(b => b.UnitId == unitId && b.CheckIn <= date && b.CheckOut > date, cancellationToken);
                dict[date] = !overlapping;
            }
            return dict;
        }

        public async Task<Unit> GetByIdWithIncludesAsync(Guid id, params Expression<Func<Unit, object>>[] includes)
        {
            IQueryable<Unit> query = _dbSet;

            foreach (var include in includes)
            {
                query = query.Include(include);
            }

            return await query.FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted);
        }

        public async Task<Unit> GetByIdWithUnitTypeAsync(Guid id)
        {
            return await _dbSet
                .Include(u => u.UnitType)
                .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted);
        }
        


    }
} 