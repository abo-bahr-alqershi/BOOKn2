using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Analytics.Queries.Dashboard
{
    /// <summary>
    /// استعلام للحصول على بيانات لوحة تحكم المسؤول ضمن نطاق زمني
    /// Query to retrieve admin dashboard data within a date range
    /// </summary>
    public class GetAdminDashboardQuery : IRequest<AdminDashboardDto>
    {
        /// <summary>
        /// النطاق الزمني
        /// Date range for the dashboard data
        /// </summary>
        public DateRangeDto Range { get; set; }

        public GetAdminDashboardQuery(DateRangeDto range)
        {
            Range = range;
        }
    }
} 