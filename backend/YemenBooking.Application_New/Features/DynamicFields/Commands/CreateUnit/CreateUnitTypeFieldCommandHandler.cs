using MediatR;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
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
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.DynamicFields.Commands.CreateUnit;

/// <summary>
/// معالج أمر إنشاء حقل نوع الوحدة
/// Create unit type field command handler
/// 
/// يقوم بإنشاء حقل ديناميكي جديد لنوع الوحدة ويشمل:
/// - التحقق من صحة البيانات المدخلة
/// - التحقق من وجود نوع الوحدة ونوع الحقل
/// - التحقق من صلاحيات المستخدم (مسؤول فقط)
/// - التحقق من قواعد العمل
/// - إنشاء الحقل الديناميكي
/// - تسجيل العملية في سجل التدقيق
/// 
/// Creates new dynamic field for unit type and includes:
/// - Input data validation
/// - Unit type and field type existence validation
/// - User authorization validation (Admin only)
/// - Business rules validation
/// - Dynamic field creation
/// - Audit log creation
/// </summary>
public class CreateUnitTypeFieldCommandHandler : IRequestHandler<CreateUnitTypeFieldCommand, ResultDto<string>>
{
    private readonly IUnitTypeFieldRepository _unitTypeFieldRepository;
    private readonly IUnitTypeRepository _unitTypeRepository;
    private readonly IFieldGroupRepository _fieldGroupRepository;
    private readonly IFieldGroupFieldRepository _fieldGroupFieldRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly IEventPublisher _eventPublisher;
    private readonly ILogger<CreateUnitTypeFieldCommandHandler> _logger;

    public CreateUnitTypeFieldCommandHandler(
        IUnitTypeFieldRepository unitTypeFieldRepository,
        IUnitTypeRepository unitTypeRepository,
        IFieldGroupRepository fieldGroupRepository,
        IFieldGroupFieldRepository fieldGroupFieldRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IValidationService validationService,
        IAuditService auditService,
        IEventPublisher eventPublisher,
        ILogger<CreateUnitTypeFieldCommandHandler> logger)
    {
        _unitTypeFieldRepository = unitTypeFieldRepository;
        _unitTypeRepository = unitTypeRepository;
        _fieldGroupRepository = fieldGroupRepository;
        _fieldGroupFieldRepository = fieldGroupFieldRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _validationService = validationService;
        _auditService = auditService;
        _eventPublisher = eventPublisher;
        _logger = logger;
    }

    /// <summary>
    /// معالجة أمر إنشاء حقل نوع الوحدة
    /// Handle create unit type field command
    /// </summary>
    /// <param name="request">طلب إنشاء حقل نوع الوحدة / Create unit type field request</param>
    /// <param name="cancellationToken">رمز الإلغاء / Cancellation token</param>
    /// <returns>نتيجة العملية مع معرف الحقل / Operation result with field ID</returns>
    public async Task<ResultDto<string>> Handle(CreateUnitTypeFieldCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة أمر إنشاء حقل نوع الوحدة: {FieldName} لنوع الوحدة: {UnitTypeId}", 
                request.FieldName, request.UnitTypeId);

            // الخطوة 1: التحقق من صحة البيانات المدخلة
            var inputValidationResult = await ValidateInputAsync(request, cancellationToken);
            if (!inputValidationResult.Success)
            {
                return inputValidationResult;
            }

            // الخطوة 2: التحقق من وجود نوع الوحدة ونوع الحقل
            var entityValidationResult = await ValidateEntitiesExistenceAsync(request, cancellationToken);
            if (!entityValidationResult.Success)
            {
                return entityValidationResult;
            }

            // الخطوة 3: التحقق من صلاحيات المستخدم
            var authorizationValidation = await ValidateAuthorizationAsync(cancellationToken);
            if (!authorizationValidation.Success)
            {
                return authorizationValidation;
            }

            // الخطوة 4: التحقق من قواعد العمل
            var businessRulesValidation = await ValidateBusinessRulesAsync(request, cancellationToken);
            if (!businessRulesValidation.Success)
            {
                return businessRulesValidation;
            }

            // الخطوة 5: إنشاء حقل نوع الوحدة
            var unitTypeField = new UnitTypeField
            {
                Id = Guid.NewGuid(),
                UnitTypeId = Guid.Parse(request.UnitTypeId),
                FieldTypeId = request.FieldTypeId,
                FieldName = request.FieldName,
                DisplayName = request.DisplayName,
                Description = request.Description ?? string.Empty,
                FieldOptions = JsonConvert.SerializeObject(request.FieldOptions ?? new System.Collections.Generic.Dictionary<string, object>()),
                ValidationRules = JsonConvert.SerializeObject(request.ValidationRules ?? new System.Collections.Generic.Dictionary<string, object>()),
                IsRequired = request.IsRequired,
                IsSearchable = request.IsSearchable,
                IsPublic = request.IsPublic,
                SortOrder = request.SortOrder,
                Category = request.Category ?? string.Empty,
                IsForUnits = request.IsForUnits,
                ShowInCards = request.ShowInCards,
                IsPrimaryFilter = request.IsPrimaryFilter,
                Priority = request.Priority,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = _currentUserService.UserId,
                IsDeleted = false
            };

