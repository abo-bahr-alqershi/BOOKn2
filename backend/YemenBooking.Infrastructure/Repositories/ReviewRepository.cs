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
    /// <summary>
    /// تنفيذ مستودع التقييمات
    /// Review repository implementation
    /// </summary>
    public class ReviewRepository : BaseRepository<Review>, IReviewRepository
    {
        public ReviewRepository(YemenBookingDbContext context) : base(context) { }

        public async Task<Review> CreateReviewAsync(Review review, CancellationToken cancellationToken = default)
        {
            await _dbSet.AddAsync(review, cancellationToken);
            await _context.SaveChangesAsync(cancellationToken);
            return review;
        }

        public async Task<Review?> GetReviewByIdAsync(Guid reviewId, CancellationToken cancellationToken = default)
            => await _dbSet.FindAsync(new object[]{reviewId}, cancellationToken);

        public async Task<Review> UpdateReviewAsync(Review review, CancellationToken cancellationToken = default)
        {
            _dbSet.Update(review);
            await _context.SaveChangesAsync(cancellationToken);
            return review;
        }

        public async Task<bool> DeleteReviewAsync(Guid reviewId, CancellationToken cancellationToken = default)
        {
            var review = await GetReviewByIdAsync(reviewId, cancellationToken);
            if (review == null) return false;
            _dbSet.Remove(review);
            await _context.SaveChangesAsync(cancellationToken);
            return true;
        }

        public async Task<bool> CheckReviewEligibilityAsync(Guid bookingId, Guid userId, CancellationToken cancellationToken = default)
        {
            // Eligibility: booking exists and belongs to user and no existing review
            var exists = await _context.Bookings.AnyAsync(b => b.Id == bookingId && b.UserId == userId, cancellationToken);
            if (!exists) return false;
            return !await _dbSet.AnyAsync(r => r.BookingId == bookingId, cancellationToken);
        }

        public async Task<IEnumerable<Review>> GetReviewsByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default)
            => await _dbSet.Include(r => r.Booking)
                           .Where(r => r.Booking.Unit.PropertyId == propertyId)
                           .ToListAsync(cancellationToken);

        public async Task<IEnumerable<Review>> GetReviewsByUserAsync(Guid userId, CancellationToken cancellationToken = default)
            => await _dbSet.Where(r => r.Booking.UserId == userId).ToListAsync(cancellationToken);

        public async Task<Review?> GetReviewByBookingAsync(Guid bookingId, CancellationToken cancellationToken = default)
            => await _dbSet.FirstOrDefaultAsync(r => r.BookingId == bookingId, cancellationToken);

        public async Task<(double AverageRating, int TotalReviews)> GetPropertyRatingStatsAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            var reviews = await _dbSet.Include(r => r.Booking)
                                       .Where(r => r.Booking.Unit.PropertyId == propertyId)
                                       .ToListAsync(cancellationToken);
            var count = reviews.Count;
            var avg = count > 0 ? reviews.Average(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0) : 0.0;
            return (Math.Round(avg,2), count);
        }

        public async Task<double> CalculateAverageRatingAsync(Guid propertyId, CancellationToken cancellationToken = default)
        {
            var stats = await GetPropertyRatingStatsAsync(propertyId, cancellationToken);
            return stats.AverageRating;
        }

        public async Task<Booking?> GetBookingByIdAsync(Guid bookingId, CancellationToken cancellationToken = default)
        {
            return await _context.Bookings.FindAsync(new object[] { bookingId }, cancellationToken);
        }
    }
}