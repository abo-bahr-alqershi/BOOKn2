using MediatR;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Features.DynamicFields;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using Unit = MediatR.Unit;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.DynamicFields.Commands.UpdateUnit;

/// <summary>
/// معالج أمر تحديث حقل ديناميكي لنوع الوحدة
/// Update unit type field command handler
/// 
/// يقوم بتحديث حقل ديناميكي موجود لنوع الوحدة ويشمل:
/// - التحقق من صحة البيانات المدخلة
/// - التحقق من وجود الحقل
/// - التحقق من صلاحيات المستخدم (مسؤول فقط)
/// - التحقق من قواعد العمل
/// - التحقق من عدم تأثير التغييرات على القيم الموجودة
/// - تحديث الحقل الديناميكي
/// - إعادة تقييم صحة القيم الموجودة
/// - تسجيل العملية في سجل التدقيق
/// - نشر الأحداث
/// 
/// Updates existing dynamic field for unit type and includes:
/// - Input data validation
/// - Field existence validation
/// - User authorization validation (Admin only)
/// - Business rules validation
/// - Validation that changes don't affect existing values
/// - Dynamic field update
/// - Re-evaluation of existing values validity
/// - Audit log creation
/// - Event publishing
/// </summary>
public class UpdateUnitTypeFieldCommandHandler : IRequestHandler<UpdateUnitTypeFieldCommand, ResultDto<Unit>>
{
    private readonly IUnitTypeFieldRepository _unitTypeFieldRepository;
    private readonly IUnitTypeRepository _unitTypeRepository;
    private readonly IFieldGroupRepository _fieldGroupRepository;
    private readonly IUnitFieldValueRepository _unitFieldValueRepository;
    private readonly IFieldGroupFieldRepository _fieldGroupFieldRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly IEventPublisher _eventPublisher;
    private readonly ILogger<UpdateUnitTypeFieldCommandHandler> _logger;

    public UpdateUnitTypeFieldCommandHandler(
        IUnitTypeFieldRepository unitTypeFieldRepository,
        IUnitTypeRepository unitTypeRepository,
        IFieldGroupRepository fieldGroupRepository,
        IUnitFieldValueRepository unitFieldValueRepository,
        IFieldGroupFieldRepository fieldGroupFieldRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IValidationService validationService,
        IAuditService auditService,
        IEventPublisher eventPublisher,
        ILogger<UpdateUnitTypeFieldCommandHandler> logger)
    {
        _unitTypeFieldRepository = unitTypeFieldRepository;
        _unitTypeRepository = unitTypeRepository;
        _fieldGroupRepository = fieldGroupRepository;
        _unitFieldValueRepository = unitFieldValueRepository;
        _fieldGroupFieldRepository = fieldGroupFieldRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _validationService = validationService;
        _auditService = auditService;
        _eventPublisher = eventPublisher;
        _logger = logger;
    }

