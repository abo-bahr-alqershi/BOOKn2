using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reviews.Queries.GetReviewResponses
{
    /// <summary>
    /// استعلام لجلب ردود التقييم
    /// </summary>
    public class GetReviewResponsesQuery : IRequest<ResultDto<List<ReviewResponseDto>>>
    {
        public Guid ReviewId { get; set; }
    }
}

