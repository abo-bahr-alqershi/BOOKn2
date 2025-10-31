using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using System.Text.Json;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Users.Commands.DeleteUser
{
    /// <summary>
    /// معالج أمر إلغاء تفعيل حساب المستخدم
    /// </summary>
    public class DeactivateUserCommandHandler : IRequestHandler<DeactivateUserCommand, ResultDto<bool>>
    {
        private readonly IUserRepository _userRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<DeactivateUserCommandHandler> _logger;

        public DeactivateUserCommandHandler(
            IUserRepository userRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<DeactivateUserCommandHandler> logger)
        {
            _userRepository = userRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(DeactivateUserCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء إلغاء تفعيل المستخدم: UserId={UserId}", request.UserId);

            // التحقق من المدخلات
            if (request.UserId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف المستخدم مطلوب");

            // التحقق من الصلاحيات (مسؤول فقط)
            if (_currentUserService.Role != "Admin")
                return ResultDto<bool>.Failed("غير مصرح لك بإلغاء تفعيل المستخدم");

            // التحقق من الوجود
            var user = await _userRepository.GetUserByIdAsync(request.UserId, cancellationToken);
            if (user == null)
                return ResultDto<bool>.Failed("المستخدم غير موجود");

            // التنفيذ
            var result = await _userRepository.DeactivateUserAsync(request.UserId, cancellationToken);
            if (!result)
                return ResultDto<bool>.Failed("فشل إلغاء تفعيل المستخدم");

            // تسجيل التدقيق اليدوي
            var auditValues = new { UserId = request.UserId, Deactivated = true };
            await _auditService.LogAuditAsync(
                entityType: "User",
                entityId: request.UserId,
                action: AuditAction.DEACTIVATE,
                oldValues: null,
                newValues: JsonSerializer.Serialize(auditValues),
                performedBy: _currentUserService.UserId,
                notes: $"تم إلغاء تفعيل المستخدم {request.UserId}",
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل إلغاء تفعيل المستخدم بنجاح: UserId={UserId}", request.UserId);
            return ResultDto<bool>.Succeeded(true, "تم إلغاء تفعيل المستخدم بنجاح");
        }
    }
} 