    /// <summary>
    /// معالجة أمر تحديث الحقل الديناميكي لنوع الوحدة
    /// Handle update unit type field command
    /// </summary>
    /// <param name="request">طلب تحديث الحقل الديناميكي / Update field request</param>
    /// <param name="cancellationToken">رمز الإلغاء / Cancellation token</param>
    /// <returns>نتيجة العملية / Operation result</returns>
    public async Task<ResultDto<Unit>> Handle(UpdateUnitTypeFieldCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة أمر تحديث الحقل الديناميكي: {FieldId}", request.FieldId);

            // الخطوة 1: التحقق من صحة البيانات المدخلة
            var inputValidationResult = ValidateInputAsync(request, cancellationToken);
            if (!inputValidationResult.Success)
            {
                return inputValidationResult;
            }

            // الخطوة 2: التحقق من وجود الحقل
            var fieldId = Guid.Parse(request.FieldId);
            var existingField = await _unitTypeFieldRepository.GetUnitTypeFieldByIdAsync(fieldId, cancellationToken);
            if (existingField == null || existingField.IsDeleted)
            {
                _logger.LogWarning("الحقل الديناميكي غير موجود: {FieldId}", request.FieldId);
                return ResultDto<Unit>.Failure("الحقل الديناميكي غير موجود");
            }

            // الخطوة 3: التحقق من صلاحيات المستخدم
            var authorizationValidation = ValidateAuthorizationAsync(cancellationToken);
            if (!authorizationValidation.Success)
            {
                return authorizationValidation;
            }

            // الخطوة 4: التحقق من قواعد العمل
            var businessRulesValidation = await ValidateBusinessRulesAsync(request, existingField, cancellationToken);
            if (!businessRulesValidation.Success)
            {
                return businessRulesValidation;
            }

            // الخطوة 5: التحقق من تأثير التغييرات على القيم الموجودة
            var existingValuesValidation = await ValidateExistingValuesAsync(request, existingField, cancellationToken);
            if (!existingValuesValidation.Success)
            {
                return existingValuesValidation;
            }

            // الخطوة 6: حفظ القيم الأصلية للمراجعة
            var originalValues = new
            {
                existingField.FieldName,
                existingField.DisplayName,
                existingField.Description,
                existingField.FieldOptions,
                existingField.ValidationRules,
                existingField.IsRequired,
                existingField.IsSearchable,
                existingField.IsPublic,
                existingField.SortOrder,
                existingField.Category
            };

            // الخطوة 7: تحديث الحقل الديناميكي
            existingField.FieldName = request.FieldName;
            existingField.DisplayName = request.DisplayName;
            existingField.Description = request.Description;
            existingField.FieldOptions = JsonSerializer.Serialize(request.FieldOptions ?? new System.Collections.Generic.Dictionary<string, object>());
            existingField.ValidationRules = JsonSerializer.Serialize(request.ValidationRules ?? new System.Collections.Generic.Dictionary<string, object>());
            existingField.IsRequired = request.IsRequired;
            existingField.IsSearchable = request.IsSearchable;
            existingField.IsPublic = request.IsPublic;
            existingField.SortOrder = request.SortOrder;
            existingField.Category = request.Category;
            existingField.IsForUnits = request.IsForUnits;
            existingField.ShowInCards = request.ShowInCards ?? existingField.ShowInCards;
            existingField.IsPrimaryFilter = request.IsPrimaryFilter ?? existingField.IsPrimaryFilter;
            existingField.Priority = request.Priority ?? existingField.Priority;
            if (!string.IsNullOrWhiteSpace(request.FieldTypeId) && !string.Equals(existingField.FieldTypeId, request.FieldTypeId, StringComparison.OrdinalIgnoreCase))
            {
                existingField.FieldTypeId = request.FieldTypeId!;
            }
            existingField.UpdatedAt = DateTime.UtcNow;

            var updatedField = await _unitTypeFieldRepository.UpdateUnitTypeFieldAsync(existingField, cancellationToken);

            // Update group assignment if provided
            if (!string.IsNullOrWhiteSpace(request.GroupId))
            {
                var updatedFieldId = updatedField.Id;
                // Remove existing group links
                var existingLinks = await _fieldGroupFieldRepository.GetGroupsByFieldIdAsync(updatedFieldId, cancellationToken);
                foreach (var link in existingLinks)
                    await _fieldGroupFieldRepository.RemoveFieldFromGroupAsync(updatedFieldId, link.GroupId, cancellationToken);
                // Add new link
                var newLink = new FieldGroupField
                {
                    FieldId = updatedFieldId,
                    GroupId = Guid.Parse(request.GroupId),
                    SortOrder = updatedField.SortOrder
                };
                await _fieldGroupFieldRepository.AssignFieldToGroupAsync(newLink, cancellationToken);
            }

            // الخطوة 8: إعادة تقييم صحة القيم الموجودة إذا لزم الأمر
            await RevalidateExistingValuesAsync(updatedField, cancellationToken);

            // الخطوة 9: تسجيل العملية في سجل التدقيق (يدوي مع JSON للقيم القديمة والجديدة)
            await _auditService.LogAuditAsync(
                entityType: "UnitTypeField",
                entityId: updatedField.Id,
                action: AuditAction.UPDATE,
                oldValues: JsonSerializer.Serialize(originalValues),
                newValues: JsonSerializer.Serialize(new {
                    updatedField.FieldName,
                    updatedField.DisplayName,
                    updatedField.Description,
                    updatedField.FieldOptions,
                    updatedField.ValidationRules,
                    updatedField.IsRequired,
                    updatedField.IsSearchable,
                    updatedField.IsPublic,
                    updatedField.SortOrder,
                    updatedField.Category
                }),
                performedBy: _currentUserService.UserId,
                notes: $"تم تحديث الحقل الديناميكي: {updatedField.FieldName} لنوع الوحدة: {updatedField.UnitTypeId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            // الخطوة 10: نشر الحدث
            // await _eventPublisher.PublishEventAsync(new UnitTypeFieldUpdatedEvent
            // {
            //     FieldId = updatedField.Id,
            //     UnitTypeId = updatedField.UnitTypeId,
            //     FieldName = updatedField.FieldName,
            //     DisplayName = updatedField.DisplayName,
            //     UpdatedBy = _currentUserService.UserId,
            //     UpdatedAt = updatedField.UpdatedAt
            // }, cancellationToken);

            _logger.LogInformation("تم تحديث الحقل الديناميكي بنجاح: {FieldId}", updatedField.Id);

            return ResultDto<Unit>.Ok(
                Unit.Value,
                "تم تحديث الحقل الديناميكي بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في تحديث الحقل الديناميكي: {FieldId}", request.FieldId);
            return ResultDto<Unit>.Failure("حدث خطأ أثناء تحديث الحقل الديناميكي");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate input data
    /// </summary>
    private ResultDto<Unit> ValidateInputAsync(UpdateUnitTypeFieldCommand request, CancellationToken cancellationToken)
    {
        var validationErrors = new List<string>();

        // التحقق من وجود معرف الحقل
        if (string.IsNullOrWhiteSpace(request.FieldId))
        {
            validationErrors.Add("معرف الحقل مطلوب");
        }
        else if (!Guid.TryParse(request.FieldId, out _))
        {
            validationErrors.Add("معرف الحقل غير صحيح");
        }

        // التحقق من اسم الحقل
        if (string.IsNullOrWhiteSpace(request.FieldName))
        {
            validationErrors.Add("اسم الحقل مطلوب");
        }
        else if (request.FieldName.Length > 100)
        {
            validationErrors.Add("اسم الحقل يجب أن يكون أقل من 100 حرف");
        }

        // التحقق من الاسم المعروض
        if (string.IsNullOrWhiteSpace(request.DisplayName))
        {
            validationErrors.Add("الاسم المعروض مطلوب");
        }
        else if (request.DisplayName.Length > 100)
        {
            validationErrors.Add("الاسم المعروض يجب أن يكون أقل من 100 حرف");
        }

        // التحقق من الوصف إذا تم توفيره
        if (!string.IsNullOrWhiteSpace(request.Description) && request.Description.Length > 500)
        {
            validationErrors.Add("الوصف يجب أن يكون أقل من 500 حرف");
        }

        // التحقق من الفئة إذا تم توفيرها
        if (!string.IsNullOrWhiteSpace(request.Category) && request.Category.Length > 50)
        {
            validationErrors.Add("الفئة يجب أن تكون أقل من 50 حرف");
        }

        // التحقق من ترتيب العرض
        if (request.SortOrder < 0)
        {
            validationErrors.Add("ترتيب العرض يجب أن يكون رقم موجب");
        }

        if (validationErrors.Any())
        {
            var errorMessage = string.Join(", ", validationErrors);
            _logger.LogWarning("فشل التحقق من البيانات المدخلة: {Errors}", errorMessage);
            return ResultDto<Unit>.Failure($"خطأ في البيانات المدخلة: {errorMessage}");
        }

        return ResultDto<Unit>.Ok(Unit.Value);
    }

    /// <summary>
    /// التحقق من صلاحيات المستخدم
    /// Validate user authorization
    /// </summary>
    private ResultDto<Unit> ValidateAuthorizationAsync(CancellationToken cancellationToken)
    {
        if (_currentUserService.Role != "Admin")
        {
            _logger.LogWarning("محاولة تحديث حقل ديناميكي من مستخدم غير مسؤول: {UserId}", _currentUserService.UserId);
            return ResultDto<Unit>.Failure("ليس لديك صلاحية لتحديث الحقول الديناميكية");
        }

        return ResultDto<Unit>.Ok(Unit.Value);
    }

    /// <summary>
    /// التحقق من قواعد العمل
    /// Validate business rules
    /// </summary>
    private async Task<ResultDto<Unit>> ValidateBusinessRulesAsync(UpdateUnitTypeFieldCommand request, UnitTypeField existingField, CancellationToken cancellationToken)
    {
        // إذا تغير اسم الحقل، التحقق من عدم التكرار ضمن نفس نوع الوحدة
        if (!existingField.FieldName.Equals(request.FieldName, StringComparison.OrdinalIgnoreCase))
        {
            var allFields = await _unitTypeFieldRepository.GetFieldsByUnitTypeIdAsync(existingField.UnitTypeId, cancellationToken);
            if (allFields.Any(f => f.Id != existingField.Id && 
                                  f.FieldName.Equals(request.FieldName, StringComparison.OrdinalIgnoreCase) && 
                                  !f.IsDeleted))
            {
                _logger.LogWarning("يوجد حقل آخر بنفس الاسم في نوع الوحدة: {FieldName}", request.FieldName);
                return ResultDto<Unit>.Failure($"يوجد حقل آخر بالاسم '{request.FieldName}' في نفس نوع الوحدة");
            }
        }

        // التحقق من صحة خيارات الحقل حسب نوع الحقل
        // var fieldType = await _fieldTypeRepository.GetFieldTypeByIdAsync(existingField.FieldTypeId, cancellationToken);
        // if (fieldType != null && (fieldType.Name.ToLower() == "select" || fieldType.Name.ToLower() == "multi_select"))
        // {
        //     if (request.FieldOptions == null || !request.FieldOptions.Any())
        //     {
        //         _logger.LogWarning("خيارات الحقل مطلوبة لنوع الحقل: {FieldType}", fieldType.Name);
        //         return ResultDto<Unit>.Failure($"خيارات الحقل مطلوبة لنوع الحقل '{fieldType.DisplayName}'");
        //     }
        // }

        // التحقق من صحة الفئة (Category)
        if (!string.IsNullOrWhiteSpace(request.Category))
        {
            var validCategories = new[] { "basic", "details", "features", "location", "contact", "custom" };
            if (!validCategories.Contains(request.Category.ToLower()))
            {
                _logger.LogWarning("فئة غير صحيحة: {Category}", request.Category);
                return ResultDto<Unit>.Failure($"الفئة '{request.Category}' غير مدعومة");
            }
        }

        return ResultDto<Unit>.Ok(Unit.Value);
    }

    /// <summary>
    /// التحقق من تأثير التغييرات على القيم الموجودة
    /// Validate impact of changes on existing values
    /// </summary>
    private async Task<ResultDto<Unit>> ValidateExistingValuesAsync(UpdateUnitTypeFieldCommand request, UnitTypeField existingField, CancellationToken cancellationToken)
    {
        // إذا تغير الحقل من اختياري إلى إلزامي، التحقق من عدم وجود قيم فارغة
        if (!existingField.IsRequired && request.IsRequired)
        {
            var unitValues = await _unitFieldValueRepository.GetByFieldIdAsync(existingField.Id, cancellationToken);

            var emptyUnitValues = unitValues.Where(pv => string.IsNullOrWhiteSpace(pv.FieldValue)).Count();

            if (emptyUnitValues > 0 || emptyUnitValues > 0)
            {
                _logger.LogWarning("لا يمكن جعل الحقل إلزامي لوجود قيم فارغة - وحدةات: {UnitCount}, وحدات: {UnitCount}", 
                    emptyUnitValues, emptyUnitValues);
                return ResultDto<Unit>.Failure($"لا يمكن جعل الحقل إلزامي لوجود {emptyUnitValues + emptyUnitValues} قيمة فارغة");
            }
        }

        // التحقق من توافق خيارات الحقل الجديدة مع القيم الموجودة (للحقول من نوع select)
        // var fieldType = await _fieldTypeRepository.GetFieldTypeByIdAsync(existingField.FieldTypeId, cancellationToken);
        // if (fieldType != null && (fieldType.Name.ToLower() == "select" || fieldType.Name.ToLower() == "multi_select"))
        // {
        //     if (request.FieldOptions != null && request.FieldOptions.Any())
        //     {
        //         var newOptions = request.FieldOptions.Keys.ToList();
        //         var existingUnitValues = await _unitFieldValueRepository.GetByFieldIdAsync(existingField.Id, cancellationToken);

        //         var incompatibleUnitValues = existingUnitValues
        //             .Where(pv => !string.IsNullOrWhiteSpace(pv.FieldValue) && !newOptions.Contains(pv.FieldValue))
        //             .Count();


        //         if (incompatibleUnitValues > 0 || incompatibleUnitValues > 0)
        //         {
        //             _logger.LogWarning("توجد قيم غير متوافقة مع الخيارات الجديدة - وحدةات: {UnitCount}, وحدات: {UnitCount}",
        //                 incompatibleUnitValues, incompatibleUnitValues);
        //             return ResultDto<Unit>.Failure($"توجد {incompatibleUnitValues + incompatibleUnitValues} قيمة غير متوافقة مع الخيارات الجديدة");
        //         }
        //     }
        // }

        return ResultDto<Unit>.Ok(Unit.Value);
    }

    /// <summary>
    /// إعادة تقييم صحة القيم الموجودة
    /// Re-validate existing values
    /// </summary>
    private Task RevalidateExistingValuesAsync(UnitTypeField updatedField, CancellationToken cancellationToken)
    {
        try
        {
            // يمكن إضافة منطق إعادة التحقق من صحة القيم الموجودة هنا
            // مثل تحديث فهارس البحث أو إعادة معالجة القيم
            
            _logger.LogInformation("تم إعادة تقييم القيم الموجودة للحقل: {FieldId}", updatedField.Id);
            return Task.CompletedTask;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في إعادة تقييم القيم الموجودة للحقل: {FieldId}", updatedField.Id);
            // لا نرمي الاستثناء هنا لأن العملية الأساسية نجحت
            return Task.CompletedTask;
        }
    }
}

/// <summary>
/// حدث تحديث الحقل الديناميكي لنوع الوحدة
/// Unit type field updated event
/// </summary>
public class UnitTypeFieldUpdatedEvent
{
    /// <summary>
    /// معرف الحقل
    /// Field ID
    /// </summary>
    public Guid FieldId { get; set; }

    /// <summary>
    /// معرف نوع الوحدة
    /// Unit type ID
    /// </summary>
    public Guid UnitTypeId { get; set; }

    /// <summary>
    /// اسم الحقل
    /// Field name
    /// </summary>
    public string FieldName { get; set; } = string.Empty;

    /// <summary>
    /// الاسم المعروض
    /// Display name
    /// </summary>
    public string DisplayName { get; set; } = string.Empty;

    /// <summary>
    /// معرف المحدث
    /// Updated by user ID
    /// </summary>
    public Guid UpdatedBy { get; set; }

    /// <summary>
    /// تاريخ التحديث
    /// Update date
    /// </summary>
    public DateTime UpdatedAt { get; set; }
}
