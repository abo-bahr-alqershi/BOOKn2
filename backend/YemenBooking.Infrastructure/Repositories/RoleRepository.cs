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
    /// تنفيذ مستودع الأدوار
    /// Role repository implementation
    /// </summary>
    public class RoleRepository : BaseRepository<Role>, IRoleRepository
    {
        public RoleRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<Role?> GetRoleByIdAsync(Guid roleId, CancellationToken cancellationToken = default)
            => await _dbSet.FindAsync(new object[]{roleId}, cancellationToken);

        public async Task<IEnumerable<Role>> GetAllRolesAsync(CancellationToken cancellationToken = default)
            => await _dbSet.ToListAsync(cancellationToken);

        public async Task<Role> CreateRoleAsync(Role role, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(role, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return role;
        }

        public async Task<Role> UpdateRoleAsync(Role role, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(role);
            await _context.SaveChangesAsync(cancellationToken);
            return role;
        }

        public async Task<bool> DeleteRoleAsync(Guid roleId, CancellationToken cancellationToken = default)
        {
            var role = await GetRoleByIdAsync(roleId, cancellationToken);
            if (role == null) return false;
            _dbSet.Remove(role);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> AssignRoleToUserAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default)
        {
            var userRole = new UserRole { UserId = userId, RoleId = roleId, AssignedAt = DateTime.UtcNow };
            await _context.Set<UserRole>().AddAsync(userRole, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> RemoveRoleFromUserAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default)
        {
            var ur = await _context.Set<UserRole>().FirstOrDefaultAsync(r => r.UserId == userId && r.RoleId == roleId, cancellationToken);
            if (ur == null) return false;
            _context.Set<UserRole>().Remove(ur);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> HasPermissionAsync(Guid userId, string permission, CancellationToken cancellationToken = default)
        {
            // منح الصلاحيات فقط للمسؤولين حالياً
            var isAdmin = await _context.Set<UserRole>()
                .Include(ur => ur.Role)
                .AnyAsync(ur => ur.UserId == userId && ur.Role.Name.Equals("Admin", StringComparison.OrdinalIgnoreCase), cancellationToken);
            return isAdmin;
        }
    }
}
