using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Users;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Accounting.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Users.Commands.ManageRoles
{
    /// <summary>
    /// معالج أمر تخصيص دور للمستخدم
    /// </summary>
    public class AssignUserRoleCommandHandler : IRequestHandler<AssignUserRoleCommand, ResultDto<bool>>
    {
        private readonly IUserRepository _userRepository;
        private readonly IRoleRepository _roleRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<AssignUserRoleCommandHandler> _logger;
        private readonly IFinancialAccountingService _financialAccountingService;
        private readonly IUnitOfWork _unitOfWork;

        public AssignUserRoleCommandHandler(
            IUserRepository userRepository,
            IRoleRepository roleRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<AssignUserRoleCommandHandler> logger,
            IFinancialAccountingService financialAccountingService,
            IUnitOfWork unitOfWork)
        {
            _userRepository = userRepository;
            _roleRepository = roleRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
            _financialAccountingService = financialAccountingService;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<bool>> Handle(AssignUserRoleCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تخصيص دور للمستخدم: UserId={UserId}, RoleId={RoleId}", request.UserId, request.RoleId);

            // التحقق من المدخلات
            if (request.UserId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف المستخدم مطلوب");
            if (request.RoleId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف الدور مطلوب");

            // التحقق من الصلاحيات (مسؤول عام فقط)
            if (_currentUserService.Role != "Admin")
                return ResultDto<bool>.Failed("غير مصرح لك بتخصيص دور");

            // التحقق من الوجود
            var user = await _userRepository.GetUserByIdAsync(request.UserId, cancellationToken);
            if (user == null)
                return ResultDto<bool>.Failed("المستخدم غير موجود");
            var role = await _roleRepository.GetRoleByIdAsync(request.RoleId, cancellationToken);
            if (role == null)
                return ResultDto<bool>.Failed("الدور غير موجود");

            // الحصول على الأدوار الحالية
            var assignedRoles = await _userRepository.GetUserRolesAsync(request.UserId, cancellationToken);
            
            // التحقق من عدم التكرار
            if (assignedRoles.Any(r => r.RoleId == request.RoleId))
            {
                // إذا كان الدور مسنداً بالفعل، نعتبر ذلك نجاحاً (idempotent operation)
                _logger.LogInformation("الدور {RoleId} مخصص بالفعل للمستخدم {UserId}، سيتم تجاهل هذه العملية", request.RoleId, request.UserId);
                return ResultDto<bool>.Succeeded(true, "الدور مخصص للمستخدم بالفعل");
            }

            // التحقق من عدم وجود عمليات مالية للمستخدم قبل تغيير الدور
            if (assignedRoles.Any())
            {
                var hasTransactions = await _financialAccountingService.HasFinancialTransactionsAsync(request.UserId);
                if (hasTransactions)
                {
                    _logger.LogWarning("لا يمكن تغيير دور المستخدم {UserId} لأنه مرتبط بعمليات مالية", request.UserId);
                    return ResultDto<bool>.Failed("لا يمكن تغيير دور المستخدم لأنه مرتبط بعمليات مالية. يجب إلغاء أو نقل جميع العمليات المالية أولاً / Cannot change user role because they have financial transactions. All financial operations must be cancelled or transferred first");
                }
            }

            // حذف الأدوار السابقة + تخصيص الدور الجديد + إنشاء حسابات المالك (إن كان الدور مالك) ضمن ترانزاكشن واحدة
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                foreach (var oldRole in assignedRoles)
                {
                    _logger.LogInformation("حذف الدور القديم {OldRoleId} من المستخدم {UserId}", oldRole.RoleId, request.UserId);
                    var removeResult = await _roleRepository.RemoveRoleFromUserAsync(request.UserId, oldRole.RoleId, cancellationToken);
                    if (!removeResult)
                    {
                        _logger.LogWarning("فشل حذف الدور القديم {OldRoleId} من المستخدم {UserId}", oldRole.RoleId, request.UserId);
                    }
                }

                var result = await _roleRepository.AssignRoleToUserAsync(request.UserId, request.RoleId, cancellationToken);
                if (!result)
                    throw new InvalidOperationException("FAILED_TO_ASSIGN_ROLE");

                // إنشاء حسابات المالك المالية إذا كان الدور مالك
                var roleName = role.Name?.Trim().ToLowerInvariant() ?? string.Empty;
                if (roleName == "owner" || roleName == "hotel_owner" || roleName.Contains("owner"))
                {
                    var created = await _financialAccountingService.CreateOwnerFinancialAccountsAsync(user.Id, user.Name, cancellationToken);
                    if (!created)
                        throw new InvalidOperationException("FAILED_TO_CREATE_OWNER_FINANCIAL_ACCOUNTS");
                }
            }, cancellationToken);

            // تسجيل التدقيق اليدوي مع القيم القديمة والجديدة للأدوار
            var oldRoleIds = assignedRoles.Select(r => r.RoleId).ToList();
            var newRoleIds = new[] { request.RoleId };
            await _auditService.LogAuditAsync(
                entityType: "UserRole",
                entityId: request.UserId,
                action: AuditAction.UPDATE,
                oldValues: JsonSerializer.Serialize(new { Roles = oldRoleIds }),
                newValues: JsonSerializer.Serialize(new { Roles = newRoleIds }),
                performedBy: _currentUserService.UserId,
                notes: $"تم تخصيص الدور {request.RoleId} للمستخدم {request.UserId}",
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل تخصيص الدور بنجاح: UserId={UserId}, RoleId={RoleId}", request.UserId, request.RoleId);
            return ResultDto<bool>.Succeeded(true, "تم تخصيص الدور للمستخدم بنجاح");
        }
    }
} 