using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Reviews.Commands.ReviewResponse
{
    /// <summary>
    /// أمر لحذف رد تقييم
    /// </summary>
    public class DeleteReviewResponseCommand : IRequest<ResultDto<bool>>
    {
        public Guid ResponseId { get; set; }
    }
}

