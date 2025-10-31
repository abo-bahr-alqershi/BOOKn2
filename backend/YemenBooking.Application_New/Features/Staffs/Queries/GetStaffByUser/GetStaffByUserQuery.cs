using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Staffs.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Staffs.Queries.GetStaffByUser
{
    /// <summary>
    /// استعلام للحصول على بيانات الموظف للمستخدم
    /// Query to get staff details by user
    /// </summary>
    public class GetStaffByUserQuery : IRequest<ResultDto<StaffDto>>
    {
        /// <summary>
        /// معرف المستخدم
        /// </summary>
        public Guid UserId { get; set; }
    }
} 