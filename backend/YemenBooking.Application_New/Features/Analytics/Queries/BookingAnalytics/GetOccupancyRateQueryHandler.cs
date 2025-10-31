using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics
{
    /// <summary>
    /// معالج استعلام نسبة الإشغال
    /// Handler for GetOccupancyRateQuery
    /// </summary>
    public class GetOccupancyRateQueryHandler : IRequestHandler<GetOccupancyRateQuery, decimal>
    {
        private readonly IReportingService _reportingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetOccupancyRateQueryHandler> _logger;

        public GetOccupancyRateQueryHandler(
            IReportingService reportingService,
            ICurrentUserService currentUserService,
            ILogger<GetOccupancyRateQueryHandler> logger)
        {
            _reportingService = reportingService;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<decimal> Handle(GetOccupancyRateQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Processing Occupancy Rate Query for Property {PropertyId} Range {Start} - {End}", request.PropertyId, request.Range.StartDate, request.Range.EndDate);

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
                throw new UnauthorizedException("يجب تسجيل الدخول للوصول إلى نسبة الإشغال");

            var role = _currentUserService.Role;
            if (role != "Admin" && !_currentUserService.IsStaffInProperty(request.PropertyId) && _currentUserService.PropertyId != request.PropertyId)
                throw new ForbiddenException("ليس لديك صلاحية لعرض نسبة الإشغال لهذا الكيان");

            // Convert incoming range from user local to UTC
            // Normalize incoming range from user's local time to UTC
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.StartDate);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.Range.EndDate);
            var rate = await _reportingService.CalculateOccupancyRateAsync(request.PropertyId, startUtc, endUtc, cancellationToken);
            return rate;
        }
    }
} 