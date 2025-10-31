using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Analytics.Services;
using System.Collections.Concurrent;
using System.Linq;

namespace YemenBooking.Infrastructure.Services
{
    /// <summary>
    /// تنفيذ خدمة تتبع الأحداث للتحليلات
    /// Analytics tracker service implementation
    /// </summary>
    public class AnalyticsTrackerService : IAnalyticsTrackerService
    {
        private readonly ILogger<AnalyticsTrackerService> _logger;
        private static readonly ConcurrentBag<(string EventName, DateTime Timestamp)> _events = new();

        /// <summary>
        /// المُنشئ مع حقن الLogger
        /// Constructor with injected logger
        /// </summary>
        public AnalyticsTrackerService(ILogger<AnalyticsTrackerService> logger)
        {
            _logger = logger;
        }

        /// <inheritdoc />
        public Task TrackEventAsync(string eventName, Dictionary<string, string> properties)
        {
            _logger.LogInformation("تتبع حدث: {EventName} بخصائص: {@Properties}", eventName, properties);
            _events.Add((eventName, DateTime.UtcNow));
            return Task.CompletedTask;
        }

        /// <inheritdoc />
        public Task<Dictionary<string, int>> GetEventCountsAsync(DateTime startDate, DateTime endDate, IEnumerable<string> eventNames)
        {
            _logger.LogInformation("الحصول على إحصائيات الأحداث من {StartDate} إلى {EndDate} للأحداث: {@EventNames}", startDate, endDate, eventNames);
            var counts = _events
                .Where(e => e.Timestamp >= startDate && e.Timestamp <= endDate && eventNames.Contains(e.EventName))
                .GroupBy(e => e.EventName)
                .ToDictionary(g => g.Key, g => g.Count());
            return Task.FromResult(counts);
        }
    }
} 