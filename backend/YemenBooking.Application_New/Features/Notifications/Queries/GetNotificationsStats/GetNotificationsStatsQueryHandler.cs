using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Notifications;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetNotificationsStats
{
    /// <summary>
    /// معالج إحصائيات الإشعارات
    /// </summary>
    public class GetNotificationsStatsQueryHandler : IRequestHandler<GetNotificationsStatsQuery, NotificationsStatsDto>
    {
        private readonly INotificationRepository _notificationRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetNotificationsStatsQueryHandler> _logger;

        public GetNotificationsStatsQueryHandler(
            INotificationRepository notificationRepository,
            ICurrentUserService currentUserService,
            ILogger<GetNotificationsStatsQueryHandler> logger)
        {
            _notificationRepository = notificationRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<NotificationsStatsDto> Handle(GetNotificationsStatsQuery request, CancellationToken cancellationToken)
        {
            if (_currentUserService.Role != "Admin")
                return new NotificationsStatsDto();

            var q = _notificationRepository.GetQueryable();

            // Normalize optional incoming date filters
            if (request.From.HasValue)
                request.From = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.From.Value);
            if (request.To.HasValue)
                request.To = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.To.Value);
            if (!string.IsNullOrWhiteSpace(request.Type)) q = q.Where(n => n.Type == request.Type);
            if (request.From.HasValue) q = q.Where(n => n.CreatedAt >= request.From.Value);
            if (request.To.HasValue) q = q.Where(n => n.CreatedAt <= request.To.Value);

            // Use user-local day boundaries for daily buckets, then compare in UTC (data stored in UTC)
            var userNowLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow);
            var now = (await _currentUserService.ConvertFromUserLocalToUtcAsync(userNowLocal.Date));
            var last7 = now.AddDays(-7);
            var last30 = now.AddDays(-30);

            var stats = new NotificationsStatsDto
            {
                Total = q.Count(),
                Pending = q.Count(n => n.Status == "PENDING"),
                Sent = q.Count(n => n.Status == "SENT"),
                Delivered = q.Count(n => n.Status == "DELIVERED"),
                Read = q.Count(n => n.Status == "READ"),
                Failed = q.Count(n => n.Status == "FAILED"),
                Today = q.Count(n => n.CreatedAt >= now),
                Last7Days = q.Count(n => n.CreatedAt >= last7),
                Last30Days = q.Count(n => n.CreatedAt >= last30)
            };

            // Compute trends like currencies: compare current [From,To] to previous same-length window
            if (request.From.HasValue && request.To.HasValue && request.To > request.From)
            {
                var start = request.From.Value;
                var end = request.To.Value;
                var period = end - start;
                var prevStart = start - period;
                var prevEnd = start;

                double Trend(int current, int previous)
                {
                    if (previous == 0) return current == 0 ? 0.0 : double.NaN;
                    return Math.Round(((current - previous) / (double)previous) * 100.0, 1);
                }

                int CountInRange(Func<Core.Entities.Notification, bool> predicate, DateTime s, DateTime e)
                    => q.Where(n => n.CreatedAt >= s && n.CreatedAt <= e).Where(predicate).Count();

                var currTotal = q.Count(n => n.CreatedAt >= start && n.CreatedAt <= end);
                var prevTotal = q.Count(n => n.CreatedAt >= prevStart && n.CreatedAt <= prevEnd);
                var currSent = CountInRange(n => n.Status == "SENT" || n.Status == "DELIVERED" || n.Status == "READ", start, end);
                var prevSent = CountInRange(n => n.Status == "SENT" || n.Status == "DELIVERED" || n.Status == "READ", prevStart, prevEnd);
                var currPending = CountInRange(n => n.Status == "PENDING", start, end);
                var prevPending = CountInRange(n => n.Status == "PENDING", prevStart, prevEnd);
                var currFailed = CountInRange(n => n.Status == "FAILED", start, end);
                var prevFailed = CountInRange(n => n.Status == "FAILED", prevStart, prevEnd);

                var currRead = CountInRange(n => n.Status == "READ", start, end);
                var currReachable = CountInRange(n => n.Status == "DELIVERED" || n.Status == "READ" || n.Status == "SENT", start, end);
                var prevRead = CountInRange(n => n.Status == "READ", prevStart, prevEnd);
                var prevReachable = CountInRange(n => n.Status == "DELIVERED" || n.Status == "READ" || n.Status == "SENT", prevStart, prevEnd);

                int SafePct(int numerator, int denominator)
                {
                    if (denominator == 0) return numerator == 0 ? 0 : 0; // 0% when no baseline
                    return (int)Math.Round((numerator / (double)denominator) * 100.0);
                }

                int TrendInt(double t)
                {
                    if (double.IsNaN(t)) return 0; // undefined trend when previous 0 and current > 0 -> show 0 (neutral)
                    return (int)Math.Round(t);
                }

                stats.TotalTrend = TrendInt(Trend(currTotal, prevTotal));
                stats.SentTrend = TrendInt(Trend(currSent, prevSent));
                stats.PendingTrend = TrendInt(Trend(currPending, prevPending));
                stats.FailedTrend = TrendInt(Trend(currFailed, prevFailed));

                stats.ReadRate = SafePct(currRead, Math.Max(currReachable, 1));
                var prevReadRate = SafePct(prevRead, Math.Max(prevReachable, 1));
                stats.ReadRateTrend = TrendInt(Trend(stats.ReadRate, prevReadRate));
            }

            return await Task.FromResult(stats);
        }
    }
}

