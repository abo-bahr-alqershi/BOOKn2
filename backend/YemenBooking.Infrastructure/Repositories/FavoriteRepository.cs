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
    public class FavoriteRepository : BaseRepository<Favorite>, IFavoriteRepository
    {
        public FavoriteRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<IEnumerable<Favorite>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            return await _dbSet.AsNoTracking()
                .Where(f => f.UserId == userId && !f.IsDeleted)
                .OrderByDescending(f => f.DateAdded)
                .ToListAsync(cancellationToken);
        }

        public async Task<(IEnumerable<Favorite> Items, int TotalCount)> GetUserFavoritesAsync(Guid userId, int pageNumber = 1, int pageSize = 10, CancellationToken cancellationToken = default)
        {
            if (pageNumber < 1) pageNumber = 1;
            if (pageSize < 1) pageSize = 10;

            var query = _dbSet.AsNoTracking().Where(f => f.UserId == userId && !f.IsDeleted);
            var total = await query.CountAsync(cancellationToken);
            var items = await query
                .OrderByDescending(f => f.DateAdded)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            return (items, total);
        }

        public async Task<bool> ExistsAsync(Guid userId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            return await _dbSet.AsNoTracking().AnyAsync(
                f => f.UserId == userId && f.PropertyId == propertyId && !f.IsDeleted,
                cancellationToken);
        }

        public async Task<int> CountUserFavoritesAsync(Guid userId, CancellationToken cancellationToken = default)
        {
            return await _dbSet.AsNoTracking().CountAsync(f => f.UserId == userId && !f.IsDeleted, cancellationToken);
        }

        public Task<IEnumerable<(Guid PropertyId, int FavoriteCount)>> GetMostFavoritedPropertiesAsync(int limit = 10, CancellationToken cancellationToken = default)
        {
            throw new NotImplementedException();
        }

        public new async Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default)
        {
            var entity = await _dbSet.FirstOrDefaultAsync(f => f.Id == id, cancellationToken);
            if (entity == null) return false;
            _dbSet.Remove(entity);
            return true;
        }

        public async Task<bool> DeleteByUserAndPropertyAsync(Guid userId, Guid propertyId, CancellationToken cancellationToken = default)
        {
            var entity = await _dbSet.FirstOrDefaultAsync(
                f => f.UserId == userId && f.PropertyId == propertyId,
                cancellationToken);
            if (entity == null) return false;
            _dbSet.Remove(entity);
            return true;
        }
    }
}
