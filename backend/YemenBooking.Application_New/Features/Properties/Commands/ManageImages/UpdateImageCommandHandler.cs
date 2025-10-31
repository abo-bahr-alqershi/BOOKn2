using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using System.Collections.Generic;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// معالج أمر تحديث بيانات الصورة
    /// Handler for UpdateImageCommand to update image metadata
    /// </summary>
    public class UpdateImageCommandHandler : IRequestHandler<UpdateImageCommand, ResultDto<ImageDto>>
    {
        private readonly IPropertyImageRepository _imageRepository;
        private readonly ISectionImageRepository _sectionImageRepository;
        private readonly IPropertyInSectionImageRepository _propertyInSectionImageRepository;
        private readonly IUnitInSectionImageRepository _unitInSectionImageRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;

        public UpdateImageCommandHandler(
            IPropertyImageRepository imageRepository,
            ISectionImageRepository sectionImageRepository,
            IPropertyInSectionImageRepository propertyInSectionImageRepository,
            IUnitInSectionImageRepository unitInSectionImageRepository,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService)
        {
            _imageRepository = imageRepository;
            _sectionImageRepository = sectionImageRepository;
            _propertyInSectionImageRepository = propertyInSectionImageRepository;
            _unitInSectionImageRepository = unitInSectionImageRepository;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<ImageDto>> Handle(UpdateImageCommand request, CancellationToken cancellationToken)
        {
            // جلب الصورة الحالية (تحقق في الجداول المتخصصة أولاً)
            var s = await _sectionImageRepository.GetByIdAsync(request.ImageId, cancellationToken);
            var pis = s == null ? await _propertyInSectionImageRepository.GetByIdAsync(request.ImageId, cancellationToken) : null;
            var uis = (s == null && pis == null) ? await _unitInSectionImageRepository.GetByIdAsync(request.ImageId, cancellationToken) : null;
            var image = (s == null && pis == null && uis == null) ? await _imageRepository.GetPropertyImageByIdAsync(request.ImageId, cancellationToken) : null;
            if (s == null && pis == null && uis == null && image == null)
                return ResultDto<ImageDto>.Failure("الصورة غير موجودة");

            // تحديث الحقول
            void UpdateCommon<T>(T x) where T : class
            {
                dynamic d = x!;
                if (request.Alt != null) d.AltText = request.Alt;
                if (request.IsPrimary.HasValue) d.IsMainImage = request.IsPrimary.Value;
                if (request.Order.HasValue) d.DisplayOrder = request.Order.Value;
                if (request.Tags != null) d.Tags = System.Text.Json.JsonSerializer.Serialize(request.Tags);
                if (request.Category.HasValue) d.Category = request.Category.Value;
            }
            if (s != null) UpdateCommon(s);
            else if (pis != null) UpdateCommon(pis);
            else if (uis != null) UpdateCommon(uis);
            else if (image != null)
            {
                if (request.Alt != null) image.AltText = request.Alt;
                if (request.IsPrimary.HasValue) image.IsMain = request.IsPrimary.Value;
                if (request.Order.HasValue) image.DisplayOrder = request.Order.Value;
                if (request.Tags != null) image.Tags = System.Text.Json.JsonSerializer.Serialize(request.Tags);
                if (request.Category.HasValue) image.Category = request.Category.Value;
            }

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                if (s != null) await _sectionImageRepository.UpdateAsync(s, cancellationToken);
                else if (pis != null) await _propertyInSectionImageRepository.UpdateAsync(pis, cancellationToken);
                else if (uis != null) await _unitInSectionImageRepository.UpdateAsync(uis, cancellationToken);
                else if (image != null) await _imageRepository.UpdatePropertyImageAsync(image, cancellationToken);
            }, cancellationToken);

            // تحويل إلى DTO (أعد الحقول الزمنية للمستخدم بالتوقيت المحلي إن لزم)
            ImageDto dto;
            if (s != null)
            {
                var uploadedLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(s.UploadedAt);
                dto = new ImageDto
                {
                    Id = s.Id,
                    Url = s.Url,
                    Filename = System.IO.Path.GetFileName(new Uri(s.Url).LocalPath),
                    Size = s.SizeBytes,
                    MimeType = s.Type,
                    Width = 0,
                    Height = 0,
                    Alt = s.AltText,
                    UploadedAt = uploadedLocal,
                    UploadedBy = s.CreatedBy ?? Guid.Empty,
                    Order = s.DisplayOrder,
                    IsPrimary = s.IsMainImage,
                    Category = s.Category,
                    Tags = System.Text.Json.JsonSerializer.Deserialize<List<string>>(s.Tags) ?? new List<string>(),
                    ProcessingStatus = s.Status.ToString(),
                    Thumbnails = new ImageThumbnailsDto { Small = s.Sizes ?? string.Empty, Medium = s.Sizes ?? string.Empty, Large = s.Sizes ?? string.Empty, Hd = s.Sizes ?? string.Empty },
                    MediaType = string.IsNullOrWhiteSpace(s.MediaType) ? "image" : s.MediaType,
                    Duration = s.DurationSeconds,
                    VideoThumbnail = string.IsNullOrWhiteSpace(s.VideoThumbnailUrl) ? null : s.VideoThumbnailUrl
                };
            }
            else if (pis != null)
            {
                var uploadedLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(pis.UploadedAt);
                dto = new ImageDto
                {
                    Id = pis.Id,
                    Url = pis.Url,
                    Filename = System.IO.Path.GetFileName(new Uri(pis.Url).LocalPath),
                    Size = pis.SizeBytes,
                    MimeType = pis.Type,
                    Width = 0,
                    Height = 0,
                    Alt = pis.AltText,
                    UploadedAt = uploadedLocal,
                    UploadedBy = pis.CreatedBy ?? Guid.Empty,
                    Order = pis.DisplayOrder,
                    IsPrimary = pis.IsMainImage,
                    Category = pis.Category,
                    Tags = System.Text.Json.JsonSerializer.Deserialize<List<string>>(pis.Tags) ?? new List<string>(),
                    ProcessingStatus = pis.Status.ToString(),
                    Thumbnails = new ImageThumbnailsDto { Small = pis.Sizes ?? string.Empty, Medium = pis.Sizes ?? string.Empty, Large = pis.Sizes ?? string.Empty, Hd = pis.Sizes ?? string.Empty },
                    MediaType = string.IsNullOrWhiteSpace(pis.MediaType) ? "image" : pis.MediaType,
                    Duration = pis.DurationSeconds,
                    VideoThumbnail = string.IsNullOrWhiteSpace(pis.VideoThumbnailUrl) ? null : pis.VideoThumbnailUrl
                };
            }
            else if (uis != null)
            {
                var uploadedLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(uis.UploadedAt);
                dto = new ImageDto
                {
                    Id = uis.Id,
                    Url = uis.Url,
                    Filename = System.IO.Path.GetFileName(new Uri(uis.Url).LocalPath),
                    Size = uis.SizeBytes,
                    MimeType = uis.Type,
                    Width = 0,
                    Height = 0,
                    Alt = uis.AltText,
                    UploadedAt = uploadedLocal,
                    UploadedBy = uis.CreatedBy ?? Guid.Empty,
                    Order = uis.DisplayOrder,
                    IsPrimary = uis.IsMainImage,
                    Category = uis.Category,
                    Tags = System.Text.Json.JsonSerializer.Deserialize<List<string>>(uis.Tags) ?? new List<string>(),
                    ProcessingStatus = uis.Status.ToString(),
                    Thumbnails = new ImageThumbnailsDto { Small = uis.Sizes ?? string.Empty, Medium = uis.Sizes ?? string.Empty, Large = uis.Sizes ?? string.Empty, Hd = uis.Sizes ?? string.Empty },
                    MediaType = string.IsNullOrWhiteSpace(uis.MediaType) ? "image" : uis.MediaType,
                    Duration = uis.DurationSeconds,
                    VideoThumbnail = string.IsNullOrWhiteSpace(uis.VideoThumbnailUrl) ? null : uis.VideoThumbnailUrl
                };
            }
            else
            {
                var uploadedLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(image.UploadedAt);
                dto = new ImageDto
            {
                Id = image.Id,
                Url = image.Url,
                // extract filename from URL
                Filename = System.IO.Path.GetFileName(new Uri(image.Url).LocalPath),
                Size = image.SizeBytes,
                MimeType = image.Type,
                Width = 0,
                Height = 0,
                Alt = image.AltText,
                UploadedAt = uploadedLocal,
                UploadedBy = image.CreatedBy ?? Guid.Empty,
                Order = image.DisplayOrder,
                IsPrimary = image.IsMain,
                PropertyId = image.PropertyId,
                UnitId = image.UnitId,
                Category = image.Category,
                Tags = System.Text.Json.JsonSerializer.Deserialize<List<string>>(image.Tags) ?? new List<string>(),
                ProcessingStatus = image.Status.ToString(),
                Thumbnails = new ImageThumbnailsDto
                {
                    Small = image.Sizes,
                    Medium = image.Sizes,
                    Large = image.Sizes,
                    Hd = image.Sizes
                },
                MediaType = string.IsNullOrWhiteSpace(image.MediaType)
                    ? ((image.Type?.StartsWith("video/", StringComparison.OrdinalIgnoreCase) ?? false) ? "video" : "image")
                    : image.MediaType,
                Duration = image.DurationSeconds,
                VideoThumbnail = string.IsNullOrWhiteSpace(image.VideoThumbnailUrl) ? null : image.VideoThumbnailUrl
            };

            }
            return ResultDto<ImageDto>.Ok(dto);
        }
    }
} 