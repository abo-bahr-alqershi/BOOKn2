using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Policies;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Policies.DTOs;
using YemenBooking.Application.Features;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Policies.Queries.GetAllPolicies
{
    /// <summary>
    /// معالج استعلام الحصول على جميع السياسات مع الصفحات
    /// Handler for getting all policies with pagination
    /// </summary>
    public class GetAllPoliciesQueryHandler : IRequestHandler<GetAllPoliciesQuery, PaginatedResult<PolicyDto>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly ILogger<GetAllPoliciesQueryHandler> _logger;
        private readonly ICurrentUserService _currentUserService;

        public GetAllPoliciesQueryHandler(
            IPolicyRepository policyRepository,
            ILogger<GetAllPoliciesQueryHandler> logger,
            ICurrentUserService currentUserService)
        {
            _policyRepository = policyRepository;
            _logger = logger;
            _currentUserService = currentUserService;
        }

        public async Task<PaginatedResult<PolicyDto>> Handle(GetAllPoliciesQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء الاستعلام عن جميع السياسات: Page={PageNumber}, Size={PageSize}, PropertyId={PropertyId}, PolicyType={PolicyType}", 
                request.PageNumber, request.PageSize, request.PropertyId, request.PolicyType);

            // بناء الاستعلام مع تحسينات الأداء
            // Note: HasQueryFilter already filters IsDeleted, but we add it explicitly for clarity
            var query = _policyRepository.GetQueryable()
                .Include(p => p.Property)
                .AsSplitQuery() // تحسين الأداء للـ Include
                .AsQueryable();
            
            // فلترة السياسات النشطة (نتحمل IsActive = null كـ true للسياسات القديمة)
            query = query.Where(p => p.IsActive);

            if (_currentUserService.Role != "Admin")
            {
                var userPropertyId = _currentUserService.PropertyId;
                if (userPropertyId.HasValue)
                {
                    query = query.Where(p => p.PropertyId == userPropertyId.Value);
                }
                else
                {
                    query = query.Where(p => false);
                }
            }

            // تطبيق الفلاتر
            if (request.PropertyId.HasValue && request.PropertyId.Value != Guid.Empty)
            {
                _logger.LogInformation("تطبيق فلتر PropertyId: {PropertyId}", request.PropertyId.Value);
                query = query.Where(p => p.PropertyId == request.PropertyId.Value);
            }

            if (request.PolicyType.HasValue)
            {
                _logger.LogInformation("تطبيق فلتر PolicyType: {PolicyType}", request.PolicyType.Value);
                query = query.Where(p => p.Type == request.PolicyType.Value);
            }

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var searchTerm = request.SearchTerm.ToLower();
                _logger.LogInformation("تطبيق فلتر البحث: {SearchTerm}", searchTerm);
                query = query.Where(p => 
                    p.Description.ToLower().Contains(searchTerm) ||
                    p.Rules.ToLower().Contains(searchTerm) ||
                    (p.Property != null && p.Property.Name.ToLower().Contains(searchTerm))
                );
            }

            // الحصول على العدد الكلي
            var totalCount = await query.CountAsync(cancellationToken);
            _logger.LogInformation("إجمالي السياسات بعد الفلترة: {TotalCount}", totalCount);

            // تطبيق الترتيب والصفحات
            var policies = await query
                .OrderByDescending(p => p.CreatedAt)
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .Select(p => new PolicyDto
                {
                    Id = p.Id,
                    PropertyId = p.PropertyId,
                    PropertyName = p.Property != null ? p.Property.Name : "غير متوفر",
                    PolicyType = p.Type,
                    Description = p.Description,
                    Rules = p.Rules,
                    CancellationWindowDays = p.CancellationWindowDays,
                    RequireFullPaymentBeforeConfirmation = p.RequireFullPaymentBeforeConfirmation,
                    MinimumDepositPercentage = p.MinimumDepositPercentage,
                    MinHoursBeforeCheckIn = p.MinHoursBeforeCheckIn,
                    CreatedAt = p.CreatedAt,
                    UpdatedAt = p.UpdatedAt,
                    IsActive = p.IsActive
                })
                .ToListAsync(cancellationToken);

            _logger.LogInformation("تم الحصول على {Count} سياسة من أصل {Total} في الصفحة {Page}", 
                policies.Count, totalCount, request.PageNumber);

            return new PaginatedResult<PolicyDto>
            {
                Items = policies,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalCount = totalCount
            };
        }
    }
}
