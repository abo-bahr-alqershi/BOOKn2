using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;

namespace YemenBooking.Application.Features.Users.Commands.ManageRoles
{
    /// <summary>
    /// معالج أمر إنشاء دور جديد
    /// </summary>
    public class CreateRoleCommandHandler : IRequestHandler<CreateRoleCommand, ResultDto<Guid>>
    {
        private readonly IRoleRepository _roleRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<CreateRoleCommandHandler> _logger;

        public CreateRoleCommandHandler(
            IRoleRepository roleRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<CreateRoleCommandHandler> logger)
        {
            _roleRepository = roleRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<Guid>> Handle(CreateRoleCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إنشاء دور جديد: Name={Name}", request.Name);

            // التحقق من المدخلات
            if (string.IsNullOrWhiteSpace(request.Name))
                return ResultDto<Guid>.Failed("اسم الدور مطلوب");

            // التحقق من الصلاحيات (مسؤول عام)
            if (_currentUserService.Role != "Admin")
                return ResultDto<Guid>.Failed("غير مصرح لك بإنشاء أدوار");

            // التحقق من التكرار
            bool exists = await _roleRepository.ExistsAsync(r => r.Name.Trim().ToLower() == request.Name.Trim().ToLower(), cancellationToken);
            if (exists)
                return ResultDto<Guid>.Failed("يوجد دور بنفس الاسم");

            // إنشاء الكيان
            var role = new Role
            {
                Name = request.Name.Trim(),
                CreatedBy = _currentUserService.UserId,
                CreatedAt = DateTime.UtcNow
            };
            var created = await _roleRepository.CreateRoleAsync(role, cancellationToken);

            // تسجيل التدقيق (يدوي) يتضمن اسم ومعرّف المنفذ
            var notes = $"تم إنشاء دور جديد {created.Id} باسم {created.Name} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "Role",
                entityId: created.Id,
                action: AuditAction.CREATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { created.Id, created.Name }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل إنشاء الدور بنجاح: RoleId={RoleId}", created.Id);
            return ResultDto<Guid>.Succeeded(created.Id, "تم إنشاء الدور بنجاح");
        }
    }
} 