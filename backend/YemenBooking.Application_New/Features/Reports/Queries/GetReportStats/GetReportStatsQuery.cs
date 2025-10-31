using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reports.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reports.Queries.GetReportStats
{
    /// <summary>
    /// استعلام للحصول على إحصائيات وتحليلات البلاغات
    /// Query to retrieve report analytics and statistics
    /// </summary>
    public class GetReportStatsQuery : IRequest<ReportStatsDto>
    {
    }
} 