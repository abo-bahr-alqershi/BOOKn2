using MediatR;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Features.DynamicFields;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.DynamicFields.Commands.ManageFieldGroups;

/// <summary>
/// معالج أمر إنشاء مجموعة الحقول
/// Create field group command handler
/// 
/// يقوم بإنشاء مجموعة حقول جديدة ويشمل:
/// - التحقق من صحة البيانات المدخلة
/// - التحقق من وجود نوع الكيان
/// - التحقق من صلاحيات المستخدم (مسؤول فقط)
/// - التحقق من قواعد العمل
/// - إنشاء مجموعة الحقول
/// - تسجيل العملية في سجل التدقيق
/// 
/// Creates new field group and includes:
/// - Input data validation
/// - Property type existence validation
/// - User authorization validation (Admin only)
/// - Business rules validation
/// - Field group creation
/// - Audit log creation
/// </summary>
public class CreateFieldGroupCommandHandler : IRequestHandler<CreateFieldGroupCommand, ResultDto<string>>
{
    private readonly IFieldGroupRepository _fieldGroupRepository;
    private readonly IUnitTypeRepository _unitTypeRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly IEventPublisher _eventPublisher;
    private readonly ILogger<CreateFieldGroupCommandHandler> _logger;

    public CreateFieldGroupCommandHandler(
        IFieldGroupRepository fieldGroupRepository,
        IUnitTypeRepository unitTypeRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IValidationService validationService,
        IAuditService auditService,
        IEventPublisher eventPublisher,
        ILogger<CreateFieldGroupCommandHandler> logger)
    {
        _fieldGroupRepository = fieldGroupRepository;
        _unitTypeRepository = unitTypeRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _validationService = validationService;
        _auditService = auditService;
        _eventPublisher = eventPublisher;
        _logger = logger;
    }

