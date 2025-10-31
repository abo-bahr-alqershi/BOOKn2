using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetImageById
{
    /// <summary>
    /// معالج استعلام الحصول على صورة واحدة بواسطة المعرف
    /// Handler for GetImageByIdQuery to retrieve a single image by its ID
    /// </summary>
    public class GetImageByIdQueryHandler : IRequestHandler<GetImageByIdQuery, ResultDto<ImageDto>>
    {
        private readonly IPropertyImageRepository _imageRepository;
        private readonly ISectionImageRepository _sectionImageRepository;
        private readonly IPropertyInSectionImageRepository _propertyInSectionImageRepository;
        private readonly IUnitInSectionImageRepository _unitInSectionImageRepository;
        private readonly ICurrentUserService _currentUserService;

        public GetImageByIdQueryHandler(
            IPropertyImageRepository imageRepository,
            ISectionImageRepository sectionImageRepository,
            IPropertyInSectionImageRepository propertyInSectionImageRepository,
            IUnitInSectionImageRepository unitInSectionImageRepository,
            ICurrentUserService currentUserService)
        {
            _imageRepository = imageRepository;
            _sectionImageRepository = sectionImageRepository;
            _propertyInSectionImageRepository = propertyInSectionImageRepository;
            _unitInSectionImageRepository = unitInSectionImageRepository;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<ImageDto>> Handle(GetImageByIdQuery request, CancellationToken cancellationToken)
        {
            // جلب الصورة من المستودعات الخاصة أولاً للحفاظ على الدلالات الجديدة
            var s = await _sectionImageRepository.GetByIdAsync(request.ImageId, cancellationToken);
            if (s != null) return ResultDto<ImageDto>.Ok(ToDto(s));
            var pis = await _propertyInSectionImageRepository.GetByIdAsync(request.ImageId, cancellationToken);
            if (pis != null) return ResultDto<ImageDto>.Ok(ToDto(pis));
            var uis = await _unitInSectionImageRepository.GetByIdAsync(request.ImageId, cancellationToken);
            if (uis != null) return ResultDto<ImageDto>.Ok(ToDto(uis));
            var image = await _imageRepository.GetPropertyImageByIdAsync(request.ImageId, cancellationToken);
            if (image == null)
                return ResultDto<ImageDto>.Failure("الصورة غير موجودة");

            // تحويل الكيان إلى DTO
            var dto = new ImageDto
            {
                Id = image.Id,
                Url = image.Url,
                Filename = image.Name,
                Size = image.SizeBytes,
                MimeType = image.Type,
                Width = 0,
                Height = 0,
                Alt = image.AltText,
                UploadedAt = image.UploadedAt,
                UploadedBy = image.CreatedBy ?? Guid.Empty,
                Order = image.DisplayOrder,
                IsPrimary = image.IsMain,
                PropertyId = image.PropertyId,
                UnitId = image.UnitId,
                Category = image.Category,
                Tags = string.IsNullOrWhiteSpace(image.Tags)
                    ? new List<string>()
                    : JsonSerializer.Deserialize<List<string>>(image.Tags)!,
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

            dto.UploadedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.UploadedAt);
            return ResultDto<ImageDto>.Ok(dto);
        }

        private ImageDto ToDto(Core.Entities.SectionImage i)
        {
            var dto = new ImageDto
            {
                Id = i.Id,
                Url = i.Url,
                Filename = i.Name,
                Size = i.SizeBytes,
                MimeType = i.Type,
                Width = 0,
                Height = 0,
                Alt = i.AltText,
                UploadedAt = i.UploadedAt,
                UploadedBy = i.CreatedBy ?? Guid.Empty,
                Order = i.DisplayOrder,
                IsPrimary = i.IsMainImage,
                Category = i.Category,
                Tags = string.IsNullOrWhiteSpace(i.Tags) ? new List<string>() : System.Text.Json.JsonSerializer.Deserialize<List<string>>(i.Tags) ?? new List<string>(),
                ProcessingStatus = i.Status.ToString(),
                Thumbnails = new ImageThumbnailsDto { Small = i.Sizes ?? string.Empty, Medium = i.Sizes ?? string.Empty, Large = i.Sizes ?? string.Empty, Hd = i.Sizes ?? string.Empty },
                MediaType = string.IsNullOrWhiteSpace(i.MediaType) ? "image" : i.MediaType,
                Duration = i.DurationSeconds,
                VideoThumbnail = string.IsNullOrWhiteSpace(i.VideoThumbnailUrl) ? null : i.VideoThumbnailUrl
            };
            dto.UploadedAt = _currentUserService.ConvertFromUtcToUserLocalAsync(dto.UploadedAt).GetAwaiter().GetResult();
            return dto;
        }

        private ImageDto ToDto(Core.Entities.PropertyInSectionImage i)
        {
            var dto = new ImageDto
            {
                Id = i.Id,
                Url = i.Url,
                Filename = i.Name,
                Size = i.SizeBytes,
                MimeType = i.Type,
                Width = 0,
                Height = 0,
                Alt = i.AltText,
                UploadedAt = i.UploadedAt,
                UploadedBy = i.CreatedBy ?? Guid.Empty,
                Order = i.DisplayOrder,
                IsPrimary = i.IsMainImage,
                Category = i.Category,
                Tags = string.IsNullOrWhiteSpace(i.Tags) ? new List<string>() : System.Text.Json.JsonSerializer.Deserialize<List<string>>(i.Tags) ?? new List<string>(),
                ProcessingStatus = i.Status.ToString(),
                Thumbnails = new ImageThumbnailsDto { Small = i.Sizes ?? string.Empty, Medium = i.Sizes ?? string.Empty, Large = i.Sizes ?? string.Empty, Hd = i.Sizes ?? string.Empty },
                MediaType = string.IsNullOrWhiteSpace(i.MediaType) ? "image" : i.MediaType,
                Duration = i.DurationSeconds,
                VideoThumbnail = string.IsNullOrWhiteSpace(i.VideoThumbnailUrl) ? null : i.VideoThumbnailUrl
            };
            dto.UploadedAt = _currentUserService.ConvertFromUtcToUserLocalAsync(dto.UploadedAt).GetAwaiter().GetResult();
            return dto;
        }

        private ImageDto ToDto(Core.Entities.UnitInSectionImage i)
        {
            var dto = new ImageDto
            {
                Id = i.Id,
                Url = i.Url,
                Filename = i.Name,
                Size = i.SizeBytes,
                MimeType = i.Type,
                Width = 0,
                Height = 0,
                Alt = i.AltText,
                UploadedAt = i.UploadedAt,
                UploadedBy = i.CreatedBy ?? Guid.Empty,
                Order = i.DisplayOrder,
                IsPrimary = i.IsMainImage,
                Category = i.Category,
                Tags = string.IsNullOrWhiteSpace(i.Tags) ? new List<string>() : System.Text.Json.JsonSerializer.Deserialize<List<string>>(i.Tags) ?? new List<string>(),
                ProcessingStatus = i.Status.ToString(),
                Thumbnails = new ImageThumbnailsDto { Small = i.Sizes ?? string.Empty, Medium = i.Sizes ?? string.Empty, Large = i.Sizes ?? string.Empty, Hd = i.Sizes ?? string.Empty },
                MediaType = string.IsNullOrWhiteSpace(i.MediaType) ? "image" : i.MediaType,
                Duration = i.DurationSeconds,
                VideoThumbnail = string.IsNullOrWhiteSpace(i.VideoThumbnailUrl) ? null : i.VideoThumbnailUrl
            };
            dto.UploadedAt = _currentUserService.ConvertFromUtcToUserLocalAsync(dto.UploadedAt).GetAwaiter().GetResult();
            return dto;
        }
    }
} 