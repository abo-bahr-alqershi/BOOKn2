using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features.Analytics.Services;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.UserAnalytics
{
    /// <summary>
    /// معالج استعلام للحصول على بيانات قمع اكتساب العملاء ضمن نطاق زمني
    /// Handles GetUserAcquisitionFunnelQuery and returns user acquisition funnel data
    /// </summary>
    public class GetUserAcquisitionFunnelQueryHandler : IRequestHandler<GetUserAcquisitionFunnelQuery, ResultDto<UserFunnelDto>>
    {
        private readonly IDashboardService _dashboardService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetUserAcquisitionFunnelQueryHandler> _logger;

        public GetUserAcquisitionFunnelQueryHandler(
            IDashboardService dashboardService,
            ICurrentUserService currentUserService,
            ILogger<GetUserAcquisitionFunnelQueryHandler> logger)
        {
            _dashboardService = dashboardService;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<UserFunnelDto>> Handle(GetUserAcquisitionFunnelQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب قمع اكتساب العملاء ضمن النطاق: {Start} - {End}", request.Range.StartDate, request.Range.EndDate);

            if (request.Range == null || request.Range.StartDate > request.Range.EndDate)
            {
                _logger.LogWarning("نطاق التاريخ غير صالح");
                return ResultDto<UserFunnelDto>.Failure("نطاق التاريخ غير صالح");
            }

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<UserFunnelDto>.Failure("يجب تسجيل الدخول لعرض هذه البيانات");
            }

            if (_currentUserService.Role != "Admin")
            {
                _logger.LogWarning("ليس لدى المستخدم صلاحية الوصول إلى هذه البيانات");
                return ResultDto<UserFunnelDto>.Failure("ليس لديك صلاحية الوصول إلى هذه البيانات");
            }

            // Normalize incoming range from user's local time to UTC
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.StartDate);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.EndDate);
            var utcRange = new YemenBooking.Application.Features.Analytics.DTOs.DateRangeDto { StartDate = startUtc, EndDate = endUtc };

            var data = await _dashboardService.GetUserAcquisitionFunnelAsync(utcRange, cancellationToken);
            return ResultDto<UserFunnelDto>.Ok(data);
        }
    }
} 