    /// <summary>
    /// معالجة أمر إنشاء مجموعة الحقول
    /// Handle create field group command
    /// </summary>
    /// <param name="request">طلب إنشاء مجموعة الحقول / Create field group request</param>
    /// <param name="cancellationToken">رمز الإلغاء / Cancellation token</param>
    /// <returns>نتيجة العملية مع معرف مجموعة الحقول / Operation result with field group ID</returns>
    public async Task<ResultDto<string>> Handle(CreateFieldGroupCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة أمر إنشاء مجموعة الحقول لنوع الوحدة: {UnitTypeId}", request.unitTypeId);

            // الخطوة 1: التحقق من صحة البيانات المدخلة
            var inputValidationResult = await ValidateInputAsync(request, cancellationToken);
            if (!inputValidationResult.Success)
            {
                return inputValidationResult;
            }

            // الخطوة 2: التحقق من وجود نوع الوحدة
            var unitTypeId = Guid.Parse(request.unitTypeId);
            var unitType = await _unitTypeRepository.GetUnitTypeByIdAsync(unitTypeId, cancellationToken);
            if (unitType == null)
            {
                _logger.LogWarning("نوع الوحدة غير موجود: {UnitTypeId}", request.unitTypeId);
                return ResultDto<string>.Failure("نوع الوحدة غير موجود");
            }

            // الخطوة 3: التحقق من صلاحيات المستخدم
            var authorizationValidation = await ValidateAuthorizationAsync(cancellationToken);
            if (!authorizationValidation.Success)
            {
                return authorizationValidation;
            }

            // الخطوة 4: التحقق من قواعد العمل
            var businessRulesValidation = await ValidateBusinessRulesAsync(request, unitTypeId, cancellationToken);
            if (!businessRulesValidation.Success)
            {
                return businessRulesValidation;
            }

            // الخطوة 5: إنشاء مجموعة الحقول
            var fieldGroup = new FieldGroup
            {
                Id = Guid.NewGuid(),
                UnitTypeId = unitTypeId,
                GroupName = request.GroupName,
                DisplayName = request.DisplayName,
                Description = request.Description,
                SortOrder = request.SortOrder,
                IsCollapsible = request.IsCollapsible,
                IsExpandedByDefault = request.IsExpandedByDefault,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = _currentUserService.UserId,
                IsDeleted = false
            };

            var createdFieldGroup = await _fieldGroupRepository.CreateFieldGroupAsync(fieldGroup, cancellationToken);

            // الخطوة 6: إعادة ترتيب المجموعات الأخرى إذا لزم الأمر
            await ReorderExistingGroupsIfNeededAsync(unitTypeId, request.SortOrder, cancellationToken);

            // الخطوة 7: تسجيل العملية في سجل التدقيق
            await _auditService.LogActivityAsync(
                "FieldGroup",
                createdFieldGroup.Id.ToString(),
                "Create",
                $"تم إنشاء مجموعة حقول جديدة: {createdFieldGroup.GroupName}",
                null,
                createdFieldGroup,
                cancellationToken);

            // الخطوة 8: نشر الحدث
            // await _eventPublisher.PublishEventAsync(new FieldGroupCreatedEvent
            // {
            //     FieldGroupId = createdFieldGroup.Id,
            //     PropertyTypeId = createdFieldGroup.UnitTypeId,
            //     GroupName = createdFieldGroup.GroupName,
            //     DisplayName = createdFieldGroup.DisplayName,
            //     CreatedBy = _currentUserService.UserId,
            //     CreatedAt = createdFieldGroup.CreatedAt
            // }, cancellationToken);

            _logger.LogInformation("تم إنشاء مجموعة الحقول بنجاح: {FieldGroupId}", createdFieldGroup.Id);

            return ResultDto<string>.Ok(
                createdFieldGroup.Id.ToString(),
                "تم إنشاء مجموعة الحقول بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في إنشاء مجموعة الحقول: {GroupName}", request.GroupName);
            return ResultDto<string>.Failure("حدث خطأ أثناء إنشاء مجموعة الحقول");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate input data
    /// </summary>
    private async Task<ResultDto<string>> ValidateInputAsync(CreateFieldGroupCommand request, CancellationToken cancellationToken)
    {
        var validationResult = await _validationService.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            var errors = string.Join(", ", validationResult.Errors.Select(e => e.Message));
            _logger.LogWarning("بيانات غير صحيحة لإنشاء مجموعة الحقول: {Errors}", errors);
            return ResultDto<string>.Failure($"بيانات غير صحيحة: {errors}");
        }

        // التحقق من صحة معرف نوع الكيان
        if (!Guid.TryParse(request.unitTypeId, out _))
        {
            _logger.LogWarning("معرف نوع الكيان غير صحيح: {PropertyTypeId}", request.unitTypeId);
            return ResultDto<string>.Failure("معرف نوع الكيان غير صحيح");
        }

        // التحقق من اسم المجموعة
        if (string.IsNullOrWhiteSpace(request.GroupName))
        {
            return ResultDto<string>.Failure("اسم المجموعة مطلوب");
        }

        if (request.GroupName.Length > 100)
        {
            return ResultDto<string>.Failure("اسم المجموعة لا يجب أن يتجاوز 100 حرف");
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
    /// التحقق من صلاحيات المستخدم
    /// Validate user authorization
    /// </summary>
    private Task<ResultDto<string>> ValidateAuthorizationAsync(CancellationToken cancellationToken)
    {
        if (_currentUserService.Role != "Admin")
        {
            _logger.LogWarning("المستخدم {UserId} لا يملك صلاحية إنشاء مجموعات الحقول", _currentUserService.UserId);
            return Task.FromResult(ResultDto<string>.Failure("غير مصرح لك بإنشاء مجموعات الحقول"));
        }

        return Task.FromResult(ResultDto<string>.Ok(string.Empty));
    }

    /// <summary>
    /// التحقق من قواعد العمل
    /// Validate business rules
    /// </summary>
    private async Task<ResultDto<string>> ValidateBusinessRulesAsync(CreateFieldGroupCommand request, Guid propertyTypeId, CancellationToken cancellationToken)
    {
        // التحقق من عدم وجود مجموعة بنفس الاسم ضمن نفس نوع الكيان
        var existingGroups = await _fieldGroupRepository.GetGroupsByUnitTypeIdAsync(propertyTypeId, cancellationToken);
        if (existingGroups.Any(g => g.GroupName.Equals(request.GroupName, StringComparison.OrdinalIgnoreCase)))
        {
            _logger.LogWarning("يوجد مجموعة حقول بنفس الاسم في نوع الكيان: {GroupName}", request.GroupName);
            return ResultDto<string>.Failure($"يوجد مجموعة حقول بالاسم '{request.GroupName}' مسبقاً في هذا النوع من الكيانات");
        }

        // التحقق من صحة ترتيب الفرز
        var groupsWithSameSortOrder = existingGroups.Where(g => g.SortOrder == request.SortOrder).ToList();
        if (groupsWithSameSortOrder.Any())
        {
            _logger.LogInformation("يوجد مجموعات أخرى بنفس ترتيب الفرز، سيتم إعادة ترتيبها: {SortOrder}", request.SortOrder);
        }

        return ResultDto<string>.Ok(string.Empty);
    }

    /// <summary>
    /// إعادة ترتيب المجموعات الموجودة إذا لزم الأمر
    /// Reorder existing groups if needed
    /// </summary>
    private async Task ReorderExistingGroupsIfNeededAsync(Guid propertyTypeId, int newGroupSortOrder, CancellationToken cancellationToken)
    {
        var existingGroups = await _fieldGroupRepository.GetGroupsByUnitTypeIdAsync(propertyTypeId, cancellationToken);
        var groupsToUpdate = existingGroups
            .Where(g => g.SortOrder >= newGroupSortOrder)
            .OrderBy(g => g.SortOrder)
            .ToList();

        foreach (var group in groupsToUpdate)
        {
            group.SortOrder++;
            group.UpdatedAt = DateTime.UtcNow;
            group.UpdatedBy = _currentUserService.UserId;
            await _fieldGroupRepository.UpdateFieldGroupAsync(group, cancellationToken);
        }

        if (groupsToUpdate.Any())
        {
            _logger.LogInformation("تم إعادة ترتيب {Count} مجموعة حقول", groupsToUpdate.Count);
        }
    }
}

/// <summary>
/// حدث إنشاء مجموعة الحقول
/// Field group created event
/// </summary>
public class FieldGroupCreatedEvent
{
    public Guid FieldGroupId { get; set; }
    public Guid PropertyTypeId { get; set; }
    public string GroupName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public Guid CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
}
