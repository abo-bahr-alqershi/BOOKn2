using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Features.Policies;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;
 using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Policies.Queries.GetPolicyById
{
    /// <summary>
    /// معالج استعلام الحصول على سياسة محددة
    /// Query handler for GetPolicyByIdQuery
    /// </summary>
    public class GetPolicyByIdQueryHandler : IRequestHandler<GetPolicyByIdQuery, ResultDto<PolicyDetailsDto>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetPolicyByIdQueryHandler> _logger;

        public GetPolicyByIdQueryHandler(
            IPolicyRepository policyRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            ILogger<GetPolicyByIdQueryHandler> logger)
        {
            _policyRepository = policyRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<PolicyDetailsDto>> Handle(GetPolicyByIdQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام السياسة: {PolicyId}", request.PolicyId);

            if (request.PolicyId == Guid.Empty)
                throw new ValidationException(nameof(request.PolicyId), "معرف السياسة غير صالح");

            var policy = await _policyRepository.GetPolicyByIdAsync(request.PolicyId, cancellationToken);
            if (policy == null)
                return ResultDto<PolicyDetailsDto>.Failure($"السياسة بالمعرف {request.PolicyId} غير موجودة");

            // Authorization for non-admins: must own the property of this policy
            if (_currentUserService.Role != "Admin")
            {
                var property = await _propertyRepository.GetPropertyByIdAsync(policy.PropertyId, cancellationToken);
                if (property == null || property.OwnerId != _currentUserService.UserId)
                    return ResultDto<PolicyDetailsDto>.Failed("غير مصرح لك بعرض هذه السياسة");
            }

            var dto = new PolicyDetailsDto
            {
                Id = policy.Id,
                PropertyId = policy.PropertyId,
                PolicyType = policy.Type,
                Description = policy.Description,
                Rules = policy.Rules,
                CancellationWindowDays = policy.CancellationWindowDays,
                RequireFullPaymentBeforeConfirmation = policy.RequireFullPaymentBeforeConfirmation,
                MinimumDepositPercentage = policy.MinimumDepositPercentage,
                MinHoursBeforeCheckIn = policy.MinHoursBeforeCheckIn,
                CreatedAt = policy.CreatedAt,
                UpdatedAt = policy.UpdatedAt,
                IsActive = true
            };

            return ResultDto<PolicyDetailsDto>.Ok(dto, "تم جلب بيانات السياسة بنجاح");
        }
    }
} 