using System;
using System.IO;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Enums;
using System.Collections.Generic;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Properties.Commands.UploadImages
{
    /// <summary>
    /// معالج أمر رفع صورة مع بيانات إضافية
    /// </summary>
    public class UploadImageCommandHandler : IRequestHandler<UploadImageCommand, ResultDto<ImageDto>>
    {
        private readonly IFileStorageService _fileStorageService;
        private readonly IImageProcessingService _imageProcessingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UploadImageCommandHandler> _logger;
        private readonly IPropertyImageRepository _imageRepository;
        private readonly ISectionImageRepository _sectionImageRepository;
        private readonly IPropertyInSectionImageRepository _propertyInSectionImageRepository;
        private readonly IUnitInSectionImageRepository _unitInSectionImageRepository;
        private readonly IUnitRepository _unitRepository;
        private readonly IMediaMetadataService _mediaMetadataService;
        // حذف خدمة توليد المصغرات من الخادم والاعتماد على العميل

        public UploadImageCommandHandler(
            IFileStorageService fileStorageService,
            IImageProcessingService imageProcessingService,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<UploadImageCommandHandler> logger,
            IPropertyImageRepository imageRepository,
            ISectionImageRepository sectionImageRepository,
            IPropertyInSectionImageRepository propertyInSectionImageRepository,
            IUnitInSectionImageRepository unitInSectionImageRepository,
            IUnitRepository unitRepository,
            IMediaMetadataService mediaMetadataService)
        {
            _fileStorageService = fileStorageService;
            _imageProcessingService = imageProcessingService;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _imageRepository = imageRepository;
            _sectionImageRepository = sectionImageRepository;
            _propertyInSectionImageRepository = propertyInSectionImageRepository;
            _unitInSectionImageRepository = unitInSectionImageRepository;
            _unitRepository = unitRepository;
            _mediaMetadataService = mediaMetadataService;
        }

        /// <inheritdoc />
        public async Task<ResultDto<ImageDto>> Handle(UploadImageCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء رفع الصورة: Name={Name}, Type={Type}", request.Name, request.ImageType);

            // التحقق من المصادقة
            if (_currentUserService.UserId == Guid.Empty)
                return ResultDto<ImageDto>.Failed("يجب تسجيل الدخول لرفع الصور");

            // التحقق من صحة المدخلات
            if (request.File == null || request.File.FileContent == null || request.File.FileContent.Length == 0)
                return ResultDto<ImageDto>.Failed("ملف الصورة مطلوب");
            if (string.IsNullOrWhiteSpace(request.Name))
                return ResultDto<ImageDto>.Failed("اسم الملف مطلوب");
            if (string.IsNullOrWhiteSpace(request.Extension))
                return ResultDto<ImageDto>.Failed("امتداد الملف مطلوب");

            try
            {
                // تحويل المحتوى إلى تيار
                var stream = new MemoryStream(request.File.FileContent);

                // Determine dynamic folder path based on ImageType, PropertyId, UnitId or TempKey
                Guid effectivePropertyId = request.PropertyId ?? Guid.Empty;
                if (effectivePropertyId == Guid.Empty && request.UnitId.HasValue)
                {
                    var unitEntity = await _unitRepository.GetUnitByIdAsync(request.UnitId.Value, cancellationToken);
                    effectivePropertyId = unitEntity?.PropertyId ?? Guid.Empty;
                }
                string folderPath;
                if (!string.IsNullOrWhiteSpace(request.TempKey))
                {
                    folderPath = $"temp/{request.TempKey}";
                }
                else if (request.SectionId.HasValue)
                {
                    folderPath = $"sections/{request.SectionId.Value}";
                }
                else if (!string.IsNullOrWhiteSpace(request.CityName))
                {
                    folderPath = $"cities/{request.CityName}";
                }
                else if (effectivePropertyId == Guid.Empty)
                {
                    folderPath = "temp";
                }
                else
                {
                    folderPath = $"{request.ImageType}/{effectivePropertyId}";
                    if (request.UnitId.HasValue)
                        folderPath = $"{folderPath}/{request.UnitId.Value}";
                }

            // السماح برفع الفيديوهات أيضاً: في حال كان نوع المحتوى Video نتجاوز عمليات التحقق الخاصة بالصور
            var isVideo = request.File.ContentType?.StartsWith("video/", StringComparison.OrdinalIgnoreCase) == true
                          || request.Extension.EndsWith(".mp4", StringComparison.OrdinalIgnoreCase)
                          || request.Extension.EndsWith(".mov", StringComparison.OrdinalIgnoreCase)
                          || request.Extension.EndsWith(".webm", StringComparison.OrdinalIgnoreCase)
                          || request.Extension.EndsWith(".mkv", StringComparison.OrdinalIgnoreCase);

            if (!isVideo)
            {
                // التحقق من صلاحية الصورة
                stream.Seek(0, SeekOrigin.Begin);
                var validationOptions = new ImageValidationOptions
                {
                    MaxFileSizeBytes = 5 * 1024 * 1024 // 5 ميغابايت كحد أقصى
                };
                var validationResult = await _imageProcessingService.ValidateImageAsync(stream, validationOptions, cancellationToken);
                if (!validationResult.IsValid)
                    return ResultDto<ImageDto>.Failed(validationResult.ValidationErrors, "فشل التحقق من صحة الصورة");
            }

                // تحسين الصورة إذا طُلب
                if (!isVideo && request.OptimizeImage)
                {
                    stream.Seek(0, SeekOrigin.Begin);
                    var compressResult = await _imageProcessingService.CompressImageAsync(stream, request.Quality ?? 85, null, cancellationToken);
                    if (compressResult.IsSuccess && compressResult.ProcessedImageBytes != null)
                    {
                        stream.Dispose();
                        stream = new MemoryStream(compressResult.ProcessedImageBytes);
                    }
                    else if (!compressResult.IsSuccess)
                    {
                        _logger.LogWarning("فشل تحسين الصورة: {Error}", compressResult.ErrorMessage);
                    }
                }

                // إنشاء صورة مصغرة إذا طُلب (للصور فقط)
                if (!isVideo && request.GenerateThumbnail)
                {
                    stream.Seek(0, SeekOrigin.Begin);
                    var thumbResult32 = await _imageProcessingService.GenerateThumbnailAsync(stream, maxHeight: 32, maxWidth: 32, cancellationToken: cancellationToken);
                    if (thumbResult32.IsSuccess && thumbResult32.ProcessedImageBytes != null)
                    {
                        var thumbName = $"{request.Name}_thumb{request.Extension}";
                        await _fileStorageService.UploadFileAsync(
                            thumbResult32.ProcessedImageBytes,
                            thumbName,
                            request.File.ContentType,
                            folderPath,
                            cancellationToken);
                    }
                    else if (!thumbResult32.IsSuccess)
                    {
                        _logger.LogWarning("فشل إنشاء الصورة المصغرة: {Error}", thumbResult32.ErrorMessage);
                    }
                    stream.Seek(0, SeekOrigin.Begin);
                    var thumbResult48 = await _imageProcessingService.GenerateThumbnailAsync(stream, maxHeight: 48, maxWidth: 48, cancellationToken: cancellationToken);
                    if (thumbResult48.IsSuccess && thumbResult48.ProcessedImageBytes != null)
                    {
                        var thumbName = $"{request.Name}_thumb48{request.Extension}";
                        await _fileStorageService.UploadFileAsync(
                            thumbResult48.ProcessedImageBytes,
                            thumbName,
                            request.File.ContentType,
                            folderPath,
                            cancellationToken);
                    }
                    else if (!thumbResult48.IsSuccess)
                    {
                        _logger.LogWarning("فشل إنشاء الصورة المصغرة: {Error}", thumbResult48.ErrorMessage);
                    }
                    stream.Seek(0, SeekOrigin.Begin);
                    var thumbResult64 = await _imageProcessingService.GenerateThumbnailAsync(stream, maxHeight: 64, maxWidth: 64, cancellationToken: cancellationToken);
                    if (thumbResult64.IsSuccess && thumbResult64.ProcessedImageBytes != null)
                    {
                        var thumbName = $"{request.Name}_thumb64{request.Extension}";
                        await _fileStorageService.UploadFileAsync(
                            thumbResult64.ProcessedImageBytes,
                            thumbName,
                            request.File.ContentType,
                            folderPath,
                            cancellationToken);
                    }
                    else if (!thumbResult64.IsSuccess)
                    {
                        _logger.LogWarning("فشل إنشاء الصورة المصغرة: {Error}", thumbResult64.ErrorMessage);
                    }
                }

                // رفع الملف الرئيسي
                stream.Seek(0, SeekOrigin.Begin);
                var fileName = request.Name + request.Extension;
                var uploadResult = await _fileStorageService.UploadFileAsync(
                    stream,
                    fileName,
                    request.File.ContentType,
                    folderPath,
                    cancellationToken);

                if (!uploadResult.IsSuccess || uploadResult.FileUrl == null)
                    return ResultDto<ImageDto>.Failed("حدث خطأ أثناء رفع الصورة");

                _logger.LogInformation("اكتمل رفع الصورة بنجاح: Url={Url}", uploadResult.FileUrl);
                // معالجة الفيديو (مدة فقط) + قبول مصغرة من العميل إن وردت
                int? videoDurationSeconds = null;
                string? videoThumbUrl = null;
                if (isVideo && !string.IsNullOrWhiteSpace(uploadResult.FilePath))
                {
                    try
                    {
                        videoDurationSeconds = await _mediaMetadataService.TryGetDurationSecondsAsync(uploadResult.FilePath!, request.File.ContentType, cancellationToken);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogDebug(ex, "Video duration extraction failed");
                    }

                    // إن أرسل العميل صورة مصغّرة للفيديو، ارفعها وخزّن رابطها
                    if (request.VideoThumbnail != null && request.VideoThumbnail.FileContent?.Length > 0)
                    {
                        try
                        {
                            var posterName = Path.GetFileNameWithoutExtension(fileName) + "_poster" + (request.VideoThumbnail.FileName.EndsWith(".png", StringComparison.OrdinalIgnoreCase) ? ".png" : ".jpg");
                            var posterUpload = await _fileStorageService.UploadFileAsync(
                                new MemoryStream(request.VideoThumbnail.FileContent),
                                posterName,
                                request.VideoThumbnail.ContentType ?? "image/jpeg",
                                folderPath,
                                cancellationToken
                            );
                            if (posterUpload.IsSuccess && !string.IsNullOrWhiteSpace(posterUpload.FileUrl))
                            {
                                videoThumbUrl = posterUpload.FileUrl;
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogDebug(ex, "Client-provided video thumbnail upload failed");
                        }
                    }
                }

                // حدد قيمة thumbnails الأساسية
                // لا تضع رابط ملف الفيديو داخل Thumbnails حتى لا تحاول الواجهة عرضه كصورة
                string? thumbnailsBase = uploadResult.FileUrl;
                if (isVideo)
                {
                    thumbnailsBase = !string.IsNullOrWhiteSpace(videoThumbUrl)
                        ? videoThumbUrl!
                        : string.Empty; // اتركها فارغة إن لم يتوفر بوستر
                }

                // Compute timestamps: store UTC in DB, return local in DTO
                var uploadedUtc = DateTime.UtcNow;
                var uploadedLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(uploadedUtc);

                // بناء DTO للصورة للرد
                var imageDto = new ImageDto
                {
                    Id = Guid.NewGuid(),
                    Url = uploadResult.FileUrl,
                    Filename = fileName,
                    Size = uploadResult.FileSizeBytes,
                    MimeType = request.File.ContentType ?? string.Empty,
                    Width = 0,
                    Height = 0,
                    Alt = request.Alt,
                    UploadedAt = uploadedLocal,
                    UploadedBy = _currentUserService.UserId,
                    Order = request.Order ?? 0,
                    IsPrimary = request.IsPrimary ?? false,
                    PropertyId = request.PropertyId,
                    UnitId = request.UnitId,
                    Category = request.Category,
                    Tags = request.Tags ?? new List<string>(),
                    ProcessingStatus = "ready",
                    Thumbnails = new ImageThumbnailsDto
                    {
                        Small = thumbnailsBase ?? string.Empty,
                        Medium = thumbnailsBase ?? string.Empty,
                        Large = thumbnailsBase ?? string.Empty,
                        Hd = thumbnailsBase ?? string.Empty
                    },
                    MediaType = isVideo ? "video" : "image",
                    Duration = videoDurationSeconds,
                    VideoThumbnail = videoThumbUrl
                };

                // تسجيل عملية الرفع في السجل (يدوي) مع ذكر اسم المستخدم والمعرف
                var notes = $"تم رفع الصورة {fileName} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
                await _auditService.LogAuditAsync(
                    entityType: "Image",
                    entityId: imageDto.Id,
                    action: AuditAction.CREATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(new { Path = uploadResult.FilePath, Url = uploadResult.FileUrl }),
                    performedBy: _currentUserService.UserId,
                    notes: notes,
                    cancellationToken: cancellationToken);
                // Determine PropertyId association: maintain null if none
                Guid? propertyAssociation = request.PropertyId;
                if (!propertyAssociation.HasValue && request.UnitId.HasValue)
                {
                    var unit = await _unitRepository.GetUnitByIdAsync(request.UnitId.Value, cancellationToken);
                    propertyAssociation = unit?.PropertyId;
                }

                // Persist image entity to database based on context
                if (request.SectionId.HasValue)
                {
                    var entity = new SectionImage
                    {
                        Id = imageDto.Id,
                        SectionId = request.SectionId!.Value,
                        Name = fileName,
                        Url = uploadResult.FileUrl,
                        SizeBytes = uploadResult.FileSizeBytes,
                        Type = request.File.ContentType,
                        Category = request.Category,
                        Caption = request.Alt ?? string.Empty,
                        AltText = request.Alt ?? string.Empty,
                        Tags = JsonSerializer.Serialize(request.Tags ?? new List<string>()),
                        Sizes = thumbnailsBase,
                        IsMainImage = request.IsPrimary ?? false,
                        DisplayOrder = request.Order ?? 0,
                        Status = ImageStatus.Approved,
                        UploadedAt = uploadedUtc,
                        CreatedBy = _currentUserService.UserId,
                        UpdatedAt = uploadedUtc,
                        MediaType = isVideo ? "video" : "image",
                        DurationSeconds = videoDurationSeconds,
                        VideoThumbnailUrl = videoThumbUrl
                    };
                    await _sectionImageRepository.CreateAsync(entity, cancellationToken);
                }
                else if (request.PropertyInSectionId.HasValue)
                {
                    var entity = new PropertyInSectionImage
                    {
                        Id = imageDto.Id,
                        PropertyInSectionId = request.PropertyInSectionId!.Value,
                        Name = fileName,
                        Url = uploadResult.FileUrl,
                        SizeBytes = uploadResult.FileSizeBytes,
                        Type = request.File.ContentType,
                        Category = request.Category,
                        Caption = request.Alt ?? string.Empty,
                        AltText = request.Alt ?? string.Empty,
                        Tags = JsonSerializer.Serialize(request.Tags ?? new List<string>()),
                        Sizes = thumbnailsBase,
                        IsMainImage = request.IsPrimary ?? false,
                        DisplayOrder = request.Order ?? 0,
                        Status = ImageStatus.Approved,
                        UploadedAt = uploadedUtc,
                        CreatedBy = _currentUserService.UserId,
                        UpdatedAt = uploadedUtc,
                        MediaType = isVideo ? "video" : "image",
                        DurationSeconds = videoDurationSeconds,
                        VideoThumbnailUrl = videoThumbUrl
                    };
                    await _propertyInSectionImageRepository.CreateAsync(entity, cancellationToken);
                }
                else if (request.UnitInSectionId.HasValue)
                {
                    var entity = new UnitInSectionImage
                    {
                        Id = imageDto.Id,
                        UnitInSectionId = request.UnitInSectionId!.Value,
                        Name = fileName,
                        Url = uploadResult.FileUrl,
                        SizeBytes = uploadResult.FileSizeBytes,
                        Type = request.File.ContentType,
                        Category = request.Category,
                        Caption = request.Alt ?? string.Empty,
                        AltText = request.Alt ?? string.Empty,
                        Tags = JsonSerializer.Serialize(request.Tags ?? new List<string>()),
                        Sizes = thumbnailsBase,
                        IsMainImage = request.IsPrimary ?? false,
                        DisplayOrder = request.Order ?? 0,
                        Status = ImageStatus.Approved,
                        UploadedAt = uploadedUtc,
                        CreatedBy = _currentUserService.UserId,
                        UpdatedAt = uploadedUtc,
                        MediaType = isVideo ? "video" : "image",
                        DurationSeconds = videoDurationSeconds,
                        VideoThumbnailUrl = videoThumbUrl
                    };
                    await _unitInSectionImageRepository.CreateAsync(entity, cancellationToken);
                }
                else
                {
                    var imageEntity = new PropertyImage
                {
                    Id = imageDto.Id,
                    PropertyId = propertyAssociation,
                    UnitId = request.UnitId,
                    CityName = string.IsNullOrWhiteSpace(request.CityName) ? null : request.CityName,
                    TempKey = string.IsNullOrWhiteSpace(request.TempKey) ? null : request.TempKey,
                    Name = fileName,
                    Url = uploadResult.FileUrl,
                    SizeBytes = uploadResult.FileSizeBytes,
                    Type = request.File.ContentType,
                    Category = request.Category,
                    Caption = request.Alt ?? string.Empty,
                    AltText = request.Alt ?? string.Empty,
                    Tags = JsonSerializer.Serialize(request.Tags ?? new List<string>()),
                    Sizes = thumbnailsBase,
                    IsMainImage = request.IsPrimary ?? false,
                    DisplayOrder = request.Order ?? 0,
                    Status = ImageStatus.Approved,
                    UploadedAt = uploadedUtc,
                    CreatedBy = _currentUserService.UserId,
                    UpdatedAt = uploadedUtc,
                    MediaType = isVideo ? "video" : "image",
                    DurationSeconds = videoDurationSeconds,
                    VideoThumbnailUrl = videoThumbUrl
                };
                await _imageRepository.CreatePropertyImageAsync(imageEntity, cancellationToken);
                }
                
                return ResultDto<ImageDto>.Succeeded(imageDto, "تم رفع الصورة بنجاح");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ في رفع الصورة");
                return ResultDto<ImageDto>.Failed("حدث خطأ غير متوقع أثناء رفع الصورة");
            }
        }
    }
} 