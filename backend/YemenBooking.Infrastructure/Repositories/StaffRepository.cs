using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Enums;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع الموظفين
    /// Staff repository implementation
    /// </summary>
    public class StaffRepository : BaseRepository<Staff>, IStaffRepository
    {
        public StaffRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<Staff> AddStaffAsync(Staff staff, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(staff, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return staff;
        }

        public async Task<Staff?> GetStaffByIdAsync(Guid staffId, CancellationToken cancellationToken = default)
            => await _dbSet.FindAsync(new object[]{staffId}, cancellationToken);

        public async Task<Staff> UpdateStaffAsync(Staff staff, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(staff);
            await _context.SaveChangesAsync(cancellationToken);
            return staff;
        }

        public async Task<bool> RemoveStaffAsync(Guid staffId, CancellationToken cancellationToken = default)
        {
            var staff = await GetStaffByIdAsync(staffId, cancellationToken);
            if (staff == null) return false;
            _dbSet.Remove(staff);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<Staff>> GetStaffByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(s => s.PropertyId == propertyId).ToListAsync(cancellationToken);

        public async Task<Staff?> GetStaffByUserAsync(Guid userId, CancellationToken cancellationToken = default)
            => await _dbSet.FirstOrDefaultAsync(s => s.UserId == userId, cancellationToken);

        public async Task<IEnumerable<Staff>> GetStaffByPositionAsync(string position, Guid? propertyId = null, CancellationToken cancellationToken = default)
        {
            var parsedPosition = Enum.Parse<StaffPosition>(position, true);
            var query = _dbSet.Where(s => s.Position == parsedPosition);
            if (propertyId.HasValue) query = query.Where(s => s.PropertyId == propertyId.Value);
            return await query.ToListAsync(cancellationToken);
        }

        public async Task<User?> GetUserByIdAsync(Guid userId, CancellationToken cancellationToken = default)
            => await _context.Set<User>().FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

        public async Task<Property?> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _context.Set<Property>().FirstOrDefaultAsync(p => p.Id == propertyId, cancellationToken);
    }
} 