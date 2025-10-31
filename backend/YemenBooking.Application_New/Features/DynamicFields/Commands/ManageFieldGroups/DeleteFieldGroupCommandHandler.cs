using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.DynamicFields;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Models;
using Microsoft.Extensions.Logging;
using System.ComponentModel.DataAnnotations;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.DynamicFields.Commands.ManageFieldGroups
{
    /// <summary>
    /// معالج أمر حذف مجموعة حقول
    /// Deletes a field group (soft delete) and includes:
    /// - Input data validation
    /// - Existence check
    /// - Authorization (Admin only)
    /// - Business rules validation
    /// - Soft delete
    /// - Audit logging
    /// - Event publishing
    /// </summary>
    public class DeleteFieldGroupCommandHandler : IRequestHandler<DeleteFieldGroupCommand, ResultDto<bool>>
    {
        private readonly IFieldGroupRepository _fieldGroupRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IValidationService _validationService;
        private readonly IAuditService _auditService;
        private readonly IEventPublisher _eventPublisher;
        private readonly ILogger<DeleteFieldGroupCommandHandler> _logger;

        public DeleteFieldGroupCommandHandler(
            IFieldGroupRepository fieldGroupRepository,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IValidationService validationService,
            IAuditService auditService,
            IEventPublisher eventPublisher,
            ILogger<DeleteFieldGroupCommandHandler> logger)
        {
            _fieldGroupRepository = fieldGroupRepository;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _validationService = validationService;
            _auditService = auditService;
            _eventPublisher = eventPublisher;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(DeleteFieldGroupCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء معالجة أمر حذف مجموعة الحقول: {GroupId}", request.GroupId);

            // التحقق من صحة المعرف
            if (!Guid.TryParse(request.GroupId, out var groupId))
                throw new ValidationException("معرف مجموعة الحقول غير صالح");

            // التحقق من وجود المجموعة
            var existingGroup = await _fieldGroupRepository.GetFieldGroupByIdAsync(groupId, cancellationToken);
            if (existingGroup == null)
                throw new ValidationException("مجموعة الحقول غير موجودة");

            // التحقق من صلاحيات المستخدم
            if (_currentUserService.Role != "Admin")
                throw new ValidationException("غير مصرح لك بحذف مجموعة الحقول");

            // قواعد العمل: التأكد من أن هذه ليست المجموعة الوحيدة
            var siblings = await _fieldGroupRepository.GetGroupsByUnitTypeIdAsync(existingGroup.UnitTypeId, cancellationToken);
            if (siblings != null && siblings.Count() <= 1)
                throw new ValidationException("لا يمكن حذف المجموعة الوحيدة لنوع الكيان");

            // تنفيذ الحذف الناعم ضمن معاملة
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // حذف ناعم
                var deleted = await _fieldGroupRepository.DeleteFieldGroupAsync(groupId, cancellationToken);
                if (!deleted)
                    throw new ValidationException("فشل حذف مجموعة الحقول");

                // تسجيل التدقيق
                await _auditService.LogActivityAsync(
                    "FieldGroup",
                    existingGroup.Id.ToString(),
                    "Delete",
                    $"تم حذف مجموعة الحقول: {existingGroup.GroupName}",
                    existingGroup,
                    null,
                    cancellationToken);

                // نشر الحدث
                // await _eventPublisher.PublishEventAsync(new FieldGroupDeletedEvent
                // {
                //     GroupId = existingGroup.Id,
                //     PropertyTypeId = existingGroup.UnitTypeId,
                //     GroupName = existingGroup.GroupName,
                //     DeletedBy = _currentUserService.UserId,
                //     DeletedAt = DateTime.UtcNow
                // }, cancellationToken);

                _logger.LogInformation("تم حذف مجموعة الحقول بنجاح: {GroupId}", existingGroup.Id);
            });

            return ResultDto<bool>.Ok(true, "تم حذف مجموعة الحقول بنجاح");
        }
    }

    /// <summary>
    /// حدث حذف مجموعة حقول
    /// Field group deleted event
    /// </summary>
    public class FieldGroupDeletedEvent
    {
        public Guid GroupId { get; set; }
        public Guid PropertyTypeId { get; set; }
        public string GroupName { get; set; } = string.Empty;
        public Guid DeletedBy { get; set; }
        public DateTime DeletedAt { get; set; }
    }
} 