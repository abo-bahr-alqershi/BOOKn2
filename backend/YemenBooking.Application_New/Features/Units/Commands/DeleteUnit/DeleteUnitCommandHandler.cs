using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Events;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.Units.Commands.DeleteUnit
{
    /// <summary>
    /// معالج أمر حذف الوحدة
    /// </summary>
    public class DeleteUnitCommandHandler : IRequestHandler<DeleteUnitCommand, ResultDto<bool>>
    {
        private readonly IUnitRepository _unitRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<DeleteUnitCommandHandler> _logger;
        private readonly IUnitFieldValueRepository _valueRepository;
        private readonly IUnitTypeFieldRepository _fieldRepository;
        private readonly IMediator _mediator;
        private readonly IIndexingService _indexingService;
        private readonly IPropertyImageRepository _propertyImageRepository;
        private readonly IFileStorageService _fileStorageService;

        public DeleteUnitCommandHandler(
            IUnitRepository unitRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            IUnitFieldValueRepository valueRepository,
            IUnitTypeFieldRepository fieldRepository,
            IMediator mediator,
            ILogger<DeleteUnitCommandHandler> logger,
            IIndexingService indexingService,
            IPropertyImageRepository propertyImageRepository,
            IFileStorageService fileStorageService)
        {
            _unitRepository = unitRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _valueRepository = valueRepository;
            _fieldRepository = fieldRepository;
            _mediator = mediator;
            _logger = logger;
            _indexingService = indexingService;
            _propertyImageRepository = propertyImageRepository;
            _fileStorageService = fileStorageService;
        }

        public async Task<ResultDto<bool>> Handle(DeleteUnitCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء حذف الوحدة: UnitId={UnitId}", request.UnitId);

            // التحقق من المدخلات
            if (request.UnitId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الوحدة مطلوب");

            // التحقق من الوجود
            var unit = await _unitRepository.GetUnitByIdAsync(request.UnitId, cancellationToken);
            if (unit == null)
                return ResultDto<bool>.Failed("الوحدة غير موجودة");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            var property = await _propertyRepository.GetPropertyByIdAsync(unit.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<bool>.Failed("الكيان المرتبط بالوحدة غير موجود");
            var isAdmin = string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase)
                || string.Equals(_currentUserService.AccountRole, "Admin", StringComparison.OrdinalIgnoreCase)
                || (_currentUserService.UserRoles?.Any(r => string.Equals(r, "Admin", StringComparison.OrdinalIgnoreCase)) ?? false);
            if (!isAdmin && property.OwnerId != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بحذف هذه الوحدة");

            // منع الحذف إذا كان هناك أي حجوزات (بغض النظر عن الحالة) أو أي مدفوعات (حتى وإن كانت مستردة)
            var hasAnyBookings = await _unitRepository.HasAnyBookingsAsync(request.UnitId, cancellationToken);
            if (hasAnyBookings)
                return ResultDto<bool>.Failed("لا يمكن حذف الوحدة لوجود حجوزات مرتبطة بها حتى وإن كانت ملغاة أو سابقة");

            var hasAnyPayments = await _unitRepository.HasAnyPaymentsAsync(request.UnitId, cancellationToken);
            if (hasAnyPayments)
                return ResultDto<bool>.Failed("لا يمكن حذف الوحدة لوجود مدفوعات مرتبطة بحجوزاتها حتى وإن كانت مستردة");

            // حذف جميع صور الوحدة من قاعدة البيانات ومن التخزين الفعلي قبل حذف الوحدة
            try
            {
                var unitImages = await _propertyImageRepository.GetImagesByUnitAsync(request.UnitId, cancellationToken);
                foreach (var img in unitImages)
                {
                    if (!string.IsNullOrWhiteSpace(img.Url))
                    {
                        try { await _fileStorageService.DeleteFileAsync(img.Url, cancellationToken); } catch { /* best-effort */ }
                    }
                }
                await _propertyImageRepository.HardDeleteByUnitIdAsync(request.UnitId, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذر حذف بعض صور الوحدة {UnitId} قبل الحذف", request.UnitId);
            }

            // جلب قيم الحقول الديناميكية قبل الحذف (للاستخدام في الفهرسة بعد الحذف)
            var dynamicValues = await _valueRepository.GetValuesByUnitIdAsync(request.UnitId, cancellationToken);

            // تنفيذ الحذف
            bool removed = await _unitRepository.DeleteUnitAsync(request.UnitId, cancellationToken);
            if (!removed)
                return ResultDto<bool>.Failed("فشل حذف الوحدة");

            // فهرسة مباشرة + نشر حدث لضمان الاتساق
            try
            {
                await _indexingService.OnUnitDeletedAsync(request.UnitId, unit.PropertyId, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذر الفهرسة المباشرة بعد حذف الوحدة {UnitId}", request.UnitId);
            }
            // فهرسة مباشرة للحقول الديناميكية
            try
            {
                foreach (var value in dynamicValues)
                {
                    var def = await _fieldRepository.GetByIdAsync(value.UnitTypeFieldId, cancellationToken);
                    if (def == null) continue;
                    await _indexingService.OnDynamicFieldChangedAsync(
                        property.Id,
                        // value.Id,
                        def.FieldName,
                        // def.FieldTypeId,
                        value.FieldValue,
                        // request.UnitId,
                        false,
                        cancellationToken
                    );
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشلت الفهرسة المباشرة للحقول الديناميكية بعد حذف الوحدة: {UnitId}", request.UnitId);
            }

            // تسجيل التدقيق اليدوي مع القيم القديمة
            var oldValues = new { unit.Id, unit.PropertyId, unit.Name };
            await _auditService.LogAuditAsync(
                entityType: "Unit",
                entityId: request.UnitId,
                action: AuditAction.DELETE,
                oldValues: JsonSerializer.Serialize(oldValues),
                newValues: null,
                performedBy: _currentUserService.UserId,
                notes: $"تم حذف الوحدة {request.UnitId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل حذف الوحدة بنجاح: UnitId={UnitId}", request.UnitId);
            return ResultDto<bool>.Succeeded(true, "تم حذف الوحدة بنجاح");
        }
    }
} 