using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features.Analytics.Services;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.UserAnalytics
{
    /// <summary>
    /// معالج استعلام تحليل أفواج العملاء ضمن نطاق زمني
    /// Handles GetCustomerCohortAnalysisQuery and returns customer cohort statistics
    /// </summary>
    public class GetCustomerCohortAnalysisQueryHandler : IRequestHandler<GetCustomerCohortAnalysisQuery, ResultDto<List<CohortDto>>>
    {
        private readonly IDashboardService _dashboardService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetCustomerCohortAnalysisQueryHandler> _logger;

        public GetCustomerCohortAnalysisQueryHandler(
            IDashboardService dashboardService,
            ICurrentUserService currentUserService,
            ILogger<GetCustomerCohortAnalysisQueryHandler> logger)
        {
            _dashboardService = dashboardService;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<List<CohortDto>>> Handle(GetCustomerCohortAnalysisQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحليل أفواج العملاء من {Start} إلى {End}", request.Range.StartDate, request.Range.EndDate);

            if (request.Range.StartDate > request.Range.EndDate)
            {
                _logger.LogWarning("نطاق التاريخ غير صالح");
                return ResultDto<List<CohortDto>>.Failure("نطاق التاريخ غير صالح");
            }

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<List<CohortDto>>.Failure("يجب تسجيل الدخول لعرض هذا التحليل");
            }

            if (_currentUserService.Role != "Admin")
            {
                _logger.LogWarning("ليس لدى المستخدم صلاحية الوصول إلى هذا التحليل");
                return ResultDto<List<CohortDto>>.Failure("ليس لديك صلاحية الوصول إلى هذا التحليل");
            }

            // Normalize incoming range from user's local time to UTC
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.StartDate);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.EndDate);
            var utcRange = new YemenBooking.Application.Features.Analytics.DTOs.DateRangeDto { StartDate = startUtc, EndDate = endUtc };

            var data = await _dashboardService.GetCustomerCohortAnalysisAsync(utcRange);
            var list = data.ToList();
            return ResultDto<List<CohortDto>>.Ok(list);
        }
    }
} 