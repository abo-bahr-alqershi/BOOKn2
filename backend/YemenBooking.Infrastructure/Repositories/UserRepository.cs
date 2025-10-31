using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;
using YemenBooking.Core.Interfaces.Repositories;
using System.Linq;
using System.Text.Json;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع المستخدمين
    /// User repository implementation
    /// </summary>
    public class UserRepository : BaseRepository<User>, IUserRepository
    {
        public UserRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<User> CreateUserAsync(User user, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(user, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return user;
        }

        public async Task<User?> GetUserByIdAsync(Guid userId, CancellationToken cancellationToken = default)
            => await _dbSet.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);

        public async Task<User?> GetUserByEmailAsync(string email, CancellationToken cancellationToken = default)
        {
            var normalized = (email ?? string.Empty).Trim().ToLower();
            return await _dbSet.FirstOrDefaultAsync(u => u.Email.ToLower() == normalized, cancellationToken);
        }

        public async Task<User?> GetByPhoneAsync(string phone, CancellationToken cancellationToken = default)
            => await _dbSet.FirstOrDefaultAsync(u => u.Phone == phone, cancellationToken);

        public async Task<bool> CheckEmailExistsAsync(string email, CancellationToken cancellationToken = default)
        {
            var normalized = (email ?? string.Empty).Trim().ToLower();
            return await _dbSet.AnyAsync(u => u.Email.ToLower() == normalized, cancellationToken);
        }

        public async Task<User> UpdateUserAsync(User user, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(user);
            await _context.SaveChangesAsync(cancellationToken);
            return user;
        }

        public async Task<bool> DeactivateUserAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            var user = await GetUserByIdAsync(userId, cancellationToken);
            if (user == null) return false;
            user.IsActive = false;
            _dbSet.Update(user);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }


        public async Task<bool> ActivateUserAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            var user = await GetUserByIdAsync(userId, cancellationToken);
            if (user == null) return false;
            user.IsActive = true;
            _dbSet.Update(user);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<IEnumerable<User>> GetAllUsersAsync(CancellationToken cancellationToken = default)
            => await _dbSet.ToListAsync(cancellationToken);

        public async Task<(IEnumerable<User> Users, int TotalCount)> GetUsersWithPaginationAsync(int page, int pageSize, CancellationToken cancellationToken = default)
        {
            var total = await _dbSet.CountAsync(cancellationToken);
            var users = await _dbSet.Skip((page-1)*pageSize).Take(pageSize).ToListAsync(cancellationToken);
            return (users, total);
        }

        public async Task<IEnumerable<User>> SearchUsersAsync(string searchTerm, CancellationToken cancellationToken = default)
            => await _dbSet
                .Where(u => u.Name.Contains(searchTerm) || u.Email.Contains(searchTerm))
                .ToListAsync(cancellationToken);

        public async Task<User?> GetOwnerByIdAsync(Guid ownerId, CancellationToken cancellationToken = default)
            => await GetUserByIdAsync(ownerId, cancellationToken);

        public async Task<IEnumerable<UserRole>> GetUserRolesAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            return await _context.Set<UserRole>()
                .Where(ur => ur.UserId == userId)
                .ToListAsync(cancellationToken);
        }

        public async Task<object> AnalyzeUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            var user = await GetUserByIdAsync(userId, cancellationToken);
            if (user == null) return null;
            return JsonSerializer.Deserialize<object>(user.SettingsJson);
        }

        public async Task<decimal> CalculateCustomerRetentionAsync(DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
        {
            var totalCustomers = await _dbSet.CountAsync(cancellationToken);
            if (totalCustomers == 0) return 0m;
            var activeCustomers = await _context.Set<Booking>()
                .Where(b => b.BookedAt >= fromDate && b.BookedAt <= toDate)
                .Select(b => b.UserId)
                .Distinct()
                .CountAsync(cancellationToken);
            return (decimal)activeCustomers / totalCustomers;
        }

        public async Task<IEnumerable<User>> GetUsersByRegistrationMonthAsync(int year, int month, CancellationToken cancellationToken = default)
        {
            return await _dbSet
                .Where(u => u.CreatedAt.Year == year && u.CreatedAt.Month == month)
                .ToListAsync(cancellationToken);
        }

        public async Task<bool> UpdateUserSettingsAsync(Guid userId, string settingsJson, CancellationToken cancellationToken = default)
        {
            var user = await GetUserByIdAsync(userId, cancellationToken);
            if (user == null)
                return false;
            user.SettingsJson = settingsJson;
            _dbSet.Update(user);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> UpdateUserFavoritesAsync(Guid userId, string favoritesJson, CancellationToken cancellationToken = default)
        {
            var user = await GetUserByIdAsync(userId, cancellationToken);
            if (user == null)
                return false;
            user.FavoritesJson = favoritesJson;
            _dbSet.Update(user);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
}
