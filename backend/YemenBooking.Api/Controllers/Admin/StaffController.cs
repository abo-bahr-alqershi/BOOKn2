using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Staffs.Commands.ManageStaff;
using YemenBooking.Application.Features.Staffs.Queries.GetStaffByUser;
using YemenBooking.Application.Features.Staffs.Queries.GetStaffByProperty;
using YemenBooking.Application.Features.Staffs.Queries.GetStaffByPosition;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بعمليات الموظفين: إضافة، تعديل، إزالة واستعلام
    /// Controller for staff management by admin
    /// </summary>
    public class StaffController : BaseAdminController
    {
        public StaffController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// إضافة موظف جديد
        /// Add a new staff member
        /// </summary>
        [HttpPost("add")]
        public async Task<IActionResult> AddStaff([FromBody] AddStaffCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث بيانات موظف
        /// Update staff member details
        /// </summary>
        [HttpPut("update")]
        public async Task<IActionResult> UpdateStaff([FromBody] UpdateStaffCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إزالة موظف
        /// Remove a staff member
        /// </summary>
        [HttpPost("remove")]
        public async Task<IActionResult> RemoveStaff([FromBody] RemoveStaffCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب الموظفين حسب المنصب
        /// Get staff by position
        /// </summary>
        [HttpGet("by-position")]
        public async Task<IActionResult> GetStaffByPosition([FromQuery] GetStaffByPositionQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب الموظفين حسب الكيان
        /// Get staff by property
        /// </summary>
        [HttpGet("by-property")]
        public async Task<IActionResult> GetStaffByProperty([FromQuery] GetStaffByPropertyQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب الموظفين حسب المستخدم (المالك)
        /// Get staff by user
        /// </summary>
        [HttpGet("by-user")]
        public async Task<IActionResult> GetStaffByUser([FromQuery] GetStaffByUserQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 