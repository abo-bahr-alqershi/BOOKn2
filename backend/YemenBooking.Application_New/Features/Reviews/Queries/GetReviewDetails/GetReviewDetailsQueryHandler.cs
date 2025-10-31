using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Reviews;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reviews.Queries.GetReviewDetails
{
    /// <summary>
    /// معالج استعلام تفاصيل تقييم واحد
    /// </summary>
    public class GetReviewDetailsQueryHandler : IRequestHandler<GetReviewDetailsQuery, ResultDto<AdminReviewDetailsDto>>
    {
        private readonly IReviewRepository _reviewRepository;
        private readonly ICurrentUserService _currentUserService;

        public GetReviewDetailsQueryHandler(
            IReviewRepository reviewRepository,
            ICurrentUserService currentUserService)
        {
            _reviewRepository = reviewRepository;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<AdminReviewDetailsDto>> Handle(GetReviewDetailsQuery request, CancellationToken cancellationToken)
        {
            if (request.ReviewId == Guid.Empty)
                return ResultDto<AdminReviewDetailsDto>.Failed("معرّف التقييم مطلوب");

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
                return ResultDto<AdminReviewDetailsDto>.Failed("غير مصرح لك");

            var review = await _reviewRepository
                .GetQueryable()
                .AsNoTracking()
                .Include(r => r.Images)
                .Include(r => r.Booking)
                    .ThenInclude(b => b.Unit)
                        .ThenInclude(u => u.Property)
                .Include(r => r.Booking)
                    .ThenInclude(b => b.User)
                .FirstOrDefaultAsync(r => r.Id == request.ReviewId, cancellationToken);

            if (review == null)
                return ResultDto<AdminReviewDetailsDto>.Failed("التقييم غير موجود");

            // RBAC: Admin unrestricted; Owner only if review belongs to their property
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            var isOwnerAuthorized = _currentUserService.PropertyId.HasValue && _currentUserService.PropertyId.Value == review.PropertyId;
            if (!(isAdmin || isOwnerAuthorized))
                return ResultDto<AdminReviewDetailsDto>.Failed("غير مصرح لك");

            var dto = new AdminReviewDetailsDto
            {
                Id = review.Id,
                BookingId = review.BookingId,
                PropertyId = review.PropertyId,
                UnitId = review.Booking?.UnitId,
                Cleanliness = review.Cleanliness,
                Service = review.Service,
                Location = review.Location,
                Value = review.Value,
                AverageRating = review.AverageRating,
                Comment = review.Comment,
                CreatedAt = review.CreatedAt,
                IsApproved = !review.IsPendingApproval,
                IsPending = review.IsPendingApproval,
                ResponseText = review.ResponseText,
                ResponseDate = review.ResponseDate,
                RespondedBy = review.UpdatedBy,
                Images = review.Images.Select(img => new ReviewImageDto
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
                }).ToList(),
                PropertyName = review.Booking?.Unit?.Property?.Name ?? string.Empty,
                UnitName = review.Booking?.Unit?.Name,
                PropertyCity = review.Booking?.Unit?.Property?.City,
                PropertyAddress = review.Booking?.Unit?.Property?.Address,
                UserName = review.Booking?.User?.Name ?? string.Empty,
                UserEmail = review.Booking?.User?.Email,
                UserPhone = review.Booking?.User?.Phone,
                BookingCheckIn = review.Booking?.CheckIn,
                BookingCheckOut = review.Booking?.CheckOut,
                GuestsCount = review.Booking?.GuestsCount,
                BookingStatus = review.Booking?.Status.ToString(),
                BookingSource = review.Booking?.BookingSource,
            };

            // Localize timestamps for client
            dto.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.CreatedAt);
            if (dto.ResponseDate.HasValue)
                dto.ResponseDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.ResponseDate.Value);
            if (dto.Images != null)
                for (int i = 0; i < dto.Images.Count; i++)
                    dto.Images[i].UploadedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.Images[i].UploadedAt);
            if (dto.BookingCheckIn.HasValue)
                dto.BookingCheckIn = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.BookingCheckIn.Value);
            if (dto.BookingCheckOut.HasValue)
                dto.BookingCheckOut = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.BookingCheckOut.Value);

            return ResultDto<AdminReviewDetailsDto>.Ok(dto);
        }
    }
}

