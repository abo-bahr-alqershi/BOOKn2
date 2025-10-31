using System;
using System.Collections.Generic;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics
{
    /// <summary>
    /// معالج استعلام تقرير الإشغال
    /// Handler for occupancy report query
    /// </summary>
    public class GetOccupancyReportQueryHandler : IRequestHandler<GetOccupancyReportQuery, ResultDto<OccupancyReportDto>>
    {
        #region Dependencies
        private readonly IReportingService _reportingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetOccupancyReportQueryHandler> _logger;
        #endregion

        #region Constructor
        public GetOccupancyReportQueryHandler(
            IReportingService reportingService,
            ICurrentUserService currentUserService,
            ILogger<GetOccupancyReportQueryHandler> logger)
        {
            _reportingService = reportingService;
            _currentUserService = currentUserService;
            _logger = logger;
        }
        #endregion

        #region Handler Implementation
        public async Task<ResultDto<OccupancyReportDto>> Handle(GetOccupancyReportQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب تقرير الإشغال للكيان: {PropertyId} من {StartDate} إلى {EndDate}",
                request.PropertyId, request.StartDate, request.EndDate);

            // 1. Validate inputs
            if (request.PropertyId == Guid.Empty)
            {
                _logger.LogWarning("معرف الكيان غير صالح");
                return ResultDto<OccupancyReportDto>.Failure("معرف الكيان غير صالح");
            }
            if (request.StartDate > request.EndDate)
            {
                _logger.LogWarning("تاريخ البداية أكبر من تاريخ النهاية");
                return ResultDto<OccupancyReportDto>.Failure("تاريخ البداية يجب أن يكون قبل تاريخ النهاية");
            }

            // 2. Authorization
            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<OccupancyReportDto>.Failure("يجب تسجيل الدخول لعرض تقرير الإشغال");
            }
            var role = _currentUserService.Role;
            if (role != "Admin" && _currentUserService.PropertyId != request.PropertyId)
            {
                _logger.LogWarning("ليس لدى المستخدم الصلاحيات اللازمة لعرض تقرير الإشغال");
                return ResultDto<OccupancyReportDto>.Failure("ليس لديك صلاحية لعرض تقرير الإشغال لهذا الكيان");
            }

            // 3. Normalize date range (user-local -> UTC) before querying reporting service
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.StartDate);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.EndDate);

            // 4. Fetch report
            var rawReport = await _reportingService.GetOccupancyReportAsync(
                startUtc, endUtc, request.PropertyId, cancellationToken);

            // 5. Map to DTO
            var wrapper = new { Items = rawReport };
            var json = JsonSerializer.Serialize(wrapper);
            var reportDto = JsonSerializer.Deserialize<OccupancyReportDto>(json);
            if (reportDto == null)
            {
                _logger.LogError("فشل في تحليل بيانات تقرير الإشغال");
                return ResultDto<OccupancyReportDto>.Failure("فشل في جلب بيانات تقرير الإشغال");
            }

            _logger.LogInformation("تم جلب تقرير الإشغال بنجاح");
            return ResultDto<OccupancyReportDto>.Ok(reportDto);
        }
        #endregion
    }
} 