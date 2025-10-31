using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Reviews;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Reviews.Commands.Review
{
    /// <summary>
    /// معالج أمر حذف تقييم
    /// </summary>
    public class DeleteReviewCommandHandler : IRequestHandler<DeleteReviewCommand, ResultDto<bool>>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly IUnitRepository _unitRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<DeleteReviewCommandHandler> _logger;
        private readonly IMediator _mediator;
        private readonly IIndexingService _indexingService;

        public DeleteReviewCommandHandler(
            IReviewRepository reviewRepository,
            IUnitRepository unitRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<DeleteReviewCommandHandler> logger,
            IMediator mediator,
            IIndexingService indexingService)
        {
            _reviewRepository = reviewRepository;
            _unitRepository = unitRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _mediator = mediator;
            _indexingService = indexingService;
        }

        public async Task<ResultDto<bool>> Handle(DeleteReviewCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء حذف التقييم: ReviewId={ReviewId}", request.ReviewId);

            // التحقق من المدخلات
            if (request.ReviewId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف التقييم مطلوب");

            // التحقق من الوجود
            var review = await _reviewRepository.GetReviewByIdAsync(request.ReviewId, cancellationToken);
            if (review == null)
                return ResultDto<bool>.Failed("التقييم غير موجود");

            // التحقق من الصلاحيات: فقط المشرف يمكنه الحذف
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            if (!isAdmin)
                return ResultDto<bool>.Failed("غير مصرح لك بحذف هذا التقييم");

            // تنفيذ الحذف
            bool deleted = await _reviewRepository.DeleteReviewAsync(request.ReviewId, cancellationToken);
            if (!deleted)
                return ResultDto<bool>.Failed("فشل حذف التقييم");

            // تسجيل التدقيق (يدوي) يتضمن اسم ومعرّف المنفذ
            var notes = $"تم حذف التقييم {request.ReviewId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "Review",
                entityId: request.ReviewId,
                action: AuditAction.DELETE,
                oldValues: System.Text.Json.JsonSerializer.Serialize(new { request.ReviewId }),
                newValues: null,
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            // Update property average rating
            var bookingEntity = await _reviewRepository.GetBookingByIdAsync(review.BookingId, cancellationToken);
            if (bookingEntity != null)
            {
                var unit = await _unitRepository.GetUnitByIdAsync(bookingEntity.UnitId, cancellationToken);
                if (unit != null)
                {
                    var propertyId = unit.PropertyId;
                    var (avgRating, totalReviews) = await _reviewRepository.GetPropertyRatingStatsAsync(propertyId, cancellationToken);
                    var property = await _propertyRepository.GetPropertyByIdAsync(propertyId, cancellationToken);
                    if (property != null)
                    {
                        property.AverageRating = (decimal)avgRating;
                        await _propertyRepository.UpdatePropertyAsync(property, cancellationToken);

                        // تحديث مباشر لفهرس العقار
                        try
                        {
                            await _indexingService.OnPropertyUpdatedAsync(property.Id, cancellationToken);
                        }
                        catch (Exception ex)
                        {
                            _logger.LogWarning(ex, "تعذرت الفهرسة المباشرة للعقار بعد حذف التقييم {PropertyId}", property.Id);
                        }
                    }
                }
            }

            _logger.LogInformation("اكتمل حذف التقييم بنجاح: ReviewId={ReviewId}", request.ReviewId);
            return ResultDto<bool>.Succeeded(true, "تم حذف التقييم بنجاح");
        }
    }
} 