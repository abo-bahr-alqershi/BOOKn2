using System;
using System.Collections.Generic;
using System.Linq;
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

namespace YemenBooking.Application.Features.Policies.Queries.GetPropertyPolicies
{
    /// <summary>
    /// معالج استعلام الحصول على سياسات الكيان
    /// Query handler for GetPropertyPoliciesQuery
    /// </summary>
    public class GetPropertyPoliciesQueryHandler : IRequestHandler<GetPropertyPoliciesQuery, ResultDto<IEnumerable<PolicyDto>>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetPropertyPoliciesQueryHandler> _logger;

        public GetPropertyPoliciesQueryHandler(
            IPolicyRepository policyRepository,
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            ILogger<GetPropertyPoliciesQueryHandler> logger)
        {
            _policyRepository = policyRepository;
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<IEnumerable<PolicyDto>>> Handle(GetPropertyPoliciesQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام سياسات الكيان: {PropertyId}", request.PropertyId);

            // Determine effective propertyId
            var effectivePropertyId = request.PropertyId;
            if (effectivePropertyId == Guid.Empty && _currentUserService.Role != "Admin")
            {
                effectivePropertyId = _currentUserService.PropertyId ?? Guid.Empty;
            }

            if (effectivePropertyId == Guid.Empty)
                throw new ValidationException(nameof(request.PropertyId), "معرف الكيان غير صالح");

            // Authorization for non-admins: must be the owner of the property
            if (_currentUserService.Role != "Admin")
            {
                var property = await _propertyRepository.GetPropertyByIdAsync(effectivePropertyId, cancellationToken);
                if (property == null || property.OwnerId != _currentUserService.UserId)
                    return ResultDto<IEnumerable<PolicyDto>>.Failed("غير مصرح لك بعرض سياسات هذا الكيان");
            }

            var policies = await _policyRepository.GetPropertyPoliciesAsync(effectivePropertyId, cancellationToken);

            var dtos = policies.Select(p => new PolicyDto
            {
                Id = p.Id,
                PropertyId = p.PropertyId,
                PolicyType = p.Type,
                Description = p.Description,
                Rules = p.Rules,
                CancellationWindowDays = p.CancellationWindowDays,
                RequireFullPaymentBeforeConfirmation = p.RequireFullPaymentBeforeConfirmation,
                MinimumDepositPercentage = p.MinimumDepositPercentage,
                MinHoursBeforeCheckIn = p.MinHoursBeforeCheckIn,
                CreatedAt = p.CreatedAt,
                UpdatedAt = p.UpdatedAt,
                IsActive = true
            }).ToList();

            return ResultDto<IEnumerable<PolicyDto>>.Ok(dtos, "تم جلب سياسات الكيان بنجاح");
        }
    }
}
 