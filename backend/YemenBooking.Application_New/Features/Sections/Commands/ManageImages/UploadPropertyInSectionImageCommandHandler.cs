using System;
using System.IO;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Sections.Commands.ManageImages
{
    public class UploadPropertyInSectionImageCommandHandler : IRequestHandler<UploadPropertyInSectionImageCommand, ResultDto<ImageDto>>
    {
        private readonly IFileStorageService _fileStorageService;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UploadPropertyInSectionImageCommandHandler> _logger;
        private readonly IPropertyInSectionImageRepository _repository;

        public UploadPropertyInSectionImageCommandHandler(
            IFileStorageService fileStorageService,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<UploadPropertyInSectionImageCommandHandler> logger,
            IPropertyInSectionImageRepository repository)
        {
            _fileStorageService = fileStorageService;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _repository = repository;
        }

        public async Task<ResultDto<ImageDto>> Handle(UploadPropertyInSectionImageCommand request, CancellationToken cancellationToken)
        {
            var folderPath = string.IsNullOrWhiteSpace(request.TempKey)
                ? (request.PropertyInSectionId.HasValue ? $"section-items/{request.PropertyInSectionId}" : "temp")
                : $"temp/{request.TempKey}";
            var stream = new MemoryStream(request.File.FileContent);
            var fileName = request.Name + request.Extension;
            var upload = await _fileStorageService.UploadFileAsync(stream, fileName, request.File.ContentType, folderPath, cancellationToken);
            if (!upload.IsSuccess || string.IsNullOrWhiteSpace(upload.FileUrl))
                return ResultDto<ImageDto>.Failed("فشل رفع الملف");

            var notes = $"تم رفع صورة عنصر قسم بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: nameof(PropertyInSectionImage),
                entityId: request.PropertyInSectionId ?? Guid.Empty,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new { request.Name, Category = request.Category.ToString(), IsPrimary = request.IsPrimary ?? false, Order = request.Order ?? 0 }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            var thumbnails = new ImageThumbnailsDto { Small = upload.FileUrl!, Medium = upload.FileUrl!, Large = upload.FileUrl!, Hd = upload.FileUrl! };

            // Normalize timestamps: persist UTC, return DTO in user-local
            var uploadedUtc = upload.UploadedAt == default ? DateTime.UtcNow : upload.UploadedAt;
            var uploadedLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(uploadedUtc);

            // Prefer FK when provided; only use TempKey when FK is not supplied
            var boundPropertyInSectionId = request.PropertyInSectionId;

            var entity = new PropertyInSectionImage
            {
                Id = Guid.NewGuid(),
                PropertyInSectionId = boundPropertyInSectionId,
                TempKey = string.IsNullOrWhiteSpace(request.TempKey) ? null : request.TempKey,
                Name = fileName,
                Url = upload.FileUrl!,
                SizeBytes = upload.FileSizeBytes,
                Type = request.File.ContentType,
                Category = request.Category,
                Caption = request.Alt ?? string.Empty,
                AltText = request.Alt ?? string.Empty,
                Tags = JsonSerializer.Serialize(request.Tags ?? new System.Collections.Generic.List<string>()),
                Sizes = thumbnails.Medium,
                IsMainImage = request.IsPrimary ?? false,
                DisplayOrder = request.Order ?? 0,
                Status = ImageStatus.Approved,
                UploadedAt = uploadedUtc,
                CreatedBy = _currentUserService.UserId,
                UpdatedAt = uploadedUtc,
                MediaType = (request.File.ContentType?.StartsWith("video/", StringComparison.OrdinalIgnoreCase) ?? false) ? "video" : "image",
                DurationSeconds = null,
                VideoThumbnailUrl = null
            };

            if (request.VideoThumbnail != null)
            {
                var posterUpload = await _fileStorageService.UploadFileAsync(
                    request.VideoThumbnail.FileContent,
                    request.VideoThumbnail.FileName,
                    request.VideoThumbnail.ContentType,
                    folderPath,
                    cancellationToken);
                if (posterUpload.IsSuccess && !string.IsNullOrWhiteSpace(posterUpload.FileUrl))
                {
                    entity.VideoThumbnailUrl = posterUpload.FileUrl;
                    entity.MediaType = "video";
                }
            }

            await _repository.CreateAsync(entity, cancellationToken);

            var dto = new ImageDto
            {
                Id = entity.Id,
                Url = entity.Url,
                Filename = entity.Name,
                Size = entity.SizeBytes,
                MimeType = entity.Type,
                Width = 0,
                Height = 0,
                Alt = entity.AltText,
                UploadedAt = uploadedLocal,
                UploadedBy = entity.CreatedBy ?? Guid.Empty,
                Order = entity.DisplayOrder,
                IsPrimary = entity.IsMainImage,
                Category = entity.Category,
                Tags = string.IsNullOrWhiteSpace(entity.Tags) ? new System.Collections.Generic.List<string>() : JsonSerializer.Deserialize<System.Collections.Generic.List<string>>(entity.Tags) ?? new System.Collections.Generic.List<string>(),
                ProcessingStatus = entity.Status.ToString(),
                Thumbnails = thumbnails,
                MediaType = entity.MediaType,
                Duration = entity.DurationSeconds,
                VideoThumbnail = entity.VideoThumbnailUrl
            };

            return ResultDto<ImageDto>.Ok(dto);
        }
    }
}

