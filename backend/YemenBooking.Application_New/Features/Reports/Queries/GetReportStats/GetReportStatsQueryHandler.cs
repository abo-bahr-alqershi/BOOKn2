using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Reports;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reports.Queries.GetReportStats
{
    /// <summary>
    /// معالج استعلام إحصائيات البلاغات
    /// Handles GetReportStatsQuery and returns report analytics
    /// </summary>
    public class GetReportStatsQueryHandler : IRequestHandler<GetReportStatsQuery, ReportStatsDto>
    {
        private readonly IReportRepository _reportRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetReportStatsQueryHandler> _logger;

        public GetReportStatsQueryHandler(
            IReportRepository reportRepository,
            ICurrentUserService currentUserService,
            ILogger<GetReportStatsQueryHandler> logger)
        {
            _reportRepository = reportRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<ReportStatsDto> Handle(GetReportStatsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء معالجة استعلام GetReportStats");
            // جلب كل البلاغات دون فلترة
            var allReports = await _reportRepository.GetReportsAsync(null, null, null, cancellationToken);

            // الإحصائيات الأساسية
            var total = allReports.Count();
            var pending = allReports.Count(r => r.Status.Equals("pending", StringComparison.OrdinalIgnoreCase));
            var resolved = allReports.Count(r => r.Status.Equals("resolved", StringComparison.OrdinalIgnoreCase));
            var dismissed = allReports.Count(r => r.Status.Equals("dismissed", StringComparison.OrdinalIgnoreCase));
            var escalated = allReports.Count(r => r.Status.Equals("escalated", StringComparison.OrdinalIgnoreCase));

            // حساب متوسط زمن الحل للبلاغات المحلولة
            var resolutionTimes = allReports
                .Where(r => r.Status.Equals("resolved", StringComparison.OrdinalIgnoreCase) && r.UpdatedAt > r.CreatedAt)
                .Select(r => (r.UpdatedAt - r.CreatedAt).TotalDays);
            var avgResolution = resolutionTimes.Any() ? Math.Round(resolutionTimes.Average(), 2) : 0;

            // عدد البلاغات حسب السبب (category)
            var byCategory = allReports
                .GroupBy(r => r.Reason)
                .ToDictionary(g => g.Key, g => g.Count());

            // اتجاه البلاغات خلال آخر 7 أيام باستخدام حدود اليوم بحسب توقيت المستخدم
            var userNowLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow);
            var todayUtcBoundary = await _currentUserService.ConvertFromUserLocalToUtcAsync(userNowLocal.Date);
            var trend = Enumerable.Range(0, 7)
                .Select(i =>
                {
                    var dayStartUtc = todayUtcBoundary.AddDays(-i);
                    var nextDayStartUtc = dayStartUtc.AddDays(1);
                    var count = allReports.Count(r => r.CreatedAt >= dayStartUtc && r.CreatedAt < nextDayStartUtc);
                    // Return the user-local date for presentation
                    var dayLocal = userNowLocal.Date.AddDays(-i);
                    return new ReportTrendItem { Date = dayLocal, Count = count };
                })
                .Reverse()
                .ToList();

            return new ReportStatsDto
            {
                TotalReports = total,
                PendingReports = pending,
                ResolvedReports = resolved,
                DismissedReports = dismissed,
                EscalatedReports = escalated,
                AverageResolutionTime = avgResolution,
                ReportsByCategory = byCategory,
                ReportsTrend = trend
            };
        }
    }
} 