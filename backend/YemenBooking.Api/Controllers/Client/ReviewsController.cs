using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Reviews.Commands.SubmitReview;
using YemenBooking.Application.Features.Reviews.Queries.GetPropertyReviews;
using YemenBooking.Application.Features.Reviews.Queries.GetReviewsSummarySummary;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر إدارة التقييمات للعملاء
    /// Client Reviews Management Controller
    /// </summary>
    public class ReviewsController : BaseClientController
    {
        public ReviewsController(IMediator mediator) : base(mediator)
        {
        }

        /// <summary>
        /// إرسال تقييم جديد
        /// Submit new review
        /// </summary>
        /// <param name="command">بيانات التقييم</param>
        /// <returns>نتيجة إرسال التقييم</returns>
        [HttpPost]
        public async Task<ActionResult<ResultDto<SubmitReviewResponse>>> SubmitReview([FromBody] SubmitReviewCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على تقييمات عقار محدد للعملاء
        /// Get property reviews for clients
        /// </summary>
        /// <param name="query">معايير البحث</param>
        /// <returns>قائمة التقييمات</returns>
        [HttpGet("property")]
        public async Task<ActionResult<ResultDto<PaginatedResult<ClientReviewDto>>>> GetPropertyReviews([FromQuery] ClientGetPropertyReviewsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على ملخص التقييمات للعملاء
        /// Get reviews summary for clients
        /// </summary>
        /// <param name="query">معايير الملخص</param>
        /// <returns>ملخص التقييمات</returns>
        [HttpGet("summary")]
        public async Task<ActionResult<ResultDto<ClientReviewsSummaryDto>>> GetReviewsSummary([FromQuery] ClientGetReviewsSummaryQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        // TODO: UploadImageRequest type not found - needs to be implemented
        // /// <summary>
        // /// رفع صورة واحدة
        // /// Accept multipart/form-data and return UploadImageResponse
        // /// </summary>
        // [HttpPost("upload")]
        // [Consumes("multipart/form-data")]
        // public async Task<IActionResult> UploadImage([FromForm] UploadImageRequest request)
        // {
        //     var result = await _mediator.Send(request);
        //     return Ok(result);
        // }
    }
}
