using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.ValueObjects;
using YemenBooking.Application.Common.Exceptions;
using System.Linq;
using YemenBooking.Core.Enums;
using System.IO;
using YemenBooking.Core.Events;
using System.Collections.Generic;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.Units.Commands.CreateUnit
{
    /// <summary>
    /// معالج أمر إنشاء وحدة جديدة في الكيان
    /// </summary>
    public class CreateUnitCommandHandler : IRequestHandler<CreateUnitCommand, ResultDto<Guid>>
    {
        private readonly IUnitRepository _unitRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUnitTypeRepository _unitTypeRepository;
        private readonly IUnitFieldValueRepository _valueRepository;
        private readonly IUnitTypeFieldRepository _fieldRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly IFileStorageService _fileStorageService;
        private readonly IPropertyImageRepository _propertyImageRepository;
        private readonly IIndexingService _indexingService;
        private readonly ILogger<CreateUnitCommandHandler> _logger;
        private readonly IMediator _mediator;

        public CreateUnitCommandHandler(
            IUnitRepository unitRepository,
            IPropertyRepository propertyRepository,
            IUnitTypeRepository unitTypeRepository,
            IUnitFieldValueRepository valueRepository,
            IUnitOfWork unitOfWork,
            IUnitTypeFieldRepository fieldRepository,
            IFileStorageService fileStorageService,
            IPropertyImageRepository propertyImageRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            IIndexingService indexingService,
            IMediator mediator,
            ILogger<CreateUnitCommandHandler> logger)
        {
            _unitRepository = unitRepository;
            _propertyRepository = propertyRepository;
            _fieldRepository = fieldRepository;
            _unitTypeRepository = unitTypeRepository;
            _valueRepository = valueRepository;
            _unitOfWork = unitOfWork;
            _fileStorageService = fileStorageService;
            _propertyImageRepository = propertyImageRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _indexingService = indexingService;
            _mediator = mediator;
            _logger = logger;
        }

        public async Task<ResultDto<Guid>> Handle(CreateUnitCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إنشاء وحدة في الكيان: PropertyId={PropertyId}, Name={Name}", request.PropertyId, request.Name);

            // التحقق من المدخلات
            if (request.PropertyId == Guid.Empty)
                return ResultDto<Guid>.Failed("معرف الكيان مطلوب");
            if (request.UnitTypeId == Guid.Empty)
                return ResultDto<Guid>.Failed("معرف نوع الوحدة مطلوب");
            if (string.IsNullOrWhiteSpace(request.Name))
                return ResultDto<Guid>.Failed("اسم الوحدة مطلوب");
            if (request.BasePrice == null || request.BasePrice.Amount <= 0)
                return ResultDto<Guid>.Failed("السعر الأساسي يجب أن يكون أكبر من صفر");

            // التحقق المنطقي لنافذة الإلغاء
            if (!request.AllowsCancellation && request.CancellationWindowDays.HasValue)
                return ResultDto<Guid>.Failed("لا يمكن تحديد نافذة إلغاء إذا كانت الإلغاء غير مسموح");
            if (request.CancellationWindowDays.HasValue && request.CancellationWindowDays.Value < 0)
                return ResultDto<Guid>.Failed("نافذة الإلغاء يجب أن تكون صفر أو أكثر");

            // التحقق من وجود الكيان والنوع
            var property = await _propertyRepository.GetPropertyByIdAsync(request.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<Guid>.Failed("الكيان غير موجود");
            var unitType = await _unitTypeRepository.GetUnitTypeByIdAsync(request.UnitTypeId, cancellationToken);
            if (unitType == null)
                return ResultDto<Guid>.Failed("نوع الوحدة غير موجود");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            if (!isAdmin && property.OwnerId != _currentUserService.UserId)
                return ResultDto<Guid>.Failed("غير مصرح لك بإنشاء وحدة في هذا الكيان");

            // التحقق من التكرار
            bool exists = await _unitRepository.ExistsAsync(u => u.PropertyId == request.PropertyId && u.Name.Trim() == request.Name.Trim(), cancellationToken);
            if (exists)
                return ResultDto<Guid>.Failed("يوجد وحدة بنفس الاسم في هذا الكيان");
            // التحقق من صحة قيم الحقول الديناميكية حسب التعريفات
            var fieldDefs = await _fieldRepository.GetFieldsByUnitTypeIdAsync(request.UnitTypeId, cancellationToken);
            foreach (var def in fieldDefs)
            {
                var dto = request.FieldValues.FirstOrDefault(f => f.FieldId == def.Id);
                if (def.IsRequired && (dto == null || string.IsNullOrWhiteSpace(dto.FieldValue)))
                    return ResultDto<Guid>.Failed($"الحقل {def.DisplayName} مطلوب.");
                if (dto != null && (def.FieldTypeId == "number" || def.FieldTypeId == "currency" || def.FieldTypeId == "percentage" || def.FieldTypeId == "range"))
                {
                    if (!decimal.TryParse(dto.FieldValue, out _))
                        return ResultDto<Guid>.Failed($"قيمة الحقل {def.DisplayName} يجب أن تكون رقمًا.");
                }
            }

            // إنشاء الوحدة مع القيم الديناميكية في معاملة واحدة
            Guid createdId = Guid.Empty;
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // إنشاء الكيان
                // Always use property's currency for unit base price, ignore client currency to avoid invalid codes
                var propertyCurrency = (property.Currency ?? request.BasePrice.Currency ?? "YER").Trim().ToUpperInvariant();
                var unit = new Core.Entities.Unit
                {
                    PropertyId = request.PropertyId,
                    UnitTypeId = request.UnitTypeId,
                    Name = request.Name.Trim(),
                    BasePrice = new Money(request.BasePrice.Amount, propertyCurrency),
                    MaxCapacity = unitType.MaxCapacity,
                    CustomFeatures = request.CustomFeatures.Trim(),
                    PricingMethod = request.PricingMethod,
                    IsAvailable = true,
                    AllowsCancellation = request.AllowsCancellation,
                    CancellationWindowDays = request.CancellationWindowDays,
                    CreatedBy = _currentUserService.UserId,
                    CreatedAt = DateTime.UtcNow
                };
                var created = await _unitRepository.CreateUnitAsync(unit, cancellationToken);
                createdId = created.Id;

                // إنشاء قيم الحقول الديناميكية
                foreach (var dto in request.FieldValues)
                {
                    if (dto.FieldId == Guid.Empty)
                        throw new BusinessRuleException("InvalidFieldId", "معرف الحقل غير صالح");

                    var newValue = new UnitFieldValue
                    {
                        UnitId = created.Id,
                        UnitTypeFieldId = dto.FieldId,
                        FieldValue = dto.FieldValue,
                        CreatedBy = _currentUserService.UserId,
                        CreatedAt = DateTime.UtcNow
                    };
                    await _valueRepository.CreateUnitFieldValueAsync(newValue, cancellationToken);
                }

                // تسجيل التدقيق اليدوي مع القيم الجديدة
                var newValues = new
                {
                    created.Id,
                    created.PropertyId,
                    created.UnitTypeId,
                    created.Name,
                    created.BasePrice,
                    created.MaxCapacity,
                    created.CustomFeatures,
                    created.PricingMethod,
                    created.IsAvailable,
                    created.AllowsCancellation,
                    created.CancellationWindowDays
                };
                await _auditService.LogAuditAsync(
                    entityType: "Unit",
                    entityId: created.Id,
                    action: AuditAction.CREATE,
                    oldValues: null,
                    newValues: JsonSerializer.Serialize(newValues),
                    performedBy: _currentUserService.UserId,
                    notes: $"تم إنشاء وحدة جديدة {created.Id} باسم {created.Name} مع قيم الحقول الديناميكية بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                    cancellationToken: cancellationToken);

                _logger.LogInformation("اكتمل إنشاء الوحدة بنجاح: UnitId={UnitId}", created.Id);
            });

            // نقل الصور المؤقتة إلى المسار الرسمي بعد إنشاء الوحدة
            _logger.LogInformation("نقل الصور المؤقتة المحددة في الكوماند للوحدة: {UnitId}", createdId);
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
                    var tempFolder = string.Join("/", folderSegments);                                                   // e.g. "temp" or "temp/{tempKey}"
                    var sourceRelativePath = $"{tempFolder}/{fileName}";                                                  // e.g. "temp/file.png"
                    var persistentFolder = ImageType.Management.ToString();                                                   // e.g. "Management"
                    var destFolderPath = $"{persistentFolder}/{request.PropertyId}/{createdId}";                           // e.g. "Management/{propertyId}/{unitId}"
                    var destRelativePath = $"{destFolderPath}/{fileName}";
                    // العثور على السجل المؤقت المطابق للمسار في DB
                    var img = tempImages.FirstOrDefault(i => i.Url == relativePath);
                    if (img == null) continue;
                    // نقل الملف وإنشاء المجلد الوجهة إذا لزم الأمر
                    await _fileStorageService.MoveFileAsync(sourceRelativePath, destRelativePath, cancellationToken);
                    var newUrl = await _fileStorageService.GetFileUrlAsync(destRelativePath, null, cancellationToken);
                    img.PropertyId = request.PropertyId;
                    img.UnitId = createdId;
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

                // Set unit main image after moving
                var movedImages = await _propertyImageRepository.GetImagesByUnitAsync(createdId, cancellationToken);
                var primaryCandidate = movedImages
                    .OrderByDescending(i => i.IsMain || i.IsMainImage)
                    .ThenBy(i => i.DisplayOrder)
                    .ThenBy(i => i.UploadedAt)
                    .FirstOrDefault();
                if (primaryCandidate != null)
                {
                    await _propertyImageRepository.UpdateMainImageStatusAsync(primaryCandidate.Id, true, cancellationToken);
                }
            }

            // إذا تم تمرير TempKey بدون قائمة Images، حاول ربط جميع صور المفتاح المؤقت
            if (!string.IsNullOrWhiteSpace(request.TempKey))
            {
                var tempImages = await _propertyImageRepository.GetImagesByTempKeyAsync(request.TempKey, cancellationToken);
                foreach (var img in tempImages)
                {
                    // calculate relative names
                    string absolutePath = new Uri(img.Url, UriKind.RelativeOrAbsolute).IsAbsoluteUri
                        ? new Uri(img.Url).AbsolutePath
                        : (img.Url.StartsWith("/") ? img.Url : "/" + img.Url);
                    string relativePath = Uri.UnescapeDataString(absolutePath);
                    var fileName = Path.GetFileName(relativePath);

                    var persistentFolder = ImageType.Management.ToString();
                    var destFolderPath = $"{persistentFolder}/{request.PropertyId}/{createdId}";
                    var destRelativePath = $"{destFolderPath}/{fileName}";

                    await _fileStorageService.MoveFileAsync($"temp/{request.TempKey}/{fileName}", destRelativePath, cancellationToken);
                    var newUrl = await _fileStorageService.GetFileUrlAsync(destRelativePath, null, cancellationToken);

                    img.PropertyId = request.PropertyId;
                    img.UnitId = createdId;
                    img.TempKey = null;
                    img.Url = newUrl;
                    img.Sizes = newUrl;
                    await _propertyImageRepository.UpdatePropertyImageAsync(img, cancellationToken);

                    var nameWithoutExt = Path.GetFileNameWithoutExtension(fileName);
                    var ext = Path.GetExtension(fileName);
                    var thumbnailSuffixes = new[] { "_thumb", "_thumb48", "_thumb64", "_poster" };
                    foreach (var suffix in thumbnailSuffixes)
                    {
                        await _fileStorageService.MoveFileAsync($"temp/{request.TempKey}/{nameWithoutExt}{suffix}{ext}", $"{destFolderPath}/{nameWithoutExt}{suffix}{ext}", cancellationToken);
                    }
                }

                // Set unit main image after moving by temp key
                var movedImages = await _propertyImageRepository.GetImagesByUnitAsync(createdId, cancellationToken);
                var primaryCandidate = movedImages
                    .OrderByDescending(i => i.IsMain || i.IsMainImage)
                    .ThenBy(i => i.DisplayOrder)
                    .ThenBy(i => i.UploadedAt)
                    .FirstOrDefault();
                if (primaryCandidate != null)
                {
                    await _propertyImageRepository.UpdateMainImageStatusAsync(primaryCandidate.Id, true, cancellationToken);
                }
            }

            // فهرسة مباشرة للوحدة الجديدة
            try
            {
                await _indexingService.OnUnitCreatedAsync(createdId, request.PropertyId, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذرت الفهرسة المباشرة للوحدة الجديدة {UnitId}", createdId);
            }

            // فهرسة مباشرة للحقول الديناميكية
            try
            {
                foreach (var dto in request.FieldValues)
                {
                    var def = fieldDefs.FirstOrDefault(f => f.Id == dto.FieldId);
                    if (def == null) continue;
                    await _indexingService.OnDynamicFieldChangedAsync(
                        property.Id,
                        // value.Id,
                        def.FieldName,
                        // def.FieldTypeId,
                        dto.FieldValue,
                        // request.UnitId,
                        true,
                        cancellationToken
                    );
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشلت الفهرسة المباشرة للحقول الديناميكية بعد إنشاء الوحدة: {UnitId}", createdId);
            }

            return ResultDto<Guid>.Succeeded(createdId, "تم إنشاء الوحدة بنجاح مع قيم الحقول الديناميكية");
        }
    }
} 