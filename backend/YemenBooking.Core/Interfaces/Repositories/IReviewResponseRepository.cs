using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع ردود التقييمات
/// Review responses repository interface
/// </summary>
public interface IReviewResponseRepository : IRepository<ReviewResponse>
{
    Task<ReviewResponse> CreateAsync(ReviewResponse response, CancellationToken cancellationToken = default);
    Task<IEnumerable<ReviewResponse>> GetByReviewIdAsync(Guid reviewId, CancellationToken cancellationToken = default);
    Task<bool> DeleteAsync(Guid responseId, CancellationToken cancellationToken = default);
}

