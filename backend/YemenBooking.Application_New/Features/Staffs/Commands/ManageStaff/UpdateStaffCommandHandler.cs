using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Staffs;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Staffs.Commands.ManageStaff
{
    /// <summary>
    /// معالج أمر تحديث بيانات الموظف
    /// </summary>
    public class UpdateStaffCommandHandler : IRequestHandler<UpdateStaffCommand, ResultDto<bool>>
    {
        private readonly IStaffRepository _staffRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UpdateStaffCommandHandler> _logger;

        public UpdateStaffCommandHandler(
            IStaffRepository staffRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<UpdateStaffCommandHandler> logger)
        {
            _staffRepository = staffRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(UpdateStaffCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحديث موظف: StaffId={StaffId}", request.StaffId);

            // التحقق من المدخلات
            if (request.StaffId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الموظف مطلوب");
            if (request.Position == null && string.IsNullOrWhiteSpace(request.Permissions))
                return ResultDto<bool>.Failed("يجب تحديد منصب أو صلاحيات جديدة للتحديث");

            // التحقق من الوجود
            var staff = await _staffRepository.GetStaffByIdAsync(request.StaffId, cancellationToken);
            if (staff == null)
                return ResultDto<bool>.Failed("الموظف غير موجود");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            var property = await _staffRepository.GetPropertyByIdAsync(staff.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<bool>.Failed("الكيان المرتبط بالموظف غير موجود");
            if (_currentUserService.Role != "Admin" && property.OwnerId != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بتحديث بيانات الموظف");

            // تنفيذ التحديث
            if (request.Position.HasValue)
                staff.Position = request.Position.Value;
            if (!string.IsNullOrWhiteSpace(request.Permissions))
                staff.Permissions = request.Permissions.Trim();
            staff.UpdatedBy = _currentUserService.UserId;
            staff.UpdatedAt = DateTime.UtcNow;

            await _staffRepository.UpdateStaffAsync(staff, cancellationToken);

            // تسجيل التدقيق (يدوي) يتضمن اسم ومعرّف المنفذ
            var notes = $"تم تحديث بيانات الموظف {request.StaffId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "Staff",
                entityId: request.StaffId,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Updated = true }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل تحديث الموظف بنجاح: StaffId={StaffId}", request.StaffId);
            return ResultDto<bool>.Succeeded(true, "تم تحديث بيانات الموظف بنجاح");
        }
    }
} 