            var createdField = await _unitTypeFieldRepository.CreateUnitTypeFieldAsync(unitTypeField, cancellationToken);

            // الخطوة 6: إضافة الحقل للمجموعة المحددة إذا كانت متوفرة
            if (!string.IsNullOrWhiteSpace(request.GroupId))
            {
                await AssignFieldToGroupAsync(createdField.Id, Guid.Parse(request.GroupId), cancellationToken);
            }

            // الخطوة 7: تسجيل العملية في سجل التدقيق (يدوي مع JSON واضح)
            await _auditService.LogAuditAsync(
                entityType: "UnitTypeField",
                entityId: createdField.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new {
                    createdField.Id,
                    createdField.UnitTypeId,
                    createdField.FieldTypeId,
                    createdField.FieldName,
                    createdField.DisplayName,
                    createdField.IsRequired,
                    createdField.IsSearchable,
                    createdField.IsPublic,
                    createdField.SortOrder,
                    createdField.Category
                }),
                performedBy: _currentUserService.UserId,
                notes: $"تم إنشاء حقل جديد: {createdField.FieldName} لنوع الوحدة: {createdField.UnitTypeId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                cancellationToken: cancellationToken);

            // الخطوة 8: نشر الحدث
            // await _eventPublisher.PublishEventAsync(new UnitTypeFieldCreatedEvent
            // {
            //     FieldId = createdField.Id,
            //     UnitTypeId = createdField.UnitTypeId,
            //     FieldTypeId = createdField.FieldTypeId,
            //     FieldName = createdField.FieldName,
            //     DisplayName = createdField.DisplayName,
            //     IsRequired = createdField.IsRequired,
            //     CreatedBy = _currentUserService.UserId,
            //     CreatedAt = createdField.CreatedAt
            // }, cancellationToken);

            _logger.LogInformation("تم إنشاء حقل نوع الوحدة بنجاح: {FieldId}", createdField.Id);

            return ResultDto<string>.Ok(
                createdField.Id.ToString(),
                "تم إنشاء الحقل بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في إنشاء حقل نوع الوحدة: {FieldName}", request.FieldName);
            return ResultDto<string>.Failure("حدث خطأ أثناء إنشاء الحقل");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate input data
    /// </summary>
    private async Task<ResultDto<string>> ValidateInputAsync(CreateUnitTypeFieldCommand request, CancellationToken cancellationToken)
    {
        var validationResult = await _validationService.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            var errors = string.Join(", ", validationResult.Errors.Select(e => e.Message));
            _logger.LogWarning("بيانات غير صحيحة لإنشاء حقل نوع الوحدة: {Errors}", errors);
            return ResultDto<string>.Failure($"بيانات غير صحيحة: {errors}");
        }

        // التحقق من صحة المعرفات
        if (!Guid.TryParse(request.UnitTypeId, out _))
        {
            return ResultDto<string>.Failure("معرف نوع الوحدة غير صحيح");
        }

        if (string.IsNullOrWhiteSpace(request.FieldTypeId))
        {
            return ResultDto<string>.Failure("معرف نوع الحقل غير صحيح");
        }

        if (!string.IsNullOrWhiteSpace(request.GroupId) && !Guid.TryParse(request.GroupId, out _))
        {
            return ResultDto<string>.Failure("معرف المجموعة غير صحيح");
        }

        // التحقق من اسم الحقل
        if (string.IsNullOrWhiteSpace(request.FieldName))
        {
            return ResultDto<string>.Failure("اسم الحقل مطلوب");
        }

        if (request.FieldName.Length > 100)
        {
            return ResultDto<string>.Failure("اسم الحقل لا يجب أن يتجاوز 100 حرف");
        }

        // التحقق من الاسم المعروض
        if (!string.IsNullOrWhiteSpace(request.DisplayName) && request.DisplayName.Length > 100)
        {
            return ResultDto<string>.Failure("الاسم المعروض لا يجب أن يتجاوز 100 حرف");
        }

        // التحقق من الوصف
        if (!string.IsNullOrWhiteSpace(request.Description) && request.Description.Length > 500)
        {
            return ResultDto<string>.Failure("الوصف لا يجب أن يتجاوز 500 حرف");
        }

        // التحقق من ترتيب الفرز
        if (request.SortOrder < 0)
        {
            return ResultDto<string>.Failure("ترتيب الفرز يجب أن يكون صفر أو أكبر");
        }

