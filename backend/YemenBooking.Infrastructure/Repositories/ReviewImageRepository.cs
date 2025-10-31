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
    /// تنفيذ مستودع صور التقييم
    /// Review image repository implementation
    /// </summary>
    public class ReviewImageRepository : BaseRepository<ReviewImage>, IReviewImageRepository
    {
        public ReviewImageRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<ReviewImage> CreateReviewImageAsync(ReviewImage reviewImage, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(reviewImage, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return reviewImage;
        }

        public async Task<IEnumerable<ReviewImage>> GetImagesByReviewAsync(Guid reviewId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(img => img.ReviewId == reviewId).ToListAsync(cancellationToken);

        public async Task<bool> DeleteReviewImageAsync(Guid reviewImageId, CancellationToken cancellationToken = default)
        {
            var img = await GetByIdAsync(reviewImageId, cancellationToken);
            if (img == null) return false;
            _dbSet.Remove(img);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }
    }
} 