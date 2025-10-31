using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Users.Commands.ManageRoles;
using YemenBooking.Application.Features.Users.Queries.GetAllRoles;

namespace YemenBooking.Api.Controllers.Admin
{
    public class RolesController : BaseAdminController
    {
        public RolesController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// إنشاء دور جديد
        /// Create a new role
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateRole([FromBody] CreateRoleCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث دور
        /// Update an existing role
        /// </summary>
        [HttpPut("{roleId}")]
        public async Task<IActionResult> UpdateRole(Guid roleId, [FromBody] UpdateRoleCommand command)
        {
            command.RoleId = roleId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف دور
        /// Delete a role
        /// </summary>
        [HttpDelete("{roleId}")]
        public async Task<IActionResult> DeleteRole(Guid roleId)
        {
            var command = new DeleteRoleCommand { RoleId = roleId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب جميع الأدوار مع الصفحات
        /// Get all roles with pagination
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllRoles([FromQuery] GetAllRolesQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 