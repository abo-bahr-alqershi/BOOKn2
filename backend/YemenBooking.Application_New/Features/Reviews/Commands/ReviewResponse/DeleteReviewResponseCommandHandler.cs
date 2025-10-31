using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Reviews;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Reviews.Commands.ReviewResponse
{
    /// <summary>
    /// معالج أمر حذف رد تقييم
    /// </summary>
    public class DeleteReviewResponseCommandHandler : IRequestHandler<DeleteReviewResponseCommand, ResultDto<bool>>
    {
        private readonly IReviewResponseRepository _responseRepository;
        private readonly IReviewRepository _reviewRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<DeleteReviewResponseCommandHandler> _logger;

        public DeleteReviewResponseCommandHandler(
            IReviewResponseRepository responseRepository,
            IReviewRepository reviewRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<DeleteReviewResponseCommandHandler> logger)
        {
            _responseRepository = responseRepository;
            _reviewRepository = reviewRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(DeleteReviewResponseCommand request, CancellationToken cancellationToken)
        {
            if (request.ResponseId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الرد مطلوب");

            // Load entity via base repository
            var exist = await _responseRepository.GetByIdAsync(request.ResponseId, cancellationToken);
            if (exist == null)
                return ResultDto<bool>.Failed("الرد غير موجود");

            // Load related review to verify property ownership for owners
            var review = await _reviewRepository.GetReviewByIdAsync(exist.ReviewId, cancellationToken);
            if (review == null)
                return ResultDto<bool>.Failed("التقييم المرتبط بهذا الرد غير موجود");

            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            var isOwnerAuthorized = _currentUserService.PropertyId.HasValue && _currentUserService.PropertyId.Value == review.PropertyId;
            var isCreator = exist.CreatedBy == _currentUserService.UserId;

            if (!(isAdmin || isOwnerAuthorized || isCreator))
                return ResultDto<bool>.Failed("غير مصرح لك بحذف هذا الرد");

            var ok = await _responseRepository.DeleteAsync(request.ResponseId, cancellationToken);
            if (!ok) return ResultDto<bool>.Failed("فشل حذف الرد");

            // تسجيل التدقيق (يدوي) يتضمن اسم ومعرّف المنفذ
            var notes = $"تم حذف رد {request.ResponseId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: nameof(Core.Entities.ReviewResponse),
                entityId: request.ResponseId,
                action: AuditAction.DELETE,
                oldValues: System.Text.Json.JsonSerializer.Serialize(new { request.ResponseId }),
                newValues: null,
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            return ResultDto<bool>.Ok(true, "تم حذف الرد بنجاح");
        }
    }
}

