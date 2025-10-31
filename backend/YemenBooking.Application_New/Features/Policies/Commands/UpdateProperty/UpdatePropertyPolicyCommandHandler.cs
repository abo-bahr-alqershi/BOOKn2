using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Policies;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Policies.Commands.UpdateProperty
{
    /// <summary>
    /// معالج أمر تحديث سياسة الكيان
    /// </summary>
    public class UpdatePropertyPolicyCommandHandler : IRequestHandler<UpdatePropertyPolicyCommand, ResultDto<bool>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly IAuditService _auditService;
        private readonly ILogger<UpdatePropertyPolicyCommandHandler> _logger;

        public UpdatePropertyPolicyCommandHandler(
            IPolicyRepository policyRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            IAuditService auditService,
            ILogger<UpdatePropertyPolicyCommandHandler> logger)
        {
            _policyRepository = policyRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _auditService = auditService;
            _logger = logger;
        }

        public async Task<ResultDto<bool>> Handle(UpdatePropertyPolicyCommand request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحديث السياسة: PolicyId={PolicyId}", request.PolicyId);

            // التحقق من صحة المدخلات
            if (request.PolicyId == Guid.Empty)
                return ResultDto<bool>.Failed("معرف السياسة مطلوب");

            // التحقق من وجود السياسة
            var policy = await _policyRepository.GetPolicyByIdAsync(request.PolicyId, cancellationToken);
            if (policy == null)
                return ResultDto<bool>.Failed("السياسة غير موجودة");

            // التحقق من وجود الكيان المرتبط
            var property = await _propertyRepository.GetPropertyByIdAsync(policy.PropertyId, cancellationToken);
            if (property == null)
                return ResultDto<bool>.Failed("الكيان المرتبط بالسياسة غير موجود");

            // التحقق من الصلاحيات (مالك الكيان أو مسؤول)
            if (_currentUserService.Role != "Admin" && property.OwnerId != _currentUserService.UserId)
                return ResultDto<bool>.Failed("غير مصرح لك بتحديث هذه السياسة");

            // تنفيذ التحديث
            policy.Type = request.Type;
            policy.Description = request.Description;
            policy.Rules = request.Rules;
            
            if (request.CancellationWindowDays.HasValue)
                policy.CancellationWindowDays = request.CancellationWindowDays.Value;
            if (request.RequireFullPaymentBeforeConfirmation.HasValue)
                policy.RequireFullPaymentBeforeConfirmation = request.RequireFullPaymentBeforeConfirmation.Value;
            if (request.MinimumDepositPercentage.HasValue)
                policy.MinimumDepositPercentage = request.MinimumDepositPercentage.Value;
            if (request.MinHoursBeforeCheckIn.HasValue)
                policy.MinHoursBeforeCheckIn = request.MinHoursBeforeCheckIn.Value;
                
            policy.UpdatedBy = _currentUserService.UserId;
            policy.UpdatedAt = DateTime.UtcNow;
            await _policyRepository.UpdatePropertyPolicyAsync(policy, cancellationToken);

            // تسجيل العملية في سجل التدقيق (يدوي) مع ذكر اسم المستخدم والمعرف
            var notes = $"تم تحديث السياسة {request.PolicyId} بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "PropertyPolicy",
                entityId: request.PolicyId,
                action: AuditAction.UPDATE,
                oldValues: null,
                newValues: System.Text.Json.JsonSerializer.Serialize(new { Updated = true }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: cancellationToken);

            _logger.LogInformation("اكتمل تحديث السياسة: PolicyId={PolicyId}", request.PolicyId);
            return ResultDto<bool>.Succeeded(true, "تم تحديث السياسة بنجاح");
        }
    }
} 