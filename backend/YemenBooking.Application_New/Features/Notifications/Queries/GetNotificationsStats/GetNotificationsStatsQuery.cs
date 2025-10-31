using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetNotificationsStats
{
    /// <summary>
    /// استعلام إحصائيات الإشعارات للوحة الإدارة
    /// </summary>
    public class GetNotificationsStatsQuery : IRequest<NotificationsStatsDto>
    {
        public string? Type { get; set; }
        public DateTime? From { get; set; }
        public DateTime? To { get; set; }
    }
}

