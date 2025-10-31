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

namespace YemenBooking.Application.Features.Analytics.Queries.FinancialAnalytics
{
    /// <summary>
    /// معالج استعلام تقرير الإيرادات
    /// Handler for revenue report query
    /// </summary>
    public class GetRevenueReportQueryHandler : IRequestHandler<GetRevenueReportQuery, ResultDto<RevenueReportDto>>
    {
        #region Dependencies
        private readonly IReportingService _reportingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetRevenueReportQueryHandler> _logger;
        #endregion

        #region Constructor
        public GetRevenueReportQueryHandler(
            IReportingService reportingService,
            ICurrentUserService currentUserService,
            ILogger<GetRevenueReportQueryHandler> logger)
        {
            _reportingService = reportingService;
            _currentUserService = currentUserService;
            _logger = logger;
        }
        #endregion

        #region Handler Implementation
        public async Task<ResultDto<RevenueReportDto>> Handle(GetRevenueReportQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب تقرير الإيرادات من {StartDate} إلى {EndDate}, PropertyId: {PropertyId}",
                request.StartDate, request.EndDate, request.PropertyId);

            // 1. Validate date range
            if (request.StartDate > request.EndDate)
            {
                _logger.LogWarning("تاريخ البداية أكبر من تاريخ النهاية");
                return ResultDto<RevenueReportDto>.Failure("تاريخ البداية يجب أن يكون قبل تاريخ النهاية");
            }

            // 2. Authorization
            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<RevenueReportDto>.Failure("يجب تسجيل الدخول لعرض تقرير الإيرادات");
            }
            var role = _currentUserService.Role;
            if (request.PropertyId.HasValue)
            {
                if (role != "Admin" && _currentUserService.PropertyId != request.PropertyId)
                {
                    _logger.LogWarning("ليس لدى المستخدم الصلاحيات اللازمة لعرض تقرير الإيرادات");
                    return ResultDto<RevenueReportDto>.Failure("ليس لديك صلاحية لعرض تقرير الإيرادات لهذا الكيان");
                }
            }
            else
            {
                if (role != "Admin")
                {
                    _logger.LogWarning("ليس لدى المستخدم الصلاحيات اللازمة لعرض التقرير العام");
                    return ResultDto<RevenueReportDto>.Failure("ليس لديك صلاحية لعرض تقرير الإيرادات العام");
                }
            }

            // 3. Normalize date range (user-local -> UTC) before querying reporting service
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.StartDate);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.EndDate);

            // 4. Fetch report
            var rawReport = await _reportingService.GetRevenueReportAsync(
                startUtc, endUtc, request.PropertyId, cancellationToken);

            // 5. Map to DTO
            var wrapper = new { Items = rawReport };
            var json = JsonSerializer.Serialize(wrapper);
            var reportDto = JsonSerializer.Deserialize<RevenueReportDto>(json);
            if (reportDto == null)
            {
                _logger.LogError("فشل في تحليل بيانات تقرير الإيرادات");
                return ResultDto<RevenueReportDto>.Failure("فشل في جلب بيانات تقرير الإيرادات");
            }

            _logger.LogInformation("تم جلب تقرير الإيرادات بنجاح");
            return ResultDto<RevenueReportDto>.Ok(reportDto);
        }
        #endregion
    }
} 