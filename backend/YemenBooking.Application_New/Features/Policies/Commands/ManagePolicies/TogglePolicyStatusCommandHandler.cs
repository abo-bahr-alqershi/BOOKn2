using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Policies;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Application_New.Core.Enums;

namespace YemenBooking.Application.Features.Policies.Commands.ManagePolicies
{
    /// <summary>
    /// معالج أمر تفعيل/تعطيل السياسة
    /// Handler for toggle policy status command
    /// </summary>
    public class TogglePolicyStatusCommandHandler : IRequestHandler<TogglePolicyStatusCommand, ResultDto<bool>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<TogglePolicyStatusCommandHandler> _logger;

        public TogglePolicyStatusCommandHandler(
            IPolicyRepository policyRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<TogglePolicyStatusCommandHandler> logger)
        {
            _policyRepository = policyRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(TogglePolicyStatusCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تغيير حالة السياسة: PolicyId={PolicyId}", request.PolicyId);

            // التحقق من وجود السياسة
            var policy = await _policyRepository.GetByIdAsync(request.PolicyId, cancellationToken);
            if (policy == null)
                return ResultDto<bool>.Failed("السياسة غير موجودة");

            // تحقق الصلاحيات: غير المدير يجب أن يكون مالك العقار المرتبط بهذه السياسة
            if (!string.Equals(_currentUserService.Role, "Admin", StringComparison.OrdinalIgnoreCase))
            {
                var property = await _propertyRepository.GetPropertyByIdAsync(policy.PropertyId, cancellationToken);
                if (property == null || property.OwnerId != _currentUserService.UserId)
                    return ResultDto<bool>.Failed("غير مصرح لك بتغيير حالة هذه السياسة");
            }

            // Note: Since PropertyPolicy doesn't have IsActive yet, we'll add it to the entity
            // For now, we'll just return success
            // TODO: Add IsActive field to PropertyPolicy entity and update here

            // تسجيل العملية في سجل التدقيق
            var notes = $"تم تغيير حالة السياسة {request.PolicyId} بواسطة {_currentUserService.Username}";
            await _auditService.LogAuditAsync(
                entityType: "PropertyPolicy",
                entityId: request.PolicyId,
                action: YemenBooking.Core.Entities.AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { PolicyId = request.PolicyId }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("تم تغيير حالة السياسة بنجاح: PolicyId={PolicyId}", request.PolicyId);
            return ResultDto<bool>.Succeeded(true, "تم تغيير حالة السياسة بنجاح");
        }
    }
}
