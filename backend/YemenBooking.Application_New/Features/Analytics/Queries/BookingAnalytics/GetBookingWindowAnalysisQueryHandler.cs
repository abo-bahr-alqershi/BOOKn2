using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Features.Analytics;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features.Analytics.Services;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics
{
    /// <summary>
    /// معالج استعلام تحليل نافذة الحجز لكيان محدد
    /// Handles GetBookingWindowAnalysisQuery and returns booking window statistics
    /// </summary>
    public class GetBookingWindowAnalysisQueryHandler : IRequestHandler<GetBookingWindowAnalysisQuery, ResultDto<BookingWindowDto>>
    {
        private readonly IDashboardService _dashboardService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetBookingWindowAnalysisQueryHandler> _logger;

        public GetBookingWindowAnalysisQueryHandler(
            IDashboardService dashboardService,
            ICurrentUserService currentUserService,
            ILogger<GetBookingWindowAnalysisQueryHandler> logger)
        {
            _dashboardService = dashboardService;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<BookingWindowDto>> Handle(GetBookingWindowAnalysisQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء تحليل نافذة الحجز للكيان: {PropertyId}", request.PropertyId);

            if (request.PropertyId == Guid.Empty)
            {
                _logger.LogWarning("معرف الكيان غير صالح");
                return ResultDto<BookingWindowDto>.Failure("معرف الكيان غير صالح");
            }

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<BookingWindowDto>.Failure("يجب تسجيل الدخول لعرض هذا التحليل");
            }

            var role = _currentUserService.Role;
            if (role != "Admin" && _currentUserService.PropertyId != request.PropertyId)
            {
                _logger.LogWarning("ليس لدى المستخدم الصلاحية اللازمة لعرض هذا التحليل");
                return ResultDto<BookingWindowDto>.Failure("ليس لديك صلاحية لعرض هذا التحليل");
            }

            // No date inputs here; if service returns time-based series in future, convert there.
            // Ensure service-level data uses UTC; any outbound DateTimes to clients should be localized by callers.
            var data = await _dashboardService.GetBookingWindowAnalysisAsync(request.PropertyId);
            return ResultDto<BookingWindowDto>.Ok(data);
        }
    }
} 