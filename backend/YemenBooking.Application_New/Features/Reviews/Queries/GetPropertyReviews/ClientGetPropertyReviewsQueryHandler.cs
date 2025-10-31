using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reviews.Queries.GetPropertyReviews;

/// <summary>
/// معالج استعلام الحصول على تقييمات العقار للعميل
/// Handler for client get property reviews query
/// </summary>
public class ClientGetPropertyReviewsQueryHandler : IRequestHandler<ClientGetPropertyReviewsQuery, ResultDto<PaginatedResult<ClientReviewDto>>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;

    public ClientGetPropertyReviewsQueryHandler(IUnitOfWork unitOfWork, ICurrentUserService currentUserService)
    {
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة استعلام الحصول على تقييمات العقار
    /// Handle get property reviews query
    /// </summary>
    /// <param name="request">الطلب</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة مُقسمة من التقييمات</returns>
    public async Task<ResultDto<PaginatedResult<ClientReviewDto>>> Handle(ClientGetPropertyReviewsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            var reviewRepo = _unitOfWork.Repository<Core.Entities.Review>();
            var query = reviewRepo.GetQueryable()
                .AsNoTracking()
                .Include(r => r.Booking)
                .Include(r => r.Images)
                .Where(r => r.PropertyId == request.PropertyId);

            // تطبيق الفلاتر
            // Apply filters
            if (request.Rating.HasValue)
            {
                query = query.Where(r => r.AverageRating >= request.Rating.Value);
            }

            if (request.WithImagesOnly)
            {
                query = query.Where(r => r.Images != null && r.Images.Any());
            }

            // الترتيب
            // Ordering
            query = request.SortBy?.ToLower() switch
            {
                "rating" => request.SortDirection?.ToLower() == "asc" 
                    ? query.OrderBy(r => r.AverageRating) 
                    : query.OrderByDescending(r => r.AverageRating),
                "date" => request.SortDirection?.ToLower() == "asc" 
                    ? query.OrderBy(r => r.CreatedAt) 
                    : query.OrderByDescending(r => r.CreatedAt),
                _ => query.OrderByDescending(r => r.CreatedAt)
            };

            // التحويل إلى DTO
            // Convert to DTO
            var reviewDtos = query.Select(r => new ClientReviewDto
            {
                Id = r.Id,
                Rating = (int)Math.Round(r.AverageRating),
                Comment = r.Comment,
                CreatedAt = r.CreatedAt,
                Images = r.Images != null ? r.Images.Select(img => new ClientReviewImageDto
                {
                    Id = img.Id,
                    Url = img.Url,
                    Caption = img.Caption
                }).ToList() : new List<ClientReviewImageDto>(),
                // الخصائص الأخرى يمكن إضافتها عند الحاجة
                UserName = r.Booking != null && r.Booking.User != null ? r.Booking.User.Name : "مستخدم مجهول",
                Title = "", // إذا كان موجود في النموذج
                IsUserReview = request.UserId.HasValue && r.Booking != null && r.Booking.UserId == request.UserId,
                LikesCount = 0, // يمكن إضافته لاحقاً
                IsLikedByUser = false,
                ManagementReply = !string.IsNullOrEmpty(r.ResponseText) ? new ClientReviewReplyDto
                {
                    Id = Guid.NewGuid(),
                    Content = r.ResponseText,
                    CreatedAt = r.ResponseDate.HasValue ? r.ResponseDate.Value : DateTime.UtcNow,
                    ReplierName = "إدارة العقار",
                    ReplierPosition = "ممثل خدمة العملاء"
                } : null,
                BookingType = "Standard",
                IsRecommended = r.AverageRating >= 4
            }).ToList();

            // Localize CreatedAt and ManagementReply.CreatedAt
            for (int i = 0; i < reviewDtos.Count; i++)
            {
                reviewDtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(reviewDtos[i].CreatedAt);
                if (reviewDtos[i].ManagementReply != null)
                {
                    reviewDtos[i].ManagementReply.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(reviewDtos[i].ManagementReply.CreatedAt);
                }
            }

            // التقسيم
            // Pagination
            var totalCount = reviewDtos.Count;
            var items = reviewDtos
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToList();

            return ResultDto<PaginatedResult<ClientReviewDto>>.SuccessResult(new PaginatedResult<ClientReviewDto>
            {
                Items = items,
                TotalCount = totalCount,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize
            });
        }
        catch (Exception)
        {
            return ResultDto<PaginatedResult<ClientReviewDto>>.Failure("حدث خطأ أثناء جلب التقييمات");
        }
    }
}