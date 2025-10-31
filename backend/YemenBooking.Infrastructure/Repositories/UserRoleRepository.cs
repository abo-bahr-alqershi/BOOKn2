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
    /// تنفيذ مستودع أدوار المستخدمين
    /// UserRole repository implementation
    /// </summary>
    public class UserRoleRepository : BaseRepository<UserRole>, IUserRoleRepository
    {
        public UserRoleRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<UserRole> AssignRoleToUserAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default)
        {
            var entity = new UserRole { UserId = userId, RoleId = roleId };
            await _dbSet.AddAsync(entity, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return entity;
        }

        public async Task<bool> RemoveRoleFromUserAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default)
        {
            var entity = await _dbSet.FirstOrDefaultAsync(ur => ur.UserId == userId && ur.RoleId == roleId, cancellationToken);
            if (entity == null) return false;
            _dbSet.Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<UserRole>> GetUserRolesAsync(Guid userId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(ur => ur.UserId == userId).ToListAsync(cancellationToken);

        public async Task<bool> UserHasRoleAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default)
            => await _dbSet.AnyAsync(ur => ur.UserId == userId && ur.RoleId == roleId, cancellationToken);

        public async Task<IEnumerable<UserRole>> GetUsersInRoleAsync(Guid roleId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(ur => ur.RoleId == roleId).ToListAsync(cancellationToken);
    }
}
