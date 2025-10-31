using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع صور التقييم
/// Review Image repository interface
/// </summary>
public interface IReviewImageRepository : IRepository<ReviewImage>
{
    /// <summary>
    /// إنشاء صورة تقييم جديدة
    /// Create a new review image
    /// </summary>
    Task<ReviewImage> CreateReviewImageAsync(ReviewImage reviewImage, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على صور التقييم بناء على معرف التقييم
    /// Get review images by review ID
    /// </summary>
    Task<IEnumerable<ReviewImage>> GetImagesByReviewAsync(Guid reviewId, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف صورة تقييم
    /// Delete review image
    /// </summary>
    Task<bool> DeleteReviewImageAsync(Guid reviewImageId, CancellationToken cancellationToken = default);
} 