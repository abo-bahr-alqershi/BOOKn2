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
using YemenBooking.Application.Features.Bookings.DTOs;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.BookingAnalytics
{
    /// <summary>
    /// معالج استعلام تقرير الحجوزات
    /// Handler for booking report query
    /// </summary>
    public class GetBookingReportQueryHandler : IRequestHandler<GetBookingReportQuery, ResultDto<BookingReportDto>>
    {
        #region Dependencies
        private readonly IReportingService _reportingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetBookingReportQueryHandler> _logger;
        #endregion

        #region Constructor
        public GetBookingReportQueryHandler(
            IReportingService reportingService,
            ICurrentUserService currentUserService,
            ILogger<GetBookingReportQueryHandler> logger)
        {
            _reportingService = reportingService;
            _currentUserService = currentUserService;
            _logger = logger;
        }
        #endregion

        #region Handler Implementation
        public async Task<ResultDto<BookingReportDto>> Handle(GetBookingReportQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب تقرير الحجوزات من {StartDate} إلى {EndDate}, PropertyId: {PropertyId}",
                request.StartDate, request.EndDate, request.PropertyId);

            // 1. Validate date range
            if (request.StartDate > request.EndDate)
            {
                _logger.LogWarning("تاريخ البداية أكبر من تاريخ النهاية");
                return ResultDto<BookingReportDto>.Failure("تاريخ البداية يجب أن يكون قبل تاريخ النهاية");
            }

            // 2. Authorization
            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<BookingReportDto>.Failure("يجب تسجيل الدخول لعرض تقرير الحجوزات");
            }
            var role = _currentUserService.Role;
            if (request.PropertyId.HasValue)
            {
                if (role != "Admin" && _currentUserService.PropertyId != request.PropertyId)
                {
                    _logger.LogWarning("ليس لدى المستخدم الصلاحيات اللازمة لعرض تقرير الحجوزات");
                    return ResultDto<BookingReportDto>.Failure("ليس لديك صلاحية لعرض تقرير الحجوزات لهذا الكيان");
                }
            }
            else
            {
                if (role != "Admin")
                {
                    _logger.LogWarning("ليس لدى المستخدم الصلاحيات اللازمة لعرض التقرير العام");
                    return ResultDto<BookingReportDto>.Failure("ليس لديك صلاحية لعرض تقرير الحجوزات العام");
                }
            }

            // 3. Normalize date range (user-local -> UTC) before querying reporting service
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.StartDate);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.EndDate);

            // 4. Fetch report
            var rawReport = await _reportingService.GetBookingReportAsync(
                startUtc, endUtc, request.PropertyId, cancellationToken);

            // 5. Map to DTO
            var wrapper = new { Items = rawReport };
            var json = JsonSerializer.Serialize(wrapper);
            var reportDto = JsonSerializer.Deserialize<BookingReportDto>(json);
            if (reportDto == null)
            {
                _logger.LogError("فشل في تحليل بيانات تقرير الحجوزات");
                return ResultDto<BookingReportDto>.Failure("فشل في جلب بيانات تقرير الحجوزات");
            }

            _logger.LogInformation("تم جلب تقرير الحجوزات بنجاح");
            return ResultDto<BookingReportDto>.Ok(reportDto);
        }
        #endregion
    }
} 