using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.Dashboard
{
    /// <summary>
    /// استعلام للحصول على إحصائيات لوحة التحكم
    /// Query to get dashboard statistics
    /// </summary>
    public class GetDashboardStatsQuery : IRequest<DashboardStatsDto>
    {
        // لا توجد معلمات
    }
} 