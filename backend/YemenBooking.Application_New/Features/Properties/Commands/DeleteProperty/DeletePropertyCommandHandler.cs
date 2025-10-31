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
using System.Text.Json;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.Properties.Commands.DeleteProperty
{
    /// <summary>
    /// معالج أمر حذف الكيان
    /// </summary>
    public class DeletePropertyCommandHandler : IRequestHandler<DeletePropertyCommand, ResultDto<bool>>
    {
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly IIndexingService _indexingService;
        private readonly ILogger<DeletePropertyCommandHandler> _logger;
        private readonly IMediator _mediator;
        private readonly IPropertyImageRepository _propertyImageRepository;
        private readonly IFileStorageService _fileStorageService;

        public DeletePropertyCommandHandler(
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            IIndexingService indexingService,
            ILogger<DeletePropertyCommandHandler> logger,
            IMediator mediator,
            IPropertyImageRepository propertyImageRepository,
            IFileStorageService fileStorageService)
        {
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _indexingService = indexingService;
            _logger = logger;
            _mediator = mediator;
            _propertyImageRepository = propertyImageRepository;
            _fileStorageService = fileStorageService;
        }

        public async Task<ResultDto<bool>> Handle(DeletePropertyCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء حذف الكيان: PropertyId={PropertyId}", request.PropertyId);

            if (request.PropertyId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الكيان مطلوب");

            var property = await _propertyRepository.GetPropertyByIdAsync(request.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<bool>.Failed("الكيان غير موجود");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            if (_currentUserService.Role != "Admin" && property.OwnerId != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بحذف هذا الكيان");

            // فحوصات الارتباطات الحرجة قبل الحذف
            var hasActiveBookings = await _propertyRepository.CheckActiveBookingsAsync(request.PropertyId, cancellationToken);
            if (hasActiveBookings)
                return ResultDto<bool>.Failed("لا يمكن حذف العقار لوجود حجوزات نشطة أو مستقبلية مرتبطة به أو بوحداته");

            var unitsCount = await _propertyRepository.GetUnitsCountAsync(request.PropertyId, cancellationToken);
            if (unitsCount > 0)
                return ResultDto<bool>.Failed($"لا يمكن حذف العقار لوجود {unitsCount} وحدة مرتبطة به. يرجى حذف أو نقل الوحدات أولاً");

            var servicesCount = await _propertyRepository.GetServicesCountAsync(request.PropertyId, cancellationToken);
            if (servicesCount > 0)
                return ResultDto<bool>.Failed($"لا يمكن حذف العقار لوجود {servicesCount} خدمة مرتبطة به. يرجى حذف الخدمات أولاً");

            var amenitiesCount = await _propertyRepository.GetAmenitiesCountAsync(request.PropertyId, cancellationToken);
            if (amenitiesCount > 0)
                return ResultDto<bool>.Failed($"لا يمكن حذف العقار لوجود {amenitiesCount} مرافق مرتبطة به. يرجى إزالة الربط بالمرافق أولاً");

            var paymentsCount = await _propertyRepository.GetPaymentsCountAsync(request.PropertyId, cancellationToken);
            if (paymentsCount > 0)
                return ResultDto<bool>.Failed($"لا يمكن حذف العقار لوجود {paymentsCount} مدفوعات مرتبطة بحجوزاته");

            // حذف جميع صور العقار من التخزين ومن قاعدة البيانات قبل حذف السجل
            try
            {
                var images = await _propertyImageRepository.GetImagesByPropertyAsync(request.PropertyId, cancellationToken);
                foreach (var img in images)
                {
                    if (!string.IsNullOrWhiteSpace(img.Url))
                    {
                        try { await _fileStorageService.DeleteFileAsync(img.Url, cancellationToken); } catch { /* best-effort */ }
                    }
                }
                // حذف دائم لسجلات الصور لتجنب أي فلتر SoftDelete قد يمنع الإزالة قبل حذف العقار
                await _propertyImageRepository.HardDeleteByPropertyIdAsync(request.PropertyId, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذر حذف بعض صور الكيان {PropertyId} قبل الحذف", request.PropertyId);
            }

            var success = await _propertyRepository.DeletePropertyAsync(request.PropertyId, cancellationToken);
            if (!success)
                return ResultDto<bool>.Failed("فشل حذف الكيان");

            // تسجيل العملية في سجل التدقيق (يدوي مع JSON للقيم القديمة)
            await _auditService.LogAuditAsync(
                entityType: "Property",
                entityId: request.PropertyId,
                action: AuditAction.DELETE,
                oldValues: JsonSerializer.Serialize(new {
                    property.Id,
                    property.Name,
                    property.Address,
                    property.City,
                    property.Currency
                }),
                newValues: null,
                performedBy: _currentUserService.UserId,
                notes: $"تم حذف الكيان {request.PropertyId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            // استدعاء الفهرسة المباشرة لضمان حذف العقار من الفهرس
            try
            {
                await _indexingService.OnPropertyDeletedAsync(request.PropertyId, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذر الفهرسة المباشرة للعقار {PropertyId}", request.PropertyId);
            }

            

            _logger.LogInformation("اكتمل حذف الكيان: PropertyId={PropertyId}", request.PropertyId);
            return ResultDto<bool>.Succeeded(true, "تم حذف الكيان بنجاح");
        }
    }
} 