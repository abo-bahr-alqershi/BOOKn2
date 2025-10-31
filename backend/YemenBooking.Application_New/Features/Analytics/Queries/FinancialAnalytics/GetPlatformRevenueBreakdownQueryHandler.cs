using System;
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

namespace YemenBooking.Application.Features.Analytics.Queries.FinancialAnalytics
{
    /// <summary>
    /// معالج استعلام تفصيل الإيرادات الكلي للمنصة ضمن نطاق زمني
    /// Handles GetPlatformRevenueBreakdownQuery and returns platform revenue breakdown
    /// </summary>
    public class GetPlatformRevenueBreakdownQueryHandler : IRequestHandler<GetPlatformRevenueBreakdownQuery, ResultDto<RevenueBreakdownDto>>
    {
        private readonly IDashboardService _dashboardService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetPlatformRevenueBreakdownQueryHandler> _logger;

        public GetPlatformRevenueBreakdownQueryHandler(
            IDashboardService dashboardService,
            ICurrentUserService currentUserService,
            ILogger<GetPlatformRevenueBreakdownQueryHandler> logger)
        {
            _dashboardService = dashboardService;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<RevenueBreakdownDto>> Handle(GetPlatformRevenueBreakdownQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحليل تفصيل إيرادات المنصة من {Start} إلى {End}", request.Range.StartDate, request.Range.EndDate);

            if (request.Range.StartDate > request.Range.EndDate)
            {
                _logger.LogWarning("نطاق التاريخ غير صالح");
                return ResultDto<RevenueBreakdownDto>.Failure("نطاق التاريخ غير صالح");
            }

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<RevenueBreakdownDto>.Failure("يجب تسجيل الدخول لعرض هذا التحليل");
            }

            if (_currentUserService.Role != "Admin")
            {
                _logger.LogWarning("ليس لدى المستخدم صلاحية الوصول إلى هذا التحليل");
                return ResultDto<RevenueBreakdownDto>.Failure("ليس لديك صلاحية الوصول إلى هذا التحليل");
            }

            // Normalize incoming range from user's local time to UTC
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.StartDate);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.EndDate);
            var utcRange = new YemenBooking.Application.Features.Analytics.DTOs.DateRangeDto { StartDate = startUtc, EndDate = endUtc };

            var data = await _dashboardService.GetPlatformRevenueBreakdownAsync(utcRange);
            return ResultDto<RevenueBreakdownDto>.Ok(data);
        }
    }
} 