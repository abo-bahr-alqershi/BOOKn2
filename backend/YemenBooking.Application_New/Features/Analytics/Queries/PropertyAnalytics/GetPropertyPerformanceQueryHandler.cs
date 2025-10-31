using System;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.PropertyAnalytics
{
    /// <summary>
    /// معالج استعلام مؤشرات أداء الكيان
    /// Handler for property performance metrics query
    /// </summary>
    public class GetPropertyPerformanceQueryHandler : IRequestHandler<GetPropertyPerformanceQuery, ResultDto<PropertyPerformanceDto>>
    {
        #region Dependencies
        private readonly IReportingService _reportingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetPropertyPerformanceQueryHandler> _logger;
        #endregion

        #region Constructor
        public GetPropertyPerformanceQueryHandler(
            IReportingService reportingService,
            ICurrentUserService currentUserService,
            ILogger<GetPropertyPerformanceQueryHandler> logger)
        {
            _reportingService = reportingService;
            _currentUserService = currentUserService;
            _logger = logger;
        }
        #endregion

        #region Handler Implementation
        public async Task<ResultDto<PropertyPerformanceDto>> Handle(GetPropertyPerformanceQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب أداء الكيان: {PropertyId} من {StartDate} إلى {EndDate}",
                request.PropertyId, request.StartDate, request.EndDate);

            // Validate inputs
            if (request.PropertyId == Guid.Empty)
            {
                _logger.LogWarning("معرف الكيان غير صالح");
                return ResultDto<PropertyPerformanceDto>.Failure("معرف الكيان غير صالح");
            }
            if (request.StartDate > request.EndDate)
            {
                _logger.LogWarning("تاريخ البداية أكبر من تاريخ النهاية");
                return ResultDto<PropertyPerformanceDto>.Failure("تاريخ البداية يجب أن يكون قبل تاريخ النهاية");
            }

            // Authorization: only property owner or admin
            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<PropertyPerformanceDto>.Failure("يجب تسجيل الدخول لعرض تقرير الأداء");
            }
            var userRole = _currentUserService.Role;
            if (userRole != "Admin" && _currentUserService.PropertyId != request.PropertyId)
            {
                _logger.LogWarning("ليس لدى المستخدم الصلاحيات اللازمة لعرض تقرير الأداء");
                return ResultDto<PropertyPerformanceDto>.Failure("ليس لديك صلاحية لعرض تقرير أداء هذا الكيان");
            }

            // Fetch metrics
            var rawMetrics = await _reportingService.GetPropertyPerformanceAsync(
                request.PropertyId, request.StartDate, request.EndDate, cancellationToken);

            // Map to DTO via JSON serialization
            var json = JsonSerializer.Serialize(rawMetrics);
            var metrics = JsonSerializer.Deserialize<PropertyPerformanceDto>(json);
            if (metrics == null)
            {
                _logger.LogError("فشل في تحليل بيانات مؤشرات الأداء للكيان: {PropertyId}", request.PropertyId);
                return ResultDto<PropertyPerformanceDto>.Failure("فشل في جلب بيانات تقرير الأداء");
            }

            _logger.LogInformation("تم جلب بيانات تقرير الأداء بنجاح: {PropertyId}", request.PropertyId);
            return ResultDto<PropertyPerformanceDto>.Ok(metrics);
        }
        #endregion
    }
} 