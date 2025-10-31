using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reviews.Queries.GetAllReviews
{
    /// <summary>
    /// معالج استعلام جلب جميع التقييمات مع دعم التصفية
    /// Handler for GetAllReviewsQuery
    /// </summary>
    public class GetAllReviewsQueryHandler : IRequestHandler<GetAllReviewsQuery, PaginatedResult<ReviewDto>>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetAllReviewsQueryHandler> _logger;

        public GetAllReviewsQueryHandler(
            IReviewRepository reviewRepository,
            ICurrentUserService currentUserService,
            ILogger<GetAllReviewsQueryHandler> logger)
        {
            _reviewRepository = reviewRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<PaginatedResult<ReviewDto>> Handle(GetAllReviewsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Processing GetAllReviewsQuery");

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                throw new UnauthorizedAccessException("ليس لديك صلاحية لعرض التقييمات");
            }

            var query = _reviewRepository.GetQueryable()
                .AsNoTracking()
                .Include(r => r.Images)
                .Include(r => r.Booking)
                    .ThenInclude(b => b.Unit)
                        .ThenInclude(u => u.Property)
                .Include(r => r.Booking)
                    .ThenInclude(b => b.User)
                .AsQueryable();

            // RBAC: Admin unrestricted, Owner restricted to own property
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || ((_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false));
            var isOwner = string.Equals(_currentUserService.Role, "Owner", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Owner", StringComparison.OrdinalIgnoreCase)
                || ((_currentUserService.UserRoles?.Any(r => string.Equals(r, "Owner", StringComparison.OrdinalIgnoreCase)) ?? false));

            if (!isAdmin)
            {
                if (isOwner)
                {
                    // Owner can only see reviews of own property
                    query = query.Where(r => r.Booking.Unit.Property.OwnerId == _currentUserService.UserId);

                    // If PropertyId supplied, enforce it; else if bound in current user, default to it
                    if (request.PropertyId.HasValue && request.PropertyId.Value != Guid.Empty)
                    {
                        query = query.Where(r => r.Booking.Unit.PropertyId == request.PropertyId.Value);
                    }
                    else if (_currentUserService.PropertyId.HasValue && _currentUserService.PropertyId.Value != Guid.Empty)
                    {
                        var ownerPropId = _currentUserService.PropertyId.Value;
                        query = query.Where(r => r.Booking.Unit.PropertyId == ownerPropId);
                    }
                }
                else
                {
                    throw new UnauthorizedAccessException("ليس لديك صلاحية لعرض التقييمات");
                }
            }

            if (!string.IsNullOrEmpty(request.Status) && request.Status != "all")
            {
                if (request.Status == "pending")
                    query = query.Where(r => r.IsPendingApproval);
                else if (request.Status == "approved")
                    query = query.Where(r => !r.IsPendingApproval);
                else if (request.Status == "rejected")
                    query = query.Where(r => false);
            }

            if (request.MinRating.HasValue)
                query = query.Where(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0 >= request.MinRating.Value);
            if (request.MaxRating.HasValue)
                query = query.Where(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0 <= request.MaxRating.Value);
            if (request.HasImages.HasValue)
                query = request.HasImages.Value
                    ? query.Where(r => r.Images.Any())
                    : query.Where(r => !r.Images.Any());
            if (request.PropertyId.HasValue)
                query = query.Where(r => r.Booking.Unit.PropertyId == request.PropertyId.Value);

            // تصفية حسب معرف الوحدة
            // Filter by unit Id
            if (request.UnitId.HasValue)
                query = query.Where(r => r.Booking.UnitId == request.UnitId.Value);

            if (request.UserId.HasValue)
                query = query.Where(r => r.Booking.UserId == request.UserId.Value);
            // Normalize date filters (local -> UTC)
            if (request.ReviewedAfter.HasValue)
                request.ReviewedAfter = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.ReviewedAfter.Value);
            if (request.ReviewedBefore.HasValue)
                request.ReviewedBefore = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.ReviewedBefore.Value);
            if (request.ReviewedAfter.HasValue)
                query = query.Where(r => r.CreatedAt >= request.ReviewedAfter.Value);
            if (request.ReviewedBefore.HasValue)
                query = query.Where(r => r.CreatedAt <= request.ReviewedBefore.Value);

            // Compute counts without materializing entire set
            var totalReviews = await query.CountAsync(cancellationToken);

            // Only compute aggregates when requested (first page or IncludeStats == true)
            var shouldIncludeStats = (request.IncludeStats == true) || ((request.IncludeStats ?? false) == false && (request.PageNumber ?? 1) == 1);

            int pendingReviews = 0;
            int approvedReviews = 0;
            int reviewsWithImages = 0;
            int reviewsWithResponses = 0;
            double averageRating = 0.0;
            double averageCleanliness = 0.0;
            double averageService = 0.0;
            double averageLocation = 0.0;
            double averageValue = 0.0;

            if (shouldIncludeStats && totalReviews > 0)
            {
                // Aggregate via single round-trip
                pendingReviews = await query.Where(r => r.IsPendingApproval).CountAsync(cancellationToken);
                approvedReviews = totalReviews - pendingReviews;
                reviewsWithImages = await query.Where(r => r.Images.Any()).CountAsync(cancellationToken);
                reviewsWithResponses = await query.Where(r => !string.IsNullOrWhiteSpace(r.ResponseText)).CountAsync(cancellationToken);

                // Averages
                averageRating = await query.AverageAsync(r => (double)r.AverageRating, cancellationToken);
                averageCleanliness = await query.AverageAsync(r => (double)r.Cleanliness, cancellationToken);
                averageService = await query.AverageAsync(r => (double)r.Service, cancellationToken);
                averageLocation = await query.AverageAsync(r => (double)r.Location, cancellationToken);
                averageValue = await query.AverageAsync(r => (double)r.Value, cancellationToken);
            }

            // Pagination defaults
            var pageNumber = (request.PageNumber ?? 1) < 1 ? 1 : (request.PageNumber ?? 1);
            var pageSize = (request.PageSize ?? 20) < 1 ? 20 : (request.PageSize ?? 20);

            var reviews = await query
                .OrderByDescending(r => r.CreatedAt)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var reviewDtos = reviews.Select(r => new ReviewDto
            {
                Id = r.Id,
                BookingId = r.BookingId,
                Cleanliness = r.Cleanliness,
                Service = r.Service,
                Location = r.Location,
                Value = r.Value,
                // متوسط التقييم المخزن
                AverageRating = r.AverageRating,
                Comment = r.Comment,
                CreatedAt = r.CreatedAt,
                IsApproved = !r.IsPendingApproval,
                IsPending = r.IsPendingApproval,
                RespondedBy = null,
                // Related property and user names (safe navigation)
                PropertyName = r.Booking?.Unit?.Property?.Name ?? string.Empty,
                UserName = r.Booking?.User?.Name ?? string.Empty,
                Images = r.Images.Select(img => new ReviewImageDto
                {
                    Id = img.Id,
                    ReviewId = img.ReviewId,
                    Name = img.Name,
                    Url = img.Url,
                    SizeBytes = img.SizeBytes,
                    Type = img.Type,
                    Category = img.Category,
                    Caption = img.Caption,
                    AltText = img.AltText,
                    UploadedAt = img.UploadedAt
                }).ToList()
            }).ToList();

            // Localize CreatedAt and image timestamps
            for (int i = 0; i < reviewDtos.Count; i++)
            {
                reviewDtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(reviewDtos[i].CreatedAt);
                if (reviewDtos[i].Images != null)
                {
                    for (int j = 0; j < reviewDtos[i].Images.Count; j++)
                    {
                        reviewDtos[i].Images[j].UploadedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(reviewDtos[i].Images[j].UploadedAt);
                    }
                }
            }

            var result = new PaginatedResult<ReviewDto>
            {
                Items = reviewDtos,
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalCount = totalReviews
            };
            
            // إضافة الإحصائيات في Metadata فقط في الصفحة الأولى
            if (shouldIncludeStats)
            {
                result.Metadata = new Dictionary<string, object>
                {
                    ["totalReviews"] = totalReviews,
                    ["pendingReviews"] = pendingReviews,
                    ["approvedReviews"] = approvedReviews,
                    ["reviewsWithImages"] = reviewsWithImages,
                    ["reviewsWithResponses"] = reviewsWithResponses,
                    ["averageRating"] = Math.Round(averageRating, 2),
                    ["averageCleanliness"] = Math.Round(averageCleanliness, 2),
                    ["averageService"] = Math.Round(averageService, 2),
                    ["averageLocation"] = Math.Round(averageLocation, 2),
                    ["averageValue"] = Math.Round(averageValue, 2)
                };
            }

            return result;
        }
    }
} 