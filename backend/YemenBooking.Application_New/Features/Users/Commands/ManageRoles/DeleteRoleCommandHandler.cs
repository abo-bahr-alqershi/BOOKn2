using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Users.Commands.ManageRoles
{
    /// <summary>
    /// معالج أمر حذف دور
    /// </summary>
    public class DeleteRoleCommandHandler : IRequestHandler<DeleteRoleCommand, ResultDto<bool>>
    {
        private readonly IRoleRepository _roleRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<DeleteRoleCommandHandler> _logger;

        public DeleteRoleCommandHandler(
            IRoleRepository roleRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<DeleteRoleCommandHandler> logger)
        {
            _roleRepository = roleRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(DeleteRoleCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء حذف الدور: RoleId={RoleId}", request.RoleId);

            // التحقق من المدخلات
            if (request.RoleId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الدور مطلوب");

            // التحقق من الصلاحيات (مسؤول عام)
            if (_currentUserService.Role != "Admin")
                return ResultDto<bool>.Failed("غير مصرح لك بحذف أدوار");

            // التحقق من الوجود
            var role = await _roleRepository.GetRoleByIdAsync(request.RoleId, cancellationToken);
            if (role == null)
                return ResultDto<bool>.Failed("الدور غير موجود");

            // تنفيذ الحذف
            bool deleted = await _roleRepository.DeleteRoleAsync(request.RoleId, cancellationToken);
            if (!deleted)
                return ResultDto<bool>.Failed("فشل حذف الدور");

            // تسجيل التدقيق (يدوي) يتضمن اسم ومعرّف المنفذ
            var notes = $"تم حذف الدور {request.RoleId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "Role",
                entityId: request.RoleId,
                action: AuditAction.DELETE,
                oldValues: System.Text.Json.JsonSerializer.Serialize(new { request.RoleId }),
                newValues: null,
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل حذف الدور بنجاح: RoleId={RoleId}", request.RoleId);
            return ResultDto<bool>.Succeeded(true, "تم حذف الدور بنجاح");
        }
    }
} 