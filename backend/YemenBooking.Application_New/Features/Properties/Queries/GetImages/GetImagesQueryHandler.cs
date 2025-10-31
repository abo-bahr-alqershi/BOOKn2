using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using System.Collections.Generic;
using YemenBooking.Core.Enums;
using System.Text.Json;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetImages
{
    /// <summary>
    /// معالج استعلام الحصول على قائمة الصور مع الفلاتر والصفحات
    /// Handler for GetImagesQuery to retrieve images list with filtering, sorting, and pagination
    /// </summary>
    public class GetImagesQueryHandler : IRequestHandler<GetImagesQuery, ResultDto<PaginatedResultDto<ImageDto>>>
    {
        private readonly IPropertyImageRepository _imageRepository;
        private readonly ICurrentUserService _currentUserService;

        public GetImagesQueryHandler(IPropertyImageRepository imageRepository, ICurrentUserService currentUserService)
        {
            _imageRepository = imageRepository;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<PaginatedResultDto<ImageDto>>> Handle(GetImagesQuery request, CancellationToken cancellationToken)
        {
            // 1. بناء الاستعلام مع الفلاتر
            var query = _imageRepository.GetQueryable().AsNoTracking();

            if (!string.IsNullOrWhiteSpace(request.TempKey))
                query = query.Where(i => i.TempKey == request.TempKey);

            if (request.PropertyId.HasValue && !request.UnitId.HasValue)
                query = query.Where(i => i.PropertyId == request.PropertyId.Value);
            if (request.UnitId.HasValue)
                query = query.Where(i => i.UnitId == request.UnitId.Value);
            if (request.SectionId.HasValue)
                query = query.Where(i => i.SectionId == request.SectionId.Value);
            if (request.PropertyInSectionId.HasValue)
                query = query.Where(i => i.PropertyInSectionId == request.PropertyInSectionId.Value);
            if (request.UnitInSectionId.HasValue)
                query = query.Where(i => i.UnitInSectionId == request.UnitInSectionId.Value);
            if (!string.IsNullOrWhiteSpace(request.CityName))
                query = query.Where(i => i.CityName == request.CityName);
            // Optional: support section-level images via SectionId when sent through TempKey/PropertyId alias at API layer
            // Backward compatibility: allow cityId alias mapped at API level
            if (request.Category.HasValue)
                query = query.Where(i => i.Category == request.Category.Value);
            if (!string.IsNullOrWhiteSpace(request.Search))
            {
                var term = request.Search.Trim().ToLower();
                query = query.Where(i => i.Name.ToLower().Contains(term)
                    || i.Caption.ToLower().Contains(term)
                    || i.AltText.ToLower().Contains(term)
                    || i.Tags.ToLower().Contains(term)
                    || i.Url.ToLower().Contains(term));
            }

            // 2. تطبيق الفرز
            var sortBy = request.SortBy?.Trim().ToLower();
            var ascending = string.Equals(request.SortOrder, "asc", StringComparison.OrdinalIgnoreCase);
            if (string.IsNullOrWhiteSpace(sortBy))
            {
                // Default: order by DisplayOrder then UploadedAt (ascending)
                query = query
                    .OrderBy(i => i.DisplayOrder)
                    .ThenBy(i => i.UploadedAt);
            }
            else
            {
                query = sortBy switch
                {
                    "uploadedat" => ascending ? query.OrderBy(i => i.UploadedAt) : query.OrderByDescending(i => i.UploadedAt),
                    "order" => ascending ? query.OrderBy(i => i.DisplayOrder) : query.OrderByDescending(i => i.DisplayOrder),
                    "filename" => ascending ? query.OrderBy(i => i.Name) : query.OrderByDescending(i => i.Name),
                    _ => query.OrderBy(i => i.DisplayOrder).ThenBy(i => i.UploadedAt),
                };
            }

            // 3. تطبيق الترقيم
            var page = request.Page.GetValueOrDefault(1);
            var limit = request.Limit.GetValueOrDefault(10);
            var totalCount = await query.CountAsync(cancellationToken);
            var items = await query.Skip((page - 1) * limit).Take(limit).ToListAsync(cancellationToken);

            // 4. تحويل إلى DTO
            var dtos = items.Select(i => new ImageDto
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
                PropertyId = i.PropertyId,
                UnitId = i.UnitId,
                Category = i.Category,
                Tags = string.IsNullOrWhiteSpace(i.Tags) ? new List<string>() : JsonSerializer.Deserialize<List<string>>(i.Tags) ?? new List<string>(),
                ProcessingStatus = i.Status.ToString(),
                Thumbnails = new ImageThumbnailsDto
                {
                    // إذا كان فيديو، لا ترجع روابط الـ thumbnails كـ mp4؛ استخدم VideoThumbnail إن توفر وإلا اتركها فارغة
                    Small = ResolveThumbnail(i, preferHd:false),
                    Medium = ResolveThumbnail(i, preferHd:false),
                    Large = ResolveThumbnail(i, preferHd:true),
                    Hd = ResolveThumbnail(i, preferHd:true)
                },
                MediaType = string.IsNullOrWhiteSpace(i.MediaType)
                    ? ((i.Type?.StartsWith("video/", StringComparison.OrdinalIgnoreCase) ?? false) ? "video" : "image")
                    : i.MediaType,
                Duration = i.DurationSeconds,
                VideoThumbnail = string.IsNullOrWhiteSpace(i.VideoThumbnailUrl) ? null : i.VideoThumbnailUrl
            }).ToList();

            for (int idx = 0; idx < dtos.Count; idx++)
            {
                dtos[idx].UploadedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[idx].UploadedAt);
            }

            // 5. إعداد نتيجة الترقيم
            var totalPages = (int)Math.Ceiling(totalCount / (double)limit);
            var paged = new PaginatedResultDto<ImageDto>
            {
                Items = dtos,
                Total = totalCount,
                Page = page,
                Limit = limit,
                TotalPages = totalPages
            };

            return ResultDto<PaginatedResultDto<ImageDto>>.Ok(paged);
        }

        private static string ResolveThumbnail(Core.Entities.PropertyImage i, bool preferHd)
        {
            var isVideo = string.Equals(i.MediaType, "video", StringComparison.OrdinalIgnoreCase)
                          || (i.Type?.StartsWith("video/", StringComparison.OrdinalIgnoreCase) ?? false)
                          || i.Url.EndsWith(".mp4", StringComparison.OrdinalIgnoreCase)
                          || i.Url.EndsWith(".webm", StringComparison.OrdinalIgnoreCase)
                          || i.Url.EndsWith(".mov", StringComparison.OrdinalIgnoreCase)
                          || i.Url.EndsWith(".mkv", StringComparison.OrdinalIgnoreCase);

            if (isVideo)
            {
                // استخدم VideoThumbnail إن توفر؛ وإلا اترك الحقل فارغاً كي تتعامل الواجهة مع Placeholder
                return string.IsNullOrWhiteSpace(i.VideoThumbnailUrl) ? string.Empty : i.VideoThumbnailUrl!;
            }
            return i.Sizes ?? string.Empty;
        }
    }
} 