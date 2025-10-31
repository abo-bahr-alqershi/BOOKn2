using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع التقييمات
/// Review repository interface
/// </summary>
public interface IReviewRepository : IRepository<Review>
{
    /// <summary>
    /// إنشاء تقييم جديد
    /// Create new review
    /// </summary>
    Task<Review> CreateReviewAsync(Review review, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على تقييم بواسطة المعرف
    /// Get review by id
    /// </summary>
    Task<Review?> GetReviewByIdAsync(Guid reviewId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث التقييم
    /// Update review
    /// </summary>
    Task<Review> UpdateReviewAsync(Review review, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف التقييم
    /// Delete review
    /// </summary>
    Task<bool> DeleteReviewAsync(Guid reviewId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من أهلية التقييم
    /// Check review eligibility
    /// </summary>
    Task<bool> CheckReviewEligibilityAsync(Guid bookingId, Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على تقييمات الكيان
    /// Get reviews by property
    /// </summary>
    Task<IEnumerable<Review>> GetReviewsByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على تقييمات المستخدم
    /// Get reviews by user
    /// </summary>
    Task<IEnumerable<Review>> GetReviewsByUserAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على تقييم الحجز
    /// Get review by booking
    /// </summary>
    Task<Review?> GetReviewByBookingAsync(Guid bookingId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على إحصائيات تقييم الكيان
    /// Get property rating stats
    /// </summary>
    Task<(double AverageRating, int TotalReviews)> GetPropertyRatingStatsAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// حساب متوسط التقييم
    /// Calculate average rating
    /// </summary>
    Task<double> CalculateAverageRatingAsync(Guid propertyId, CancellationToken cancellationToken = default);

        /// <summary>
    /// الحصول على الحجز بواسطة المعرف
    /// Get booking by id
    /// </summary>
    Task<Booking?> GetBookingByIdAsync(Guid bookingId, CancellationToken cancellationToken = default);

}
