using System.Linq;
using System.Collections.Generic;
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

namespace YemenBooking.Application.Features.Policies.Queries.GetPolicyStats
{
    /// <summary>
    /// معالج استعلام الحصول على إحصائيات السياسات
    /// Handler for getting policy statistics
    /// </summary>
    public class GetPolicyStatsQueryHandler : IRequestHandler<GetPolicyStatsQuery, ResultDto<PolicyStatsDto>>
    {
        private readonly IPolicyRepository _policyRepository;
        private readonly ILogger<GetPolicyStatsQueryHandler> _logger;
        private readonly ICurrentUserService _currentUserService;

        public GetPolicyStatsQueryHandler(
            IPolicyRepository policyRepository,
            ILogger<GetPolicyStatsQueryHandler> logger,
            ICurrentUserService currentUserService)
        {
            _policyRepository = policyRepository;
            _logger = logger;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<PolicyStatsDto>> Handle(GetPolicyStatsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء الحصول على إحصائيات السياسات");

            var query = _policyRepository.GetQueryable();
            if (_currentUserService.Role != "Admin")
            {
                var propId = _currentUserService.PropertyId;
                if (propId.HasValue)
                {
                    query = query.Where(p => p.PropertyId == propId.Value);
                }
                else
                {
                    // لا يوجد معرف عقار مرتبط بالمستخدم غير المدير
                    return ResultDto<PolicyStatsDto>.Succeeded(new PolicyStatsDto
                    {
                        TotalPolicies = 0,
                        ActivePolicies = 0,
                        PoliciesByType = 0,
                        PolicyTypeDistribution = new Dictionary<string, int>(),
                        AverageCancellationWindow = 0
                    });
                }
            }
            else if (request.PropertyId.HasValue && request.PropertyId.Value != Guid.Empty)
            {
                // للمشرف: في حال تمرير PropertyId نقيد الإحصائيات عليه
                query = query.Where(p => p.PropertyId == request.PropertyId.Value);
            }

            var policies = await query.ToListAsync(cancellationToken);

            var stats = new PolicyStatsDto
            {
                TotalPolicies = policies.Count,
                ActivePolicies = policies.Count, // Since we don't have IsActive yet
                PoliciesByType = policies.GroupBy(p => p.Type).Count(),
                PolicyTypeDistribution = policies
                    .GroupBy(p => p.Type.ToString())
                    .ToDictionary(g => g.Key, g => g.Count()),
                AverageCancellationWindow = policies.Any() 
                    ? policies.Average(p => p.CancellationWindowDays) 
                    : 0
            };

            _logger.LogInformation("تم الحصول على إحصائيات السياسات: Total={Total}, Active={Active}", 
                stats.TotalPolicies, stats.ActivePolicies);

            return ResultDto<PolicyStatsDto>.Succeeded(stats);
        }
    }
}
