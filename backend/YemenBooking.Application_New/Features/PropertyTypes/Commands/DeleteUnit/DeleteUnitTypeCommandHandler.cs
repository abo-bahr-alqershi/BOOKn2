using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.PropertyTypes;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.PropertyTypes.Commands.DeleteUnit
{
    /// <summary>
    /// معالج أمر حذف نوع الوحدة
    /// </summary>
    public class DeleteUnitTypeCommandHandler : IRequestHandler<DeleteUnitTypeCommand, ResultDto<bool>>
    {
        private readonly IUnitTypeRepository _repository;
        private readonly IUnitRepository _unitRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<DeleteUnitTypeCommandHandler> _logger;

        public DeleteUnitTypeCommandHandler(
            IUnitTypeRepository repository,
            IUnitRepository unitRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<DeleteUnitTypeCommandHandler> logger)
        {
            _repository = repository;
            _unitRepository = unitRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(DeleteUnitTypeCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء حذف نوع الوحدة: UnitTypeId={UnitTypeId}", request.UnitTypeId);

            // التحقق من المدخلات
            if (request.UnitTypeId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف نوع الوحدة مطلوب");

            // التحقق من الصلاحيات (مسؤول)
            if (_currentUserService.Role != "Admin")
                return ResultDto<bool>.Failed("غير مصرح لك بحذف نوع الوحدة");

            // التحقق من الوجود
            var unitType = await _repository.GetUnitTypeByIdAsync(request.UnitTypeId, cancellationToken);
            if (unitType == null)
                return ResultDto<bool>.Failed("نوع الوحدة غير موجود");

            // التحقق من عدم وجود وحدات مرتبطة
            bool hasUnits = await _unitRepository.ExistsAsync(u => u.UnitTypeId == request.UnitTypeId, cancellationToken);
            if (hasUnits)
                return ResultDto<bool>.Failed("لا يمكن حذف نوع الوحدة لوجود وحدات مرتبطة به");

            // تنفيذ الحذف
            var success = await _repository.DeleteUnitTypeAsync(request.UnitTypeId, cancellationToken);
            if (!success)
                return ResultDto<bool>.Failed("فشل حذف نوع الوحدة");

            // تسجيل التدقيق (يدوي) مع ذكر اسم المستخدم والمعرف
            var notes = $"تم حذف نوع الوحدة {request.UnitTypeId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "UnitType",
                entityId: request.UnitTypeId,
                action: AuditAction.DELETE,
                oldValues: System.Text.Json.JsonSerializer.Serialize(new { request.UnitTypeId }),
                newValues: null,
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل حذف نوع الوحدة: UnitTypeId={UnitTypeId}", request.UnitTypeId);
            return ResultDto<bool>.Succeeded(true, "تم حذف نوع الوحدة بنجاح");
        }
    }
} 