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
using System.Linq;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Enums;
using System.IO;
using YemenBooking.Core.Events;
using System.Collections.Generic;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.Units.Commands.UpdateUnit
{
    /// <summary>
    /// معالج أمر تحديث بيانات الوحدة
    /// </summary>
    public class UpdateUnitCommandHandler : IRequestHandler<UpdateUnitCommand, ResultDto<bool>>
    {
        private readonly IUnitRepository _unitRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly IUnitFieldValueRepository _valueRepository;
        private readonly IUnitTypeFieldRepository _fieldRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UpdateUnitCommandHandler> _logger;
        private readonly IMediator _mediator;
        private readonly IFileStorageService _fileStorageService;
        private readonly IPropertyImageRepository _propertyImageRepository;
        private readonly IIndexingService _indexingService;

        public UpdateUnitCommandHandler(
            IUnitRepository unitRepository,
            IPropertyRepository propertyRepository,
            IUnitFieldValueRepository valueRepository,
            IUnitOfWork unitOfWork,
            IUnitTypeFieldRepository fieldRepository,
            IFileStorageService fileStorageService,
            IPropertyImageRepository propertyImageRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            IMediator mediator,
            ILogger<UpdateUnitCommandHandler> logger,
            IIndexingService indexingService)
        {
            _unitRepository = unitRepository;
            _propertyRepository = propertyRepository;
            _fieldRepository = fieldRepository;
            _valueRepository = valueRepository;
            _unitOfWork = unitOfWork;
            _fileStorageService = fileStorageService;
            _propertyImageRepository = propertyImageRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _mediator = mediator;
            _logger = logger;
            _indexingService = indexingService;
        }

        public async Task<ResultDto<bool>> Handle(UpdateUnitCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحديث بيانات الوحدة: UnitId={UnitId}", request.UnitId);

            // التحقق من المدخلات
            if (request.UnitId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الوحدة مطلوب");
            if (request.Name != null && string.IsNullOrWhiteSpace(request.Name))
                return ResultDto<bool>.Failed("اسم الوحدة المطلوب غير صالح");
            if (request.BasePrice != null && request.BasePrice.Amount <= 0)
                return ResultDto<bool>.Failed("السعر الأساسي يجب أن يكون أكبر من صفر");

            // التحقق المنطقي لنافذة الإلغاء
            if (request.AllowsCancellation.HasValue && request.AllowsCancellation.Value == false && request.CancellationWindowDays.HasValue)
                request.CancellationWindowDays = null; // لا يمكن تعيين نافذة إلغاء إذا كانت الإلغاء غير مسموح به
            if (request.CancellationWindowDays.HasValue && request.CancellationWindowDays.Value < 0)
                return ResultDto<bool>.Failed("نافذة الإلغاء يجب أن تكون صفر أو أكثر");

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
                return ResultDto<bool>.Failed("غير مصرح لك بتحديث بيانات هذه الوحدة");

            // التحقق من التكرار عند تغيير الاسم
            if (!string.IsNullOrWhiteSpace(request.Name) && !string.Equals(unit.Name, request.Name.Trim(), StringComparison.OrdinalIgnoreCase))
            {
                bool duplicate = await _unitRepository.ExistsAsync(u => u.PropertyId == unit.PropertyId && u.Name.Trim() == request.Name.Trim() && u.Id != request.UnitId, cancellationToken);
                if (duplicate)
                    return ResultDto<bool>.Failed("يوجد وحدة أخرى بنفس الاسم في هذا الكيان");
                unit.Name = request.Name.Trim();
            }

            // التحقق من صحة قيم الحقول الديناميكية حسب التعريفات
            var fieldDefs = await _fieldRepository.GetFieldsByUnitTypeIdAsync(unit.UnitTypeId, cancellationToken);
            foreach (var def in fieldDefs)
            {
                var dto = request.FieldValues.FirstOrDefault(f => f.FieldId == def.Id);
                if (def.IsRequired && (dto == null || string.IsNullOrWhiteSpace(dto.FieldValue)))
                    return ResultDto<bool>.Failed($"الحقل {def.DisplayName} مطلوب.");
                if (dto != null && (def.FieldTypeId == "number" || def.FieldTypeId == "currency" || def.FieldTypeId == "percentage" || def.FieldTypeId == "range"))
                {
                    if (!decimal.TryParse(dto.FieldValue, out _))
                        return ResultDto<bool>.Failed($"قيمة الحقل {def.DisplayName} يجب أن تكون رقمًا.");
                }
            }
            // تحديث الوحدة وقيم الحقول الديناميكية في معاملة واحدة
            bool success = false;
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // تطبيق التحديثات الممكنة على الوحدة
                if (request.BasePrice != null)
                    unit.BasePrice = new Money(request.BasePrice.Amount, request.BasePrice.Currency);
                if (!string.IsNullOrWhiteSpace(request.CustomFeatures))
                    unit.CustomFeatures = request.CustomFeatures.Trim();
                if (request.PricingMethod.HasValue)
                    unit.PricingMethod = request.PricingMethod.Value;
                if (request.AllowsCancellation.HasValue)
                {
                    unit.AllowsCancellation = request.AllowsCancellation.Value;
                    if (!unit.AllowsCancellation)
                    {
                        // إذا تم إيقاف الإلغاء، نظف نافذة الإلغاء
                        unit.CancellationWindowDays = null;
                    }
                    else if (request.CancellationWindowDays.HasValue)
                    {
                        unit.CancellationWindowDays = request.CancellationWindowDays;
                    }
                }
                else if (request.CancellationWindowDays.HasValue)
                {
                    // تحديث نافذة الإلغاء عند عدم تغيير سماحية الإلغاء
                    unit.CancellationWindowDays = request.CancellationWindowDays;
                }

                unit.UpdatedBy = _currentUserService.UserId;
                unit.UpdatedAt = DateTime.UtcNow;

                await _unitRepository.UpdateUnitAsync(unit, cancellationToken);

                // جلب القيم الحالية للحقل
                var existingValues = (await _valueRepository.GetValuesByUnitIdAsync(request.UnitId, cancellationToken))
                    .ToDictionary(v => v.UnitTypeFieldId);
                var incomingIds = request.FieldValues.Select(f => f.FieldId).ToHashSet();

                // تحديث أو إنشاء قيم الحقول الديناميكية
                foreach (var dto in request.FieldValues)
                {
                    if (existingValues.TryGetValue(dto.FieldId, out var entity))
                    {
                        entity.FieldValue = dto.FieldValue;
                        entity.UpdatedBy = _currentUserService.UserId;
                        entity.UpdatedAt = DateTime.UtcNow;
                        await _valueRepository.UpdateUnitFieldValueAsync(entity, cancellationToken);
                    }
                    else
                    {
                        if (dto.FieldId == Guid.Empty)
                            throw new BusinessRuleException("InvalidFieldId", "معرف الحقل غير صالح");
                        var newValue = new UnitFieldValue
                        {
                            UnitId = unit.Id,
                            UnitTypeFieldId = dto.FieldId,
                            FieldValue = dto.FieldValue,
                            CreatedBy = _currentUserService.UserId,
                            CreatedAt = DateTime.UtcNow
                        };
                        await _valueRepository.CreateUnitFieldValueAsync(newValue, cancellationToken);
                    }
                }

                // حذف القيم التي أزيلت
                foreach (var kv in existingValues)
                {
                    if (!incomingIds.Contains(kv.Key))
                        await _valueRepository.DeleteUnitFieldValueAsync(kv.Value.Id, cancellationToken);
                }

                // تسجيل التدقيق اليدوي بالقيم القديمة والجديدة
                var oldValues = new
                {
                    unit.Id,
                    unit.Name,
                    unit.BasePrice,
                    unit.CustomFeatures,
                    unit.PricingMethod,
                    unit.AllowsCancellation,
                    unit.CancellationWindowDays
                };
                var newValues = new
                {
                    unit.Id,
                    unit.Name,
                    unit.BasePrice,
                    unit.CustomFeatures,
                    unit.PricingMethod,
                    unit.AllowsCancellation,
                    unit.CancellationWindowDays
                };
                await _auditService.LogAuditAsync(
                    entityType: "Unit",
                    entityId: request.UnitId,
                    action: AuditAction.UPDATE,
                    oldValues: JsonSerializer.Serialize(oldValues),
                    newValues: JsonSerializer.Serialize(newValues),
                    performedBy: _currentUserService.UserId,
                    notes: $"تم تحديث بيانات الوحدة {request.UnitId} مع قيم الحقول الديناميكية بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                    cancellationToken: cancellationToken);

                _logger.LogInformation("اكتمل تحديث بيانات الوحدة بنجاح: UnitId={UnitId}", request.UnitId);
                success = true;
            });

            // فهرسة مباشرة + نشر حدث لضمان الاتساق
            try
            {
                await _indexingService.OnUnitUpdatedAsync(request.UnitId, unit.PropertyId, cancellationToken);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "تعذر الفهرسة المباشرة للوحدة {UnitId}", request.UnitId);
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
                        false,
                        cancellationToken
                    );
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "فشلت الفهرسة المباشرة للحقول الديناميكية بعد تحديث الوحدة: {UnitId}", request.UnitId);
            }
            return ResultDto<bool>.Succeeded(success, "تم تحديث بيانات الوحدة بنجاح مع قيم الحقول الديناميكية");
        }
    }
} 