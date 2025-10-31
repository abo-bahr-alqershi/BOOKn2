using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews.DTOs;

namespace YemenBooking.Application.Features.Reviews.Commands.RespondToReview
{
    /// <summary>
    /// أمر لإضافة رد على تقييم
    /// Command to add a response to a review
    /// </summary>
    public class RespondToReviewCommand : IRequest<ResultDto<ReviewResponseDto>>
    {
        public Guid ReviewId { get; set; }
        public string ResponseText { get; set; } = string.Empty;
        public Guid OwnerId { get; set; }
    }
}

