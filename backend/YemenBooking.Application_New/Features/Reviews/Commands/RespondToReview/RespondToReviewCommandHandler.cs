using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Reviews;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Reviews.DTOs;

namespace YemenBooking.Application.Features.Reviews.Commands.RespondToReview
{
    /// <summary>
    /// معالج أمر إضافة رد على تقييم
    /// </summary>
    public class RespondToReviewCommandHandler : IRequestHandler<RespondToReviewCommand, ResultDto<ReviewResponseDto>>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly IReviewResponseRepository _responseRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IUserRepository _userRepository;
        private readonly IAuditService _auditService;
        private readonly ILogger<RespondToReviewCommandHandler> _logger;

        public RespondToReviewCommandHandler(
            IReviewRepository reviewRepository,
            IReviewResponseRepository responseRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<RespondToReviewCommandHandler> logger,
            IUserRepository userRepository)
        {
            _reviewRepository = reviewRepository;
            _responseRepository = responseRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _userRepository = userRepository;
        }

        public async Task<ResultDto<ReviewResponseDto>> Handle(RespondToReviewCommand request, CancellationToken cancellationToken)
        {
            if (request.ReviewId == Guid.Empty || string.IsNullOrWhiteSpace(request.ResponseText))
                return ResultDto<ReviewResponseDto>.Failed("ReviewId and Text are required");

            var review = await _reviewRepository.GetReviewByIdAsync(request.ReviewId, cancellationToken);
            if (review == null)
                return ResultDto<ReviewResponseDto>.Failed("التقييم غير موجود");

            // Only Admin or property staff can respond
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            var isOwnerAuthorized = _currentUserService.PropertyId.HasValue && _currentUserService.PropertyId.Value == review.PropertyId;
            if (!(isAdmin || isOwnerAuthorized))
                return ResultDto<ReviewResponseDto>.Failed("غير مصرح لك بالرد على هذا التقييم");

            var responderId = request.OwnerId != Guid.Empty ? request.OwnerId : _currentUserService.UserId;
            var responder = await _userRepository.GetUserByIdAsync(responderId, cancellationToken);
            var responderName = responder?.Name ?? _currentUserService.Username ?? string.Empty;

            var entity = new YemenBooking.Core.Entities.ReviewResponse
            {
                Id = Guid.NewGuid(),
                ReviewId = request.ReviewId,
                Text = request.ResponseText.Trim(),
                RespondedAt = DateTime.UtcNow,
                RespondedBy = responderId,
                RespondedByName = responderName,
                CreatedBy = responderId
            };

            entity = await _responseRepository.CreateAsync(entity, cancellationToken);

            // Update quick fields on Review for CP app
            review.ResponseText = entity.Text;
            review.ResponseDate = entity.RespondedAt;
            review.UpdatedBy = responderId;
            review.UpdatedAt = DateTime.UtcNow;
            await _reviewRepository.UpdateReviewAsync(review, cancellationToken);

            // تسجيل التدقيق (يدوي) يتضمن اسم ومعرّف المنفذ
            var notes = $"تم إضافة رد على التقييم {request.ReviewId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: nameof(YemenBooking.Core.Entities.ReviewResponse),
                entityId: entity.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { request.ReviewId, entity.Text }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            var dto = new ReviewResponseDto
            {
                Id = entity.Id,
                ReviewId = entity.ReviewId,
                ResponseText = entity.Text,
                RespondedBy = entity.RespondedBy,
                RespondedByName = entity.RespondedByName,
                CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(entity.CreatedAt),
                UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(entity.UpdatedAt)
            };

            return ResultDto<ReviewResponseDto>.Ok(dto, "تم إضافة الرد بنجاح");
        }
    }
}

