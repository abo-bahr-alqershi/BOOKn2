using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.DynamicFields.Commands.ManageFieldGroups;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.DynamicFields.Queries.GetFieldGroupsByUnitType;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بإدارة مجموعات الحقول للمدراء
    /// Controller for managing field groups by admins
    /// </summary>
    public class FieldGroupsController : BaseAdminController
    {
        public FieldGroupsController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// إنشاء مجموعة حقول جديدة
        /// Create a new field group
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateFieldGroup([FromBody] CreateFieldGroupCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث مجموعة حقول
        /// Update an existing field group
        /// </summary>
        [HttpPut("{groupId}")]
        public async Task<IActionResult> UpdateFieldGroup(string groupId, [FromBody] UpdateFieldGroupCommand command)
        {
            command.GroupId = groupId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف مجموعة حقول
        /// Delete a field group
        /// </summary>
        [HttpDelete("{groupId}")]
        public async Task<IActionResult> DeleteFieldGroup(string groupId)
        {
            var command = new DeleteFieldGroupCommand { GroupId = groupId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب مجموعات الحقول لنوع وحدة معين
        /// Get field groups by unit type
        /// </summary>
        [HttpGet("unit-type/{unitTypeId}")]
        public async Task<IActionResult> GetFieldGroupsByUnitType(string unitTypeId)
        {
            var query = new GetFieldGroupsByUnitTypeQuery { UnitTypeId = unitTypeId };
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 