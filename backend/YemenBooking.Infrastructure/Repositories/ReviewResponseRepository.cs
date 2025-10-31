using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Infrastructure.Data.Context;

namespace YemenBooking.Infrastructure.Repositories
{
    /// <summary>
    /// تنفيذ مستودع ردود التقييمات
    /// Review responses repository implementation
    /// </summary>
    public class ReviewResponseRepository : BaseRepository<ReviewResponse>, IReviewResponseRepository
    {
        public ReviewResponseRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<ReviewResponse> CreateAsync(ReviewResponse response, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(response, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return response;
        }

        public async Task<IEnumerable<ReviewResponse>> GetByReviewIdAsync(Guid reviewId, CancellationToken cancellationToken = default)
        {
            return await _dbSet
                .AsNoTracking()
                .Where(r => r.ReviewId == reviewId)
                .OrderByDescending(r => r.RespondedAt)
                .ToListAsync(cancellationToken);
        }

        public async Task<bool> DeleteAsync(Guid responseId, CancellationToken cancellationToken = default)
        {
            var entity = await _dbSet.FindAsync(new object[] { responseId }, cancellationToken);
            if (entity == null) return false;
            _dbSet.Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
}

