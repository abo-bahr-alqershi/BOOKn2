using System;
using MediatR;
using YemenBooking.Core.Enums;

namespace YemenBooking.Application.Features.Analytics.Commands.Reports
{
    /// <summary>
    /// الأمر لتصدير تقرير لوحة التحكم بالتنسيق المحدد
    /// Command to export dashboard report in the specified format
    /// </summary>
    public class ExportDashboardReportCommand : IRequest<byte[]>
    {
        /// <summary>
        /// نوع لوحة التحكم
        /// Dashboard type
        /// </summary>
        public DashboardType DashboardType { get; set; }

        /// <summary>
        /// معرف الهدف (مثل معرف المالك أو المستخدم)
        /// Target identifier (e.g., owner or customer id)
        /// </summary>
        public Guid TargetId { get; set; }

        /// <summary>
        /// تنسيق التقرير
        /// Report format
        /// </summary>
        public ReportFormat Format { get; set; }

        public ExportDashboardReportCommand(DashboardType dashboardType, Guid targetId, ReportFormat format)
        {
            DashboardType = dashboardType;
            TargetId = targetId;
            Format = format;
        }
    }
} 