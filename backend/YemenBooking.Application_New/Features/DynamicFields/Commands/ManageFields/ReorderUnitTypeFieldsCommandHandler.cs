using System;
using System.Linq;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.DynamicFields;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Features.DynamicFields.DTOs;

namespace YemenBooking.Application.Features.DynamicFields.Commands.ManageFields
{
    /// <summary>
    /// معالج أمر إعادة ترتيب الحقول الديناميكية لنوع الوحدة
    /// Reorders dynamic fields for a unit type
    /// </summary>
    public class ReorderUnitTypeFieldsCommandHandler : IRequestHandler<ReorderUnitTypeFieldsCommand, ResultDto<bool>>
    {
        private readonly IUnitTypeRepository _unitTypeRepository;
        private readonly IUnitTypeFieldRepository _fieldRepository;
        private readonly IUnitOfWork _unitOfWork;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly IEventPublisher _eventPublisher;
        private readonly ILogger<ReorderUnitTypeFieldsCommandHandler> _logger;

        public ReorderUnitTypeFieldsCommandHandler(
            IUnitTypeRepository unitTypeRepository,
            IUnitTypeFieldRepository fieldRepository,
            IUnitOfWork unitOfWork,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            IEventPublisher eventPublisher,
            ILogger<ReorderUnitTypeFieldsCommandHandler> logger)
        {
            _unitTypeRepository = unitTypeRepository;
            _fieldRepository = fieldRepository;
            _unitOfWork = unitOfWork;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _eventPublisher = eventPublisher;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(ReorderUnitTypeFieldsCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إعادة ترتيب حقول نوع الوحدة {UnitTypeId}", request.UnitTypeId);

            if (!Guid.TryParse(request.UnitTypeId, out var unitTypeId))
                throw new BusinessRuleException("InvalidUnitTypeId", "معرف نوع الوحدة غير صالح");

            var unitType = await _unitTypeRepository.GetUnitTypeByIdAsync(unitTypeId, cancellationToken);
            if (unitType == null)
                throw new NotFoundException("UnitType", request.UnitTypeId);

            if (request.FieldOrders == null || !request.FieldOrders.Any())
                throw new BusinessRuleException("EmptyFieldOrders", "يجب توفير طلبات إعادة الترتيب");

            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                var existingFields = (await _fieldRepository.GetFieldsByUnitTypeIdAsync(unitTypeId, cancellationToken)).ToList();

                foreach (var order in request.FieldOrders)
                {
                    var field = existingFields.FirstOrDefault(f => f.Id == order.FieldId);
                    if (field == null)
                        throw new NotFoundException("UnitTypeField", order.FieldId.ToString());

                    field.SortOrder = order.SortOrder;
                    field.UpdatedBy = _currentUserService.UserId;
                    field.UpdatedAt = DateTime.UtcNow;
                    await _fieldRepository.UpdateUnitTypeFieldAsync(field, cancellationToken);
                }

                await _auditService.LogAuditAsync(
                    entityType: "UnitTypeField",
                    entityId: unitTypeId,
                    action: YemenBooking.Core.Entities.AuditAction.UPDATE,
                    oldValues: null,
                    newValues: null,
                    performedBy: _currentUserService.UserId,
                    notes: $"تم إعادة ترتيب حقول نوع الوحدة {unitTypeId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})",
                    cancellationToken: cancellationToken);

                // await _eventPublisher.PublishEventAsync(new UnitTypeFieldsReorderedEvent
                // {
                //     UnitTypeId = unitTypeId,
                //     FieldOrders = request.FieldOrders,
                //     ReorderedBy = _currentUserService.UserId,
                //     ReorderedAt = DateTime.UtcNow
                // }, cancellationToken);

                _logger.LogInformation("اكتملت إعادة ترتيب حقول نوع الوحدة: {UnitTypeId}", unitTypeId);
            });

            return ResultDto<bool>.Ok(true, "تم إعادة ترتيب حقول نوع الوحدة بنجاح");
        }
    }

    /// <summary>
    /// حدث إعادة ترتيب حقول نوع الوحدة
    /// Unit type fields reordered event
    /// </summary>
    public class UnitTypeFieldsReorderedEvent
    {
        public Guid UnitTypeId { get; set; }
        public List<FieldOrderDto> FieldOrders { get; set; }
        public Guid ReorderedBy { get; set; }
        public DateTime ReorderedAt { get; set; }
    }
} 