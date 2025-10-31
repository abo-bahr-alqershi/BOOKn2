using System.Collections.Generic;
using System.Threading.Tasks;
using CsvHelper.Configuration.Attributes;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.DynamicFields.Commands.CreateUnit;
using YemenBooking.Application.Features.DynamicFields.Commands.UpdateUnit;
using YemenBooking.Application.Features.DynamicFields.Commands.DeleteUnit;
using YemenBooking.Application.Features.DynamicFields.Commands.ManageFields;
using YemenBooking.Application.Features.DynamicFields.Queries.GetUnitTypeFields;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بحقول نوع الكيان للمدراء
    /// Controller for property type fields management by admins
    /// </summary>
    [Route("api/admin/unit-type-fields")]
    [Authorize(Roles = "Admin")]
    public class UnitTypeFieldsController : BaseAdminController
    {
        public UnitTypeFieldsController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// إنشاء حقل نوع للكيان
        /// Create a new property type field
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateUnitTypeField([FromBody] CreateUnitTypeFieldCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث بيانات حقل نوع الوحدة
        /// Update an existing property type field
        /// </summary>
        [HttpPut("{fieldId}")]
        public async Task<IActionResult> UpdateUnitTypeField(string fieldId, [FromBody] UpdateUnitTypeFieldCommand command)
        {
            command.FieldId = fieldId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف حقل نوع الوحدة
        /// Delete a property type field
        /// </summary>
        [HttpDelete("{fieldId}")]
        public async Task<IActionResult> DeleteUnitTypeField(string fieldId)
        {
            var command = new DeleteUnitTypeFieldCommand { FieldId = fieldId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }


        /// <summary>
        /// إعادة ترتيب حقول نوع الكيان
        /// Reorder property type fields
        /// </summary>
        [HttpPost("reorder")]
        public async Task<IActionResult> ReorderUnitTypeFields([FromBody] ReorderUnitTypeFieldsCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب الحقول حسب نوع الوحدة مع دعم الفلاتر
        /// Get unit type fields for a given unit type with filters
        /// </summary>
        [HttpGet("unit-type/{unitTypeId}")]
        public async Task<IActionResult> GetUnitTypeFields(
            string unitTypeId,
            [FromQuery] bool? isActive,
            [FromQuery] bool? isSearchable,
            [FromQuery] bool? isPublic,
            [FromQuery] bool? isForUnits,
            [FromQuery] string? category,
            [FromQuery] string? searchTerm)
        {
            var query = new GetUnitTypeFieldsQuery
            {
                unitTypeId = unitTypeId,
                IsActive = isActive,
                IsSearchable = isSearchable,
                IsPublic = isPublic,
                IsForUnits = isForUnits,
                Category = category,
                SearchTerm = searchTerm
            };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

    }
} 