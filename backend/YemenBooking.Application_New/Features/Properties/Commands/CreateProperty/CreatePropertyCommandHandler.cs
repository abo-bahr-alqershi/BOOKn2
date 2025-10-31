using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Notifications;
using YemenBooking.Core.Enums;
using System.IO;
using System.Linq;
using System.Text.Json;
using YemenBooking.Application.Infrastructure.Persistence.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.Properties.Commands.CreateProperty
{
    /// <summary>
    /// معالج أمر إنشاء كيان جديد
    /// </summary>
    public class CreatePropertyCommandHandler : IRequestHandler<CreatePropertyCommand, ResultDto<Guid>>
    {
        private readonly IPropertyRepository _propertyRepository;
        private readonly IRoleRepository _roleRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly INotificationService _notificationService;
        private readonly IAuditService _auditService;
        private readonly IFileStorageService _fileStorageService;
        private readonly IPropertyImageRepository _propertyImageRepository;
        private readonly IIndexingService _indexingService;
        private readonly ILogger<CreatePropertyCommandHandler> _logger;
        private readonly IMediator _mediator;
        private readonly IFinancialAccountingService _financialAccountingService;
        private readonly IChartOfAccountRepository _chartOfAccountRepository;

        public CreatePropertyCommandHandler(
            IPropertyRepository propertyRepository,
            IRoleRepository roleRepository,
            ICurrentUserService currentUserService,
            INotificationService notificationService,
            IAuditService auditService,
            IFileStorageService fileStorageService,
            IPropertyImageRepository propertyImageRepository,
            IIndexingService indexingService,
            ILogger<CreatePropertyCommandHandler> logger,
            IMediator mediator,
            IFinancialAccountingService financialAccountingService,
            IChartOfAccountRepository chartOfAccountRepository)
        {
            _propertyRepository = propertyRepository;
            _roleRepository = roleRepository;
            _currentUserService = currentUserService;
            _notificationService = notificationService;
            _auditService = auditService;
            _fileStorageService = fileStorageService;
            _propertyImageRepository = propertyImageRepository;
            _indexingService = indexingService;
            _logger = logger;
            _mediator = mediator;
            _financialAccountingService = financialAccountingService;
            _chartOfAccountRepository = chartOfAccountRepository;
        }

        public async Task<ResultDto<Guid>> Handle(CreatePropertyCommand request, CancellationToken cancellationToken)
        {
            // Prevent duplicate property ownership
            var existingProperties = await _propertyRepository.GetPropertiesByOwnerAsync(request.OwnerId, cancellationToken);
            if (existingProperties.Any())
                return ResultDto<Guid>.Failed("المستخدم مالك كيان بالفعل");
            _logger.LogInformation("بدء إنشاء كيان جديد: Name={Name}, OwnerId={OwnerId}", request.Name, request.OwnerId);

            // التحقق من صحة المدخلات
            if (string.IsNullOrWhiteSpace(request.Name))
                return ResultDto<Guid>.Failed("اسم الكيان مطلوب");
            if (string.IsNullOrWhiteSpace(request.Address))
                return ResultDto<Guid>.Failed("عنوان الكيان مطلوب");
            if (request.OwnerId == Guid.Empty)
                return ResultDto<Guid>.Failed("معرف المالك مطلوب");
            if (request.PropertyTypeId == Guid.Empty)
                return ResultDto<Guid>.Failed("معرف نوع الكيان مطلوب");
            if (string.IsNullOrWhiteSpace(request.City))
                return ResultDto<Guid>.Failed("اسم المدينة مطلوب");
            if (request.StarRating < 1 || request.StarRating > 5)
                return ResultDto<Guid>.Failed("تقييم النجوم يجب أن يكون بين 1 و 5");
            if (request.Latitude < -90 || request.Latitude > 90)
                return ResultDto<Guid>.Failed("خط العرض يجب أن يكون بين -90 و 90");
            if (request.Longitude < -180 || request.Longitude > 180)
                return ResultDto<Guid>.Failed("خط الطول يجب أن يكون بين -180 و 180");

            // التحقق من وجود المالك ونوع الكيان
            var owner = await _propertyRepository.GetOwnerByIdAsync(request.OwnerId, cancellationToken);
            if (owner == null)
                return ResultDto<Guid>.Failed("المالك غير موجود");
            var propertyType = await _propertyRepository.GetPropertyTypeByIdAsync(request.PropertyTypeId, cancellationToken);
            if (propertyType == null)
                return ResultDto<Guid>.Failed("نوع الكيان غير موجود");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            if (_currentUserService.Role != "Admin" && request.OwnerId != _currentUserService.UserId)
                return ResultDto<Guid>.Failed("غير مصرح لك بإنشاء كيان جديد");

            // إنشاء الكيان بحالة انتظار الموافقة
            var property = new Property
            {
                OwnerId = request.OwnerId,
                TypeId = request.PropertyTypeId,
                Name = request.Name,
                Address = request.Address,
                ShortDescription = string.IsNullOrWhiteSpace(request.ShortDescription) ? null : request.ShortDescription,
                Description = request.Description,
                City = request.City.Trim(),
                Currency = string.IsNullOrWhiteSpace(request.Currency) ? "YER" : request.Currency!.ToUpperInvariant(),
                Latitude = (decimal)request.Latitude,
                Longitude = (decimal)request.Longitude,
                StarRating = request.StarRating,
                IsApproved = false,
                IsFeatured = request.IsFeatured ?? false,
                CreatedBy = _currentUserService.UserId,
                CreatedAt = DateTime.UtcNow
            };
            var created = await _propertyRepository.CreatePropertyAsync(property, cancellationToken);

            // إنشاء حسابات التتبع للعقار فور الإنشاء (إيرادات ومصروفات)
            // الإجراء المحاسبي: إنشاء حسابات تتبع
            // إنشاء حساب: إيرادات العقار #{PropertyId}
            // إنشاء حساب: مصروفات العقار #{PropertyId}
            // لا يوجد قيد محاسبي
            try
            {
                var rev = await _chartOfAccountRepository.GetPropertyAccountAsync(created.Id, AccountType.Revenue);
                if (rev == null)
                {
                    await _chartOfAccountRepository.CreatePropertyAccountAsync(created.Id, created.Name, AccountType.Revenue);
                    _logger.LogInformation("تم إنشاء حساب إيرادات للعقار {PropertyId}", created.Id);
                }

                var exp = await _chartOfAccountRepository.GetPropertyAccountAsync(created.Id, AccountType.Expenses);
                if (exp == null)
                {
                    await _chartOfAccountRepository.CreatePropertyAccountAsync(created.Id, created.Name, AccountType.Expenses);
                    _logger.LogInformation("تم إنشاء حساب مصروفات للعقار {PropertyId}", created.Id);
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذر إنشاء حسابات التتبع (إيرادات/مصروفات) للعقار {PropertyId}", created.Id);
            }

            // Assign 'Owner' role to the user
            var allRoles = await _roleRepository.GetAllRolesAsync(cancellationToken);
            var ownerRole = allRoles.FirstOrDefault(r => r.Name.Equals("Owner", StringComparison.OrdinalIgnoreCase));
            if (ownerRole != null)
                await _roleRepository.AssignRoleToUserAsync(request.OwnerId, ownerRole.Id, cancellationToken);

            // تسجيل العملية في سجل التدقيق (يدوي مع JSON للقيم الجديدة)
            await _auditService.LogAuditAsync(
                entityType: "Property",
                entityId: created.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(new {
                    created.Id,
                    created.Name,
                    created.Address,
                    created.City,
                    created.Currency,
                    created.StarRating,
                    created.IsApproved,
                    created.IsFeatured
                }),
                performedBy: _currentUserService.UserId,
                notes: $"تم إنشاء الكيان جديد {created.Id} باسم {created.Name} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            // إرسال إشعار للمراجعة إلى المالك
            await _notificationService.SendAsync(new NotificationRequest
            {
                UserId = request.OwnerId,
                Type = NotificationType.BookingCreated,
                Title = "تم إنشاء الكيان وينتظر الموافقة",
                Message = $"تم إنشاء الكيان '{created.Name}' ويحتاج إلى موافقة الإدارة"
            }, cancellationToken);

            _logger.LogInformation("اكتمل إنشاء الكيان: PropertyId={PropertyId}", created.Id);

            // نقل الصور المؤقتة المحددة في الكوماند إلى المسار الرسمي بعد إنشاء الكيان
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
                    var tempFolder = string.Join("/", folderSegments);                                        // e.g. "temp" or "temp/{tempKey}"
                    var sourceRelativePath = $"{tempFolder}/{fileName}";                                       // e.g. "temp/file.png"
                    var persistentFolder = ImageType.Management.ToString();                                    // e.g. "Management"
                    var destFolderPath = $"{persistentFolder}/{created.Id}";                                  // e.g. "Management/{propertyId}"
                    var destRelativePath = $"{destFolderPath}/{fileName}";
                    // العثور على السجل المؤقت المطابق للمسار في DB
                    var img = tempImages.FirstOrDefault(i => i.Url == relativePath);
                    if (img == null) continue;
                    // نقل الملف وإنشاء المجلد الوجهة إذا لزم الأمر
                    await _fileStorageService.MoveFileAsync(sourceRelativePath, destRelativePath, cancellationToken);
                    var newUrl = await _fileStorageService.GetFileUrlAsync(destRelativePath, null, cancellationToken);
                    img.PropertyId = created.Id;
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

                // بعد نقل كل الصور، عيّن الصورة الرئيسية قبل الحفظ النهائي
                var movedImages = await _propertyImageRepository.GetImagesByPropertyAsync(created.Id, cancellationToken);
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
            if (!string.IsNullOrWhiteSpace(request.TempKey) && (request.Images == null || !request.Images.Any()))
            {
                var tempImages = await _propertyImageRepository.GetImagesByTempKeyAsync(request.TempKey, cancellationToken);
                foreach (var img in tempImages)
                {
                    // انقل الملفات من temp/{tempKey} إلى المسار الرسمي
                    var absolutePath = new Uri(img.Url, UriKind.RelativeOrAbsolute).IsAbsoluteUri
                        ? new Uri(img.Url).AbsolutePath
                        : (img.Url.StartsWith("/") ? img.Url : "/" + img.Url);
                    var relativePath = Uri.UnescapeDataString(absolutePath);
                    var fileName = Path.GetFileName(relativePath);
                    var destFolderPath = $"{ImageType.Management}/{created.Id}";
                    var destRelativePath = $"{destFolderPath}/{fileName}";
                    var nameWithoutExt = Path.GetFileNameWithoutExtension(fileName);
                    var ext = Path.GetExtension(fileName);

                    // move main
                    await _fileStorageService.MoveFileAsync($"temp/{request.TempKey}/{fileName}", destRelativePath, cancellationToken);
                    var newUrl = await _fileStorageService.GetFileUrlAsync(destRelativePath, null, cancellationToken);
                    img.PropertyId = created.Id;
                    img.TempKey = null;
                    img.Url = newUrl;
                    img.Sizes = newUrl;
                    await _propertyImageRepository.UpdatePropertyImageAsync(img, cancellationToken);

                    // move thumbs if exist
                    var thumbnailSuffixes = new[] { "_thumb", "_thumb48", "_thumb64", "_poster" };
                    foreach (var suffix in thumbnailSuffixes)
                    {
                        await _fileStorageService.MoveFileAsync($"temp/{request.TempKey}/{nameWithoutExt}{suffix}{ext}", $"{destFolderPath}/{nameWithoutExt}{suffix}{ext}", cancellationToken);
                    }
                }

                // تعيين الصورة الرئيسية اعتماداً على الوسم IsMain/IsMainImage أو أول صورة
                var movedImages = await _propertyImageRepository.GetImagesByPropertyAsync(created.Id, cancellationToken);
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

            // تأكيد إدراج الفهرس مباشرة لضمان عدم فقدان الحدث في حال تعطل معالج الأحداث
            try
            {
                await _indexingService.OnPropertyCreatedAsync(created.Id, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذر الفهرسة المباشرة للعقار {PropertyId}", created.Id);
            }

            

            return ResultDto<Guid>.Succeeded(created.Id, "تم إنشاء الكيان بنجاح وينتظر الموافقة");
        }
    }
} 