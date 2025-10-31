using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Staffs.Commands.ManageStaff
{
    /// <summary>
    /// أمر لإزالة الموظف
    /// Command to remove a staff member
    /// </summary>
    public class RemoveStaffCommand : IRequest<ResultDto<bool>>
    {
        /// <summary>
        /// معرف الموظف
        /// </summary>
        public Guid StaffId { get; set; }
    }
} 