using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Reviews.Commands.Review;

/// <summary>
/// أمر لحذف التقييم
/// Command to delete a review
/// </summary>
public class DeleteReviewCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف التقييم
    /// Review ID
    /// </summary>
    public Guid ReviewId { get; set; }
} 