        return ResultDto<string>.Ok(string.Empty);
    }

    /// <summary>
    /// التحقق من وجود الكيانات المطلوبة
    /// Validate required entities existence
    /// </summary>
    private async Task<ResultDto<string>> ValidateEntitiesExistenceAsync(CreateUnitTypeFieldCommand request, CancellationToken cancellationToken)
    {
        // التحقق من وجود نوع الوحدة
        var unitTypeId = Guid.Parse(request.UnitTypeId);
        var unitType = await _unitTypeRepository.GetByIdAsync(unitTypeId, cancellationToken);
        if (unitType == null)
        {
            _logger.LogWarning("نوع الوحدة غير موجود: {UnitTypeId}", request.UnitTypeId);
            return ResultDto<string>.Failure("نوع الوحدة غير موجود");
        }

        // التحقق من وجود المجموعة إذا كانت محددة
        if (!string.IsNullOrWhiteSpace(request.GroupId))
        {
            var groupId = Guid.Parse(request.GroupId);
            var fieldGroup = await _fieldGroupRepository.GetFieldGroupByIdAsync(groupId, cancellationToken);
            if (fieldGroup == null)
            {
                _logger.LogWarning("مجموعة الحقول غير موجودة: {GroupId}", request.GroupId);
                return ResultDto<string>.Failure("مجموعة الحقول غير موجودة");
            }

            // التحقق من أن المجموعة تنتمي لنفس نوع الوحدة
            if (fieldGroup.UnitTypeId != unitTypeId)
            {
                _logger.LogWarning("مجموعة الحقول لا تنتمي لنفس نوع الوحدة: {GroupId}", request.GroupId);
                return ResultDto<string>.Failure("مجموعة الحقول لا تنتمي لنفس نوع الوحدة");
            }
        }

        return ResultDto<string>.Ok(string.Empty);
    }

    /// <summary>
    /// التحقق من صلاحيات المستخدم
    /// Validate user authorization
    /// </summary>
    private Task<ResultDto<string>> ValidateAuthorizationAsync(CancellationToken cancellationToken)
    {
        if (_currentUserService.Role != "Admin" )
        {
            _logger.LogWarning("المستخدم {UserId} لا يملك صلاحية إنشاء حقول نوع الوحدة", _currentUserService.UserId);
            return Task.FromResult(ResultDto<string>.Failure("غير مصرح لك بإنشاء حقول نوع الوحدة"));
        }

        return Task.FromResult(ResultDto<string>.Ok(string.Empty));
    }

    /// <summary>
    /// التحقق من قواعد العمل
    /// Validate business rules
    /// </summary>
    private async Task<ResultDto<string>> ValidateBusinessRulesAsync(CreateUnitTypeFieldCommand request, CancellationToken cancellationToken)
    {
        var unitTypeId = Guid.Parse(request.UnitTypeId);

        // التحقق من عدم وجود حقل بنفس الاسم ضمن نفس نوع الوحدة
        var existingFields = await _unitTypeFieldRepository.GetFieldsByUnitTypeIdAsync(unitTypeId, cancellationToken);
        if (existingFields.Any(f => f.FieldName.Equals(request.FieldName, StringComparison.OrdinalIgnoreCase)))
        {
            _logger.LogWarning("يوجد حقل بنفس الاسم في نوع الوحدة: {FieldName}", request.FieldName);
            return ResultDto<string>.Failure($"يوجد حقل بالاسم '{request.FieldName}' مسبقاً في هذا النوع من الوحدةات");
        }

        // التحقق من صحة الفئة
        if (!string.IsNullOrWhiteSpace(request.Category))
        {
            // var validCategories = new[] { "basic", "location", "features", "pricing", "contact", "custom" };
            // if (!validCategories.Contains(request.Category.ToLower()))
            // {
            //     return ResultDto<string>.Failure("فئة الحقل غير صحيحة");
            // }
        }

        return ResultDto<string>.Ok(string.Empty);
    }

    /// <summary>
    /// إضافة الحقل للمجموعة المحددة
    /// Assign field to specified group
    /// </summary>
    private async Task AssignFieldToGroupAsync(Guid fieldId, Guid groupId, CancellationToken cancellationToken)
    {
        try
        {
            var fieldGroupField = new FieldGroupField
            {
                FieldId = fieldId,
                GroupId = groupId,
                SortOrder = 0, // سيتم تحديده لاحقاً حسب الحاجة
                CreatedAt = DateTime.UtcNow,
                CreatedBy = _currentUserService.UserId,
                IsDeleted = false
            };

            await _fieldGroupFieldRepository.AssignFieldToGroupAsync(fieldGroupField, cancellationToken);
            _logger.LogInformation("تم إضافة الحقل {FieldId} للمجموعة {GroupId}", fieldId, groupId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في إضافة الحقل للمجموعة: {FieldId} -> {GroupId}", fieldId, groupId);
            // لا نوقف العملية، لأن الحقل تم إنشاؤه بنجاح
        }
    }
}

/// <summary>
/// حدث إنشاء حقل نوع الوحدة
/// Unit type field created event
/// </summary>
public class UnitTypeFieldCreatedEvent
{
    public Guid FieldId { get; set; }
    public Guid UnitTypeId { get; set; }
    public string FieldTypeId { get; set; }
    public required string FieldName { get; set; }
    public required string DisplayName { get; set; }
    public bool IsRequired { get; set; }
    public Guid CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
}
