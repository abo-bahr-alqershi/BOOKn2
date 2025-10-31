using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reviews.Queries.GetReviewDetails
{
    /// <summary>
    /// استعلام جلب تفاصيل تقييم واحد للوحة التحكم
    /// Get admin review details by id
    /// </summary>
    public class GetReviewDetailsQuery : IRequest<ResultDto<AdminReviewDetailsDto>>
    {
        public Guid ReviewId { get; set; }
    }
}

