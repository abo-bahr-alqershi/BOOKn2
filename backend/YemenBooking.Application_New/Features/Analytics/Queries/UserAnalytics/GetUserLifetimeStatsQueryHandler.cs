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

namespace YemenBooking.Application.Features.Analytics.Queries.UserAnalytics
{
    /// <summary>
    /// معالج استعلام إحصائيات المستخدم مدى الحياة
    /// Handles GetUserLifetimeStatsQuery and returns user lifetime statistics
    /// </summary>
    public class GetUserLifetimeStatsQueryHandler : IRequestHandler<GetUserLifetimeStatsQuery, ResultDto<UserLifetimeStatsDto>>
    {
        private readonly IDashboardService _dashboardService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetUserLifetimeStatsQueryHandler> _logger;

        public GetUserLifetimeStatsQueryHandler(
            IDashboardService dashboardService,
            ICurrentUserService currentUserService,
            ILogger<GetUserLifetimeStatsQueryHandler> logger)
        {
            _dashboardService = dashboardService;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ResultDto<UserLifetimeStatsDto>> Handle(GetUserLifetimeStatsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب إحصائيات المستخدم مدى الحياة: {UserId}", request.UserId);

            if (request.UserId == Guid.Empty)
            {
                _logger.LogWarning("معرف المستخدم غير صالح");
                return ResultDto<UserLifetimeStatsDto>.Failure("معرف المستخدم غير صالح");
            }

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<UserLifetimeStatsDto>.Failure("يجب تسجيل الدخول لعرض هذه الإحصائيات");
            }

            if (_currentUserService.UserId != request.UserId && _currentUserService.Role != "Admin")
            {
                _logger.LogWarning("ليس لدى المستخدم صلاحية الوصول إلى هذه الإحصائيات");
                return ResultDto<UserLifetimeStatsDto>.Failure("ليس لديك صلاحية الوصول إلى هذه الإحصائيات");
            }

            var data = await _dashboardService.GetUserLifetimeStatsAsync(request.UserId);
            return ResultDto<UserLifetimeStatsDto>.Ok(data);
        }
    }
} 