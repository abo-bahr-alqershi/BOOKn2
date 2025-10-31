using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using System.Linq;
using YemenBooking.Core.Enums;
using System.IO;
using System.Text.Json;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.Properties.Commands.UpdateProperty
{
    /// <summary>
    /// معالج أمر تحديث بيانات الكيان
    /// </summary>
    public class UpdatePropertyCommandHandler : IRequestHandler<UpdatePropertyCommand, ResultDto<bool>>
    {
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly IFileStorageService _fileStorageService;
        private readonly IPropertyImageRepository _propertyImageRepository;
        private readonly IAmenityRepository _amenityRepository;
        private readonly IPropertyAmenityRepository _propertyAmenityRepository;
        private readonly IIndexingService _indexingService;
        private readonly ILogger<UpdatePropertyCommandHandler> _logger;
        private readonly IMediator _mediator;

        public UpdatePropertyCommandHandler(
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            IFileStorageService fileStorageService,
            IPropertyImageRepository propertyImageRepository,
            IAmenityRepository amenityRepository,
            IPropertyAmenityRepository propertyAmenityRepository,
            IIndexingService indexingService,
            ILogger<UpdatePropertyCommandHandler> logger,
            IMediator mediator)
        {
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _fileStorageService = fileStorageService;
            _propertyImageRepository = propertyImageRepository;
            _amenityRepository = amenityRepository;
            _propertyAmenityRepository = propertyAmenityRepository;
            _indexingService = indexingService;
            _logger = logger;
            _mediator = mediator;
        }

        public async Task<ResultDto<bool>> Handle(UpdatePropertyCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحديث بيانات الكيان: PropertyId={PropertyId}", request.PropertyId);

            // التحقق من صحة المدخلات
            if (request.PropertyId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الكيان مطلوب");

            // التحقق من وجود الكيان
            var property = await _propertyRepository.GetPropertyByIdAsync(request.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<bool>.Failed("الكيان غير موجود");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            if (_currentUserService.Role != "Admin" && property.OwnerId != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بتحديث هذا الكيان");

            // إذا كان الكيان معتمدًا وتم تعديل بيانات حساسة، إعادة تعيين الموافقة
            bool requiresReapproval = property.IsApproved &&
                ((!string.IsNullOrWhiteSpace(request.Name) && request.Name != property.Name) ||
                 (!string.IsNullOrWhiteSpace(request.Address) && request.Address != property.Address) ||
                 (request.StarRating.HasValue && request.StarRating.Value != property.StarRating) ||
                 (!string.IsNullOrWhiteSpace(request.Currency) && !string.Equals(property.Currency, request.Currency, StringComparison.OrdinalIgnoreCase)));
            if (requiresReapproval)
                property.IsApproved = false;

            // تحديث المالك إن طُلب وكان المستخدم مشرفاً
            if (request.OwnerId.HasValue && request.OwnerId.Value != Guid.Empty)
            {
                if (_currentUserService.Role == "Admin")
                {
                    var newOwner = await _propertyRepository.GetOwnerByIdAsync(request.OwnerId.Value, cancellationToken);
                    if (newOwner == null)
                        return ResultDto<bool>.Failed("المالك الجديد غير موجود");
                    if (property.OwnerId != request.OwnerId.Value)
                    {
                        property.OwnerId = request.OwnerId.Value;
                        requiresReapproval = true; // تغيير المالك يتطلب إعادة موافقة
                    }
                }
                else
                {
                    return ResultDto<bool>.Failed("غير مسموح بتغيير المالك إلا للمشرف");
                }
            }

            // تنفيذ التحديث
            if (!string.IsNullOrWhiteSpace(request.Name))
                property.Name = request.Name;
            if (!string.IsNullOrWhiteSpace(request.Address))
                property.Address = request.Address;
            if (!string.IsNullOrWhiteSpace(request.Description))
                property.Description = request.Description;
            if (!string.IsNullOrWhiteSpace(request.ShortDescription))
                property.ShortDescription = request.ShortDescription;
            if (!string.IsNullOrWhiteSpace(request.City))
                property.City = request.City;
            if (request.StarRating.HasValue)
                property.StarRating = request.StarRating.Value;
            if (!string.IsNullOrWhiteSpace(request.Currency))
                property.Currency = request.Currency!.ToUpperInvariant();
            
            if (request.IsFeatured.HasValue)
                property.IsFeatured = request.IsFeatured.Value;
            if (request.Latitude.HasValue && request.Latitude.Value >= -90 && request.Latitude.Value <= 90)
                property.Latitude = (decimal)request.Latitude.Value;
            if (request.Longitude.HasValue && request.Longitude.Value >= -180 && request.Longitude.Value <= 180)
                property.Longitude = (decimal)request.Longitude.Value;

            property.UpdatedBy = _currentUserService.UserId;
            property.UpdatedAt = DateTime.UtcNow;

            // احتفظ بالقيم القديمة قبل الحفظ
            var oldValues = new
            {
                property.Id,
                property.Name,
                property.Address,
                property.Description,
                property.City,
                property.StarRating,
                property.Currency,
                property.IsFeatured,
                property.Latitude,
                property.Longitude
            };

            await _propertyRepository.UpdatePropertyAsync(property, cancellationToken);

            // مزامنة المرافق إذا تم إرسال قائمة معرفات
            if (request.AmenityIds != null)
            {
                var desiredIds = request.AmenityIds.ToHashSet();
                // PTAs for this property type
                var ptaList = (await _amenityRepository.GetAmenitiesByPropertyTypeAsync(property.TypeId, cancellationToken)).ToList();
                var ptaByAmenityId = ptaList.ToDictionary(x => x.AmenityId, x => x);

                // current assignments
                var currentAmenities = (await _propertyRepository.GetPropertyAmenitiesAsync(request.PropertyId, cancellationToken)).ToList();
                // map current to AmenityId via PTA
                var currentAmenityIds = currentAmenities
                    .Select(pa => ptaList.FirstOrDefault(pta => pta.Id == pa.PtaId)?.AmenityId)
                    .Where(id => id.HasValue)
                    .Select(id => id!.Value)
                    .ToHashSet();

                // remove
                foreach (var pa in currentAmenities)
                {
                    var amenityId = ptaList.FirstOrDefault(pta => pta.Id == pa.PtaId)?.AmenityId;
                    if (!amenityId.HasValue) continue;
                    if (!desiredIds.Contains(amenityId.Value))
                    {
                        await _propertyAmenityRepository.RemoveAmenityFromPropertyAsync(property.Id, pa.PtaId, cancellationToken);
                    }
                }

                // add
                var toAddAmenityIds = desiredIds.Where(id => !currentAmenityIds.Contains(id)).ToList();
                foreach (var amenityId in toAddAmenityIds)
                {
                    if (!ptaByAmenityId.TryGetValue(amenityId, out var pta)) continue;
                    var pa = new PropertyAmenity
                    {
                        PropertyId = property.Id,
                        PtaId = pta.Id,
                        IsAvailable = true,
                        ExtraCost = YemenBooking.Core.ValueObjects.Money.Zero(property.Currency)
                    };
                    await _propertyAmenityRepository.AddAmenityToPropertyAsync(pa, cancellationToken);
                }
            }

            // تسجيل العملية في سجل التدقيق (يدوي مع JSON للقيم القديمة والجديدة)
            var newValues = new
            {
                property.Id,
                property.Name,
                property.Address,
                property.Description,
                property.City,
                property.StarRating,
                property.Currency,
                property.IsFeatured,
                property.Latitude,
                property.Longitude
            };
            await _auditService.LogAuditAsync(
                entityType: "Property",
                entityId: request.PropertyId,
                action: AuditAction.UPDATE,
                oldValues: JsonSerializer.Serialize(oldValues),
                newValues: JsonSerializer.Serialize(newValues),
                performedBy: _currentUserService.UserId,
                notes: $"تم تحديث بيانات الكيان {request.PropertyId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل تحديث بيانات الكيان: PropertyId={PropertyId}", request.PropertyId);
            // نقل الصور المؤقتة المحددة في الكوماند للكيان
            _logger.LogInformation("نقل الصور المؤقتة المحددة في الكوماند للكيان: {PropertyId}", request.PropertyId);
            // حذف الصور التي أزيلت من الكيان
            var existingImages = (await _propertyImageRepository.GetImagesByPropertyAsync(request.PropertyId, cancellationToken)).ToList();
            var imagesToDelete = existingImages.Where(img => request.Images == null || !request.Images.Contains(img.Url)).ToList();
            foreach (var img in imagesToDelete)
            {
                // حذف الملف من التخزين
                var uri = new Uri(img.Url);
                var filePath = uri.AbsolutePath.TrimStart('/');
                await _fileStorageService.DeleteFileAsync(filePath, cancellationToken);
                // حذف السجل من قاعدة البيانات
                await _propertyImageRepository.DeletePropertyImageAsync(img.Id, cancellationToken);
            }
            if (request.Images != null && request.Images.Any())
            {
                // جمع المسارات النسبية للصور من الطلب (بما في ذلك الشريط المائل الأمامي)
                var relativePaths = request.Images.Select(imagePath =>
                {
                    // Get absolute path (including leading slash) then unescape
                    var absolutePath = Uri.TryCreate(imagePath, UriKind.Absolute, out var uriRes)
                        ? uriRes.AbsolutePath
                        : (imagePath.StartsWith("/") ? imagePath : "/" + imagePath);
                    return Uri.UnescapeDataString(absolutePath);
                }).ToList();
                // جلب سجلات الصور المؤقتة حسب المسار فقط
                var tempImages = await _propertyImageRepository.GetImagesByPathAsync(relativePaths, cancellationToken);
                foreach (var imagePath in request.Images)
                {
                    // استخراج المسار النسبي كاملاً وإلغاء ترميز الـ URL
                    string absolutePath = Uri.TryCreate(imagePath, UriKind.Absolute, out var uriRes)
                        ? uriRes.AbsolutePath
                        : (imagePath.StartsWith("/") ? imagePath : "/" + imagePath);
                    string relativePath = Uri.UnescapeDataString(absolutePath);
                    var segments = relativePath.Split('/', StringSplitOptions.RemoveEmptyEntries);
                    // نحتاج على الأقل: ["uploads", "folder", "filename"]
                    if (segments.Length < 3) continue;
                    // استخراج المسار الفرعي دون بادئة "uploads"
                    var folderSegments = segments.Skip(1).Take(segments.Length - 2);
                    var fileName = segments[^1];
                    // استخدم مجلد "Management" للصور الدائمة
                    var tempFolder = string.Join("/", folderSegments);                                        // e.g. "temp"
                    var sourceRelativePath = $"{tempFolder}/{fileName}";                                       // e.g. "temp/file.png"
                    var persistentFolder = ImageType.Management.ToString();                                    // e.g. "Management"
                    var destFolderPath = $"{persistentFolder}/{request.PropertyId}";                            // e.g. "Management/{propertyId}"
                    var destRelativePath = $"{destFolderPath}/{fileName}";
                    // العثور على السجل المؤقت المطابق للمسار في DB
                    var img = tempImages.FirstOrDefault(i => i.Url == relativePath);
                    if (img == null) continue;
                    // نقل الملف وإنشاء المجلد الوجهة إذا لزم الأمر
                    await _fileStorageService.MoveFileAsync(sourceRelativePath, destRelativePath, cancellationToken);
                    var newUrl = await _fileStorageService.GetFileUrlAsync(destRelativePath, null, cancellationToken);
                    img.PropertyId = request.PropertyId;
                    img.Url = newUrl;
                    img.Sizes = newUrl;
                    await _propertyImageRepository.UpdatePropertyImageAsync(img, cancellationToken);
                    // Move thumbnail files if exist
                    var nameWithoutExt = Path.GetFileNameWithoutExtension(fileName);
                    var ext = Path.GetExtension(fileName);
                    var thumbnailSuffixes = new[] { "_thumb", "_thumb48", "_thumb64", "_poster" };
                    foreach (var suffix in thumbnailSuffixes)
                    {
                        var thumbSource = $"{tempFolder}/{nameWithoutExt}{suffix}{ext}";
                        var thumbDest = $"{destFolderPath}/{nameWithoutExt}{suffix}{ext}";
                        await _fileStorageService.MoveFileAsync(thumbSource, thumbDest, cancellationToken);
                    }
                }
            }

            // استدعاء الفهرسة المباشرة لضمان تحديث العقار
            try
            {
                await _indexingService.OnPropertyUpdatedAsync(property.Id, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذر الفهرسة المباشرة للعقار {PropertyId}", property.Id);
            }

            

            return ResultDto<bool>.Succeeded(true, "تم تحديث بيانات الكيان بنجاح");
        }
    }
} 