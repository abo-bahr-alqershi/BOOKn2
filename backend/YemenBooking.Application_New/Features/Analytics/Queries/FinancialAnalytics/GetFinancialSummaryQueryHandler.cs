using System;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.FinancialAnalytics
{
    /// <summary>
    /// معالج استعلام الملخص المالي
    /// Handler for financial summary query
    /// </summary>
    public class GetFinancialSummaryQueryHandler : IRequestHandler<GetFinancialSummaryQuery, ResultDto<FinancialSummaryDto>>
    {
        #region Dependencies
        private readonly IReportingService _reportingService;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetFinancialSummaryQueryHandler> _logger;
        #endregion

        #region Constructor
        public GetFinancialSummaryQueryHandler(
            IReportingService reportingService,
            ICurrentUserService currentUserService,
            ILogger<GetFinancialSummaryQueryHandler> logger)
        {
            _reportingService = reportingService;
            _currentUserService = currentUserService;
            _logger = logger;
        }
        #endregion

        #region Handler Implementation
        public async Task<ResultDto<FinancialSummaryDto>> Handle(GetFinancialSummaryQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب الملخص المالي من {StartDate} إلى {EndDate}, PropertyId: {PropertyId}",
                request.StartDate, request.EndDate, request.PropertyId);

            // 1. Validate date range
            if (request.StartDate > request.EndDate)
            {
                _logger.LogWarning("تاريخ البداية أكبر من تاريخ النهاية");
                return ResultDto<FinancialSummaryDto>.Failure("تاريخ البداية يجب أن يكون قبل تاريخ النهاية");
            }

            // 2. Authorization
            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null)
            {
                _logger.LogWarning("محاولة الوصول بدون تسجيل دخول");
                return ResultDto<FinancialSummaryDto>.Failure("يجب تسجيل الدخول لعرض الملخص المالي");
            }
            var role = _currentUserService.Role;
            if (request.PropertyId.HasValue)
            {
                if (role != "Admin" && _currentUserService.PropertyId != request.PropertyId)
                {
                    _logger.LogWarning("ليس لدى المستخدم الصلاحيات اللازمة لعرض الملخص المالي");
                    return ResultDto<FinancialSummaryDto>.Failure("ليس لديك صلاحية لعرض الملخص المالي لهذا الكيان");
                }
            }
            else
            {
                if (role != "Admin")
                {
                    _logger.LogWarning("ليس لدى المستخدم الصلاحيات اللازمة لعرض الملخص المالي العام");
                    return ResultDto<FinancialSummaryDto>.Failure("ليس لديك صلاحية لعرض الملخص المالي العام");
                }
            }

            // 3. Fetch summary
            var rawSummary = await _reportingService.GetFinancialSummaryAsync(
                request.StartDate, request.EndDate, request.PropertyId, cancellationToken);

            // 4. Map to DTO
            var json = JsonSerializer.Serialize(rawSummary);
            var summaryDto = JsonSerializer.Deserialize<FinancialSummaryDto>(json);
            if (summaryDto == null)
            {
                _logger.LogError("فشل في تحليل بيانات الملخص المالي");
                return ResultDto<FinancialSummaryDto>.Failure("فشل في جلب بيانات الملخص المالي");
            }

            _logger.LogInformation("تم جلب الملخص المالي بنجاح");
            return ResultDto<FinancialSummaryDto>.Ok(summaryDto);
        }
        #endregion
    }
} 