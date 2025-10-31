using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.PropertyTypes.Commands.CreateProperty;
using YemenBooking.Application.Features.PropertyTypes.Commands.UpdateProperty;
using YemenBooking.Application.Features.PropertyTypes.Commands.DeleteProperty;
using YemenBooking.Application.Features.PropertyTypes.Queries.GetPropertyTypes;
using YemenBooking.Application.Features.PropertyTypes.Queries.GetAllPropertyTypes;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بأنواع الكيانات للمدراء
    /// Controller for managing property types by admins
    /// </summary>
    public class PropertyTypesController : BaseAdminController
    {
        public PropertyTypesController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// إنشاء نوع كيان جديد
        /// Create a new property type
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreatePropertyType([FromBody] CreatePropertyTypeCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث نوع كيان
        /// Update an existing property type
        /// </summary>
        [HttpPut("{propertyTypeId}")]
        public async Task<IActionResult> UpdatePropertyType(Guid propertyTypeId, [FromBody] UpdatePropertyTypeCommand command)
        {
            command.PropertyTypeId = propertyTypeId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف نوع كيان
        /// Delete a property type
        /// </summary>
        [HttpDelete("{propertyTypeId}")]
        public async Task<IActionResult> DeletePropertyType(Guid propertyTypeId)
        {
            var command = new DeletePropertyTypeCommand { PropertyTypeId = propertyTypeId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب جميع أنواع الكيانات مع الصفحات
        /// Get all property types with pagination
        /// </summary>
        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetAllPropertyTypes([FromQuery] GetAllPropertyTypesQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 