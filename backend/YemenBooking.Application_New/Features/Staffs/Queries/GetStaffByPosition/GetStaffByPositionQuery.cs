using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Staffs.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Staffs.Queries.GetStaffByPosition
{
    /// <summary>
    /// استعلام للحصول على الموظفين حسب المنصب
    /// Query to get staff by position
    /// </summary>
    public class GetStaffByPositionQuery : IRequest<PaginatedResult<StaffDto>>
    {
        /// <summary>
        /// المنصب
        /// </summary>
        public string Position { get; set; }

        /// <summary>
        /// معرف الكيان (اختياري)
        /// </summary>
        public Guid? PropertyId { get; set; }

        /// <summary>
        /// رقم الصفحة
        /// </summary>
        public int PageNumber { get; set; } = 1;

        /// <summary>
        /// حجم الصفحة
        /// </summary>
        public int PageSize { get; set; } = 10;
    }
} 