using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Reviews;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reviews.Queries.GetReviewResponses
{
    /// <summary>
    /// معالج استعلام جلب ردود التقييم
    /// </summary>
    public class GetReviewResponsesQueryHandler : IRequestHandler<GetReviewResponsesQuery, ResultDto<List<ReviewResponseDto>>>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly IReviewResponseRepository _responseRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetReviewResponsesQueryHandler> _logger;

        public GetReviewResponsesQueryHandler(
            IReviewRepository reviewRepository,
            IReviewResponseRepository responseRepository,
            ICurrentUserService currentUserService,
            ILogger<GetReviewResponsesQueryHandler> logger)
        {
            _reviewRepository = reviewRepository;
            _responseRepository = responseRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<List<ReviewResponseDto>>> Handle(GetReviewResponsesQuery request, CancellationToken cancellationToken)
        {
            if (request.ReviewId == Guid.Empty)
                return ResultDto<List<ReviewResponseDto>>.Failed("معرف التقييم مطلوب");

            var review = await _reviewRepository.GetReviewByIdAsync(request.ReviewId, cancellationToken);
            if (review == null)
                return ResultDto<List<ReviewResponseDto>>.Failed("التقييم غير موجود");

            // Admin or property staff can view
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            var isOwnerAuthorized = _currentUserService.PropertyId.HasValue && _currentUserService.PropertyId.Value == review.PropertyId;
            if (!(isAdmin || isOwnerAuthorized))
                return ResultDto<List<ReviewResponseDto>>.Failed("غير مصرح لك بعرض الردود");

            var responses = await _responseRepository.GetByReviewIdAsync(request.ReviewId, cancellationToken);
            var list = responses.Select(r => new ReviewResponseDto
            {
                Id = r.Id,
                ReviewId = r.ReviewId,
                ResponseText = r.Text,
                RespondedBy = r.RespondedBy,
                RespondedByName = r.RespondedByName,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt
            }).ToList();

            return ResultDto<List<ReviewResponseDto>>.Ok(list);
        }
    }
}

