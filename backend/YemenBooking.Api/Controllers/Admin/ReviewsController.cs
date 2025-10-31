using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Reviews.Commands.Review;
using YemenBooking.Application.Features.Reviews.Commands.RespondToReview;
using YemenBooking.Application.Features.Reviews.Queries.GetAllReviews;
using YemenBooking.Application.Features.Reviews.Queries.GetReviewDetails;
using YemenBooking.Application.Features.Analytics.Commands.Reviews;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews.Queries.GetReviewByBooking;
using YemenBooking.Application.Features.Reviews.Commands.ReviewResponse;
using YemenBooking.Application.Features.Reviews.Queries.GetReviewResponses;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بالتقييمات للمدراء
    /// Controller for managing reviews by admins
    /// </summary>
    public class ReviewsController : BaseAdminController
    {
        public ReviewsController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// جلب جميع التقييمات مع دعم التصفية
        /// Get all reviews with filtering
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllReviews([FromQuery] GetAllReviewsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب تفاصيل تقييم محدد
        /// Get details of a specific review
        /// </summary>
        [HttpGet("{reviewId}")]
        public async Task<IActionResult> GetReviewDetails(Guid reviewId)
        {
            var result = await _mediator.Send(new GetReviewDetailsQuery { ReviewId = reviewId });
            return Ok(result);
        }

        /// <summary>
        /// جلب تقييم مرتبط بحجز محدد
        /// </summary>
        [HttpGet("by-booking/{bookingId}")]
        public async Task<IActionResult> GetReviewByBooking(Guid bookingId)
        {
            var result = await _mediator.Send(new GetReviewByBookingQuery { BookingId = bookingId });
            return Ok(result);
        }

        /// <summary>
        /// الموافقة على تقييم
        /// Approve a review
        /// </summary>
        [HttpPost("{reviewId}/approve")]
        public async Task<IActionResult> ApproveReview(Guid reviewId, [FromBody] ApproveReviewCommand command)
        {
            command.ReviewId = reviewId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف تقييم
        /// Delete a review
        /// </summary>
        [HttpDelete("{reviewId}")]
        public async Task<IActionResult> DeleteReview(Guid reviewId)
        {
            var command = new DeleteReviewCommand { ReviewId = reviewId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إضافة رد على تقييم
        /// </summary>
        [HttpPost("{reviewId}/respond")]
        public async Task<IActionResult> RespondToReview(Guid reviewId, [FromBody] RespondToReviewCommand command)
        {
            command.ReviewId = reviewId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب ردود تقييم
        /// </summary>
        [HttpGet("{reviewId}/responses")]
        public async Task<IActionResult> GetReviewResponses(Guid reviewId)
        {
            var responses = await _mediator.Send(new GetReviewResponsesQuery { ReviewId = reviewId });
            return Ok(responses);
        }

        /// <summary>
        /// حذف رد تقييم
        /// </summary>
        [HttpDelete("responses/{responseId}")]
        public async Task<IActionResult> DeleteReviewResponse(Guid responseId)
        {
            var result = await _mediator.Send(new DeleteReviewResponseCommand { ResponseId = responseId });
            return Ok(result);
        }
    }
} 