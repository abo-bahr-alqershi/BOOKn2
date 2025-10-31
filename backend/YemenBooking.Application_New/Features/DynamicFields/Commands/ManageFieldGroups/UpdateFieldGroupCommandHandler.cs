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
using Unit = MediatR.Unit;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.DynamicFields.Commands.ManageFieldGroups;

/// <summary>
/// معالج أمر تحديث مجموعة الحقول
/// Update field group command handler
/// 
/// يقوم بتحديث مجموعة حقول موجودة ويشمل:
/// - التحقق من صحة البيانات المدخلة
/// - التحقق من وجود مجموعة الحقول
/// - التحقق من صلاحيات المستخدم (مسؤول فقط)
/// - التحقق من قواعد العمل
/// - تحديث مجموعة الحقول
/// - إبطال Cache
/// 
/// Updates existing field group and includes:
/// - Input data validation
/// - Field group existence validation
/// - User authorization validation (Admin only)
/// - Business rules validation
/// - Field group update
/// - Cache invalidation
/// </summary>
public class UpdateFieldGroupCommandHandler : IRequestHandler<UpdateFieldGroupCommand, ResultDto<Unit>>
{
    private readonly IFieldGroupRepository _fieldGroupRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentUserService _currentUserService;
    private readonly IValidationService _validationService;
    private readonly IAuditService _auditService;
    private readonly IEventPublisher _eventPublisher;
    private readonly ILogger<UpdateFieldGroupCommandHandler> _logger;

    public UpdateFieldGroupCommandHandler(
        IFieldGroupRepository fieldGroupRepository,
        IUnitOfWork unitOfWork,
        ICurrentUserService currentUserService,
        IValidationService validationService,
        IAuditService auditService,
        IEventPublisher eventPublisher,
        ILogger<UpdateFieldGroupCommandHandler> logger)
    {
        _fieldGroupRepository = fieldGroupRepository;
        _unitOfWork = unitOfWork;
        _currentUserService = currentUserService;
        _validationService = validationService;
        _auditService = auditService;
        _eventPublisher = eventPublisher;
        _logger = logger;
    }

    /// <summary>
    /// معالجة أمر تحديث مجموعة الحقول
    /// Handle update field group command
    /// </summary>
    /// <param name="request">طلب تحديث مجموعة الحقول / Update field group request</param>
    /// <param name="cancellationToken">رمز الإلغاء / Cancellation token</param>
    /// <returns>نتيجة العملية / Operation result</returns>
    public async Task<ResultDto<Unit>> Handle(UpdateFieldGroupCommand request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء معالجة أمر تحديث مجموعة الحقول: {GroupId}", request.GroupId);

            // الخطوة 1: التحقق من صحة البيانات المدخلة
            var inputValidationResult = await ValidateInputAsync(request, cancellationToken);
            if (!inputValidationResult.Success)
            {
                return inputValidationResult;
            }

            // الخطوة 2: التحقق من وجود مجموعة الحقول
            var groupId = Guid.Parse(request.GroupId);
            var existingFieldGroup = await _fieldGroupRepository.GetFieldGroupByIdAsync(groupId, cancellationToken);
            if (existingFieldGroup == null)
            {
                _logger.LogWarning("مجموعة الحقول غير موجودة: {GroupId}", request.GroupId);
                return ResultDto<Unit>.Failure("مجموعة الحقول غير موجودة");
            }

            // الخطوة 3: التحقق من صلاحيات المستخدم
            var authorizationValidation = await ValidateAuthorizationAsync(cancellationToken);
            if (!authorizationValidation.Success)
            {
                return authorizationValidation;
            }

            // الخطوة 4: التحقق من قواعد العمل
            var businessRulesValidation = await ValidateBusinessRulesAsync(request, existingFieldGroup, cancellationToken);
            if (!businessRulesValidation.Success)
            {
                return businessRulesValidation;
            }

            // الخطوة 5: حفظ القيم الأصلية للمراجعة
            var originalValues = new
            {
                existingFieldGroup.GroupName,
                existingFieldGroup.DisplayName,
                existingFieldGroup.Description,
                existingFieldGroup.SortOrder,
                existingFieldGroup.IsCollapsible,
                existingFieldGroup.IsExpandedByDefault
            };

            // الخطوة 6: تحديث مجموعة الحقول
            existingFieldGroup.GroupName = request.GroupName;
            existingFieldGroup.DisplayName = request.DisplayName;
            existingFieldGroup.Description = request.Description;
            existingFieldGroup.SortOrder = request.SortOrder;
            existingFieldGroup.IsCollapsible = request.IsCollapsible;
            existingFieldGroup.IsExpandedByDefault = request.IsExpandedByDefault;
            existingFieldGroup.UpdatedAt = DateTime.UtcNow;
            existingFieldGroup.UpdatedBy = _currentUserService.UserId;

            var updatedFieldGroup = await _fieldGroupRepository.UpdateFieldGroupAsync(existingFieldGroup, cancellationToken);

            // الخطوة 7: تسجيل العملية في سجل التدقيق
            await _auditService.LogActivityAsync(
                "FieldGroup",
                updatedFieldGroup.Id.ToString(),
                "Update",
                $"تم تحديث مجموعة الحقول: {updatedFieldGroup.GroupName}",
                originalValues,
                updatedFieldGroup,
                cancellationToken);

            // الخطوة 8: نشر الحدث
            // await _eventPublisher.PublishEventAsync(new FieldGroupUpdatedEvent
            // {
            //     FieldGroupId = updatedFieldGroup.Id,
            //     PropertyTypeId = updatedFieldGroup.UnitTypeId,
            //     GroupName = updatedFieldGroup.GroupName,
            //     DisplayName = updatedFieldGroup.DisplayName,
            //     UpdatedBy = _currentUserService.UserId,
            //     UpdatedAt = updatedFieldGroup.UpdatedAt
            // }, cancellationToken);

            _logger.LogInformation("تم تحديث مجموعة الحقول بنجاح: {GroupId}", updatedFieldGroup.Id);

            return ResultDto<Unit>.Ok(
                Unit.Value,
                "تم تحديث مجموعة الحقول بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في تحديث مجموعة الحقول: {GroupId}", request.GroupId);
            return ResultDto<Unit>.Failure("حدث خطأ أثناء تحديث مجموعة الحقول");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate input data
    /// </summary>
    private async Task<ResultDto<Unit>> ValidateInputAsync(UpdateFieldGroupCommand request, CancellationToken cancellationToken)
    {
        var validationResult = await _validationService.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            var errors = string.Join(", ", validationResult.Errors.Select(e => e.Message));
            _logger.LogWarning("بيانات غير صحيحة لتحديث مجموعة الحقول: {Errors}", errors);
            return ResultDto<Unit>.Failure($"بيانات غير صحيحة: {errors}");
        }

        // التحقق من صحة معرف المجموعة
        if (!Guid.TryParse(request.GroupId, out _))
        {
            _logger.LogWarning("معرف مجموعة الحقول غير صحيح: {GroupId}", request.GroupId);
            return ResultDto<Unit>.Failure("معرف مجموعة الحقول غير صحيح");
        }

        // التحقق من اسم المجموعة
        if (string.IsNullOrWhiteSpace(request.GroupName))
        {
            return ResultDto<Unit>.Failure("اسم المجموعة مطلوب");
        }

        if (request.GroupName.Length > 100)
        {
            return ResultDto<Unit>.Failure("اسم المجموعة لا يجب أن يتجاوز 100 حرف");
        }

        // التحقق من الاسم المعروض
        if (!string.IsNullOrWhiteSpace(request.DisplayName) && request.DisplayName.Length > 100)
        {
            return ResultDto<Unit>.Failure("الاسم المعروض لا يجب أن يتجاوز 100 حرف");
        }

        // التحقق من الوصف
        if (!string.IsNullOrWhiteSpace(request.Description) && request.Description.Length > 500)
        {
            return ResultDto<Unit>.Failure("الوصف لا يجب أن يتجاوز 500 حرف");
        }

        // التحقق من ترتيب الفرز
        if (request.SortOrder < 0)
        {
            return ResultDto<Unit>.Failure("ترتيب الفرز يجب أن يكون صفر أو أكبر");
        }

        return ResultDto<Unit>.Ok(Unit.Value);
    }

    /// <summary>
    /// التحقق من صلاحيات المستخدم
    /// Validate user authorization
    /// </summary>
    private Task<ResultDto<Unit>> ValidateAuthorizationAsync(CancellationToken cancellationToken)
    {
        if ( _currentUserService.Role !="Admin")
        {
            _logger.LogWarning("المستخدم {UserId} لا يملك صلاحية تحديث مجموعات الحقول", _currentUserService.UserId);
            return Task.FromResult(ResultDto<Unit>.Failure("غير مصرح لك بتحديث مجموعات الحقول"));
        }

        return Task.FromResult(ResultDto<Unit>.Ok(Unit.Value));
    }

    /// <summary>
    /// التحقق من قواعد العمل
    /// Validate business rules
    /// </summary>
    private async Task<ResultDto<Unit>> ValidateBusinessRulesAsync(UpdateFieldGroupCommand request, FieldGroup existingFieldGroup, CancellationToken cancellationToken)
    {
        // إذا تغير الاسم، التحقق من عدم التكرار
        if (!existingFieldGroup.GroupName.Equals(request.GroupName, StringComparison.OrdinalIgnoreCase))
        {
            var allGroups = await _fieldGroupRepository.GetGroupsByUnitTypeIdAsync(existingFieldGroup.UnitTypeId, cancellationToken);
            if (allGroups.Any(g => g.Id != existingFieldGroup.Id && 
                                  g.GroupName.Equals(request.GroupName, StringComparison.OrdinalIgnoreCase)))
            {
                _logger.LogWarning("يوجد مجموعة حقول أخرى بنفس الاسم: {GroupName}", request.GroupName);
                return ResultDto<Unit>.Failure($"يوجد مجموعة حقول أخرى بالاسم '{request.GroupName}' مسبقاً");
            }
        }

        // التحقق من صحة الإعدادات
        if (request.IsCollapsible && request.IsExpandedByDefault)
        {
            // هذا صحيح - يمكن أن تكون المجموعة قابلة للطي وموسعة افتراضياً
        }

        if (!request.IsCollapsible && !request.IsExpandedByDefault)
        {
            // هذا أيضاً صحيح - مجموعة غير قابلة للطي ومطوية
        }

        return ResultDto<Unit>.Ok(Unit.Value);
    }
}

/// <summary>
/// حدث تحديث مجموعة الحقول
/// Field group updated event
/// </summary>
public class FieldGroupUpdatedEvent
{
    public Guid FieldGroupId { get; set; }
    public Guid PropertyTypeId { get; set; }
    public string GroupName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public Guid UpdatedBy { get; set; }
    public DateTime UpdatedAt { get; set; }
}
