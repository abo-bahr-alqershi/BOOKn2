using MediatR;
using System;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.Analytics.Commands.Reviews
{
    /// <summary>
    /// معالج أمر الموافقة على مراجعة
    /// Approves a pending review and includes:
    /// - التحقق من الوجود
    /// - التحقق من صلاحيات المسؤول
    /// - التحقق من حالة الموافقة
    /// - تحديث حالة المراجعة
    /// - تسجيل التدقيق
    /// - نشر الحدث
    /// </summary>
    public class ApproveReviewCommandHandler : IRequestHandler<ApproveReviewCommand,ResultDto<bool>>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly IEventPublisher _eventPublisher;
        private readonly ILogger<ApproveReviewCommandHandler> _logger;

        public ApproveReviewCommandHandler(
            IReviewRepository reviewRepository,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            IEventPublisher eventPublisher,
            ILogger<ApproveReviewCommandHandler> logger)
        {
            _reviewRepository = reviewRepository;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _eventPublisher = eventPublisher;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(ApproveReviewCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء الموافقة على المراجعة {ReviewId}", request.ReviewId);

            // التحقق من وجود المراجعة
            var review = await _reviewRepository.GetReviewByIdAsync(request.ReviewId, cancellationToken);
            if (review == null || review.IsDeleted)
                throw new NotFoundException("Review", request.ReviewId.ToString());

            // التحقق من صلاحية المسؤول
            if (_currentUserService.UserId != request.AdminId || _currentUserService.Role != "Admin")
                throw new ForbiddenException("غير مصرح لك بالموافقة على المراجعة");

            // التحقق من وضعية الموافقة
            if (!review.IsPendingApproval)
                throw new BusinessRuleException("AlreadyApproved", "المراجعة تمت الموافقة عليها مسبقاً");

            // تنفيذ العملية ضمن معاملة
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                review.IsPendingApproval = false;
                review.UpdatedBy = _currentUserService.UserId;
                review.UpdatedAt = DateTime.UtcNow;
                await _reviewRepository.UpdateReviewAsync(review, cancellationToken);

                // تسجيل التدقيق اليدوي مع ذكر اسم المستخدم والمعرف في الملاحظات
                var notes = $"تمت الموافقة على المراجعة {review.Id} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
                await _auditService.LogAuditAsync(
                    entityType: "Review",
                    entityId: review.Id,
                    action: AuditAction.APPROVE,
                    oldValues: null,
                    newValues: System.Text.Json.JsonSerializer.Serialize(new { Approved = true }),
                    performedBy: _currentUserService.UserId,
                    notes: notes,
                    cancellationToken: cancellationToken);

                // نشر الحدث
                // await _eventPublisher.PublishEventAsync(new ReviewApprovedEvent
                // {
                //     ReviewId = review.Id,
                //     ApprovedBy = _currentUserService.UserId,
                //     ApprovedAt = DateTime.UtcNow
                // }, cancellationToken);

                _logger.LogInformation("تمت الموافقة على المراجعة بنجاح: {ReviewId}", review.Id);
            });

            return ResultDto<bool>.Ok(true,"");
        }
    }

    /// <summary>
    /// حدث الموافقة على مراجعة
    /// Review approved event
    /// </summary>
    public class ReviewApprovedEvent
    {
        public Guid ReviewId { get; set; }
        public Guid ApprovedBy { get; set; }
        public DateTime ApprovedAt { get; set; }
    }
} 