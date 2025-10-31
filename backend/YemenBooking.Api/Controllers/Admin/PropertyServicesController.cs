using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Services.Commands.CreateProperty;
using YemenBooking.Application.Features.Services.Commands.UpdateProperty;
using YemenBooking.Application.Features.Services.Commands.DeleteProperty;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Services.Queries.GetPropertyServices;
using YemenBooking.Application.Features.Services.Queries.GetServicesByType;
using YemenBooking.Application.Features.Services.Queries.GetServiceById;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بخدمات الكيانات للمدراء والمالكين
    /// Controller for property services management (Admin/Owner)
    /// </summary>
    [ApiController]
    [Route("api/admin/[controller]")]
    [Authorize(Roles = "Admin,Owner")]
    public class PropertyServicesController : ControllerBase
    {
        private readonly IMediator _mediator;

        public PropertyServicesController(IMediator mediator)
        {
            _mediator = mediator;
        }

        /// <summary>
        /// إنشاء خدمة جديدة لكيان
        /// Create a new service for a property
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreatePropertyService([FromBody] CreatePropertyServiceCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث بيانات خدمة كيان
        /// Update an existing property service
        /// </summary>
        [HttpPut("{serviceId}")]
        public async Task<IActionResult> UpdatePropertyService(Guid serviceId, [FromBody] UpdatePropertyServiceCommand command)
        {
            command.ServiceId = serviceId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف خدمة كيان
        /// Delete a property service
        /// </summary>
        [HttpDelete("{serviceId}")]
        public async Task<IActionResult> DeletePropertyService(Guid serviceId)
        {
            var command = new DeletePropertyServiceCommand { ServiceId = serviceId };
            var result = await _mediator.Send(command);
            // If failed due to reference checks, return 409 with reason
            if (!result.IsSuccess && (result.Message?.Contains("لا يمكن حذف الخدمة") == true))
            {
                return Conflict(ResultDto.Failure(result.Message, errorCode: "SERVICE_DELETE_CONFLICT"));
            }
            return Ok(result);
        }

        /// <summary>
        /// جلب خدمات كيان معين
        /// Get services for a specific property
        /// </summary>
        [HttpGet("property/{propertyId}")]
        public async Task<IActionResult> GetPropertyServices(Guid propertyId)
        {
            var query = new GetPropertyServicesQuery { PropertyId = propertyId };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب خدمة الكيان بحسب المعرف
        /// Get property service by id
        /// </summary>
        [HttpGet("{serviceId}")]
        public async Task<IActionResult> GetServiceById(Guid serviceId)
        {
            var query = new GetServiceByIdQuery { ServiceId = serviceId };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب الخدمات حسب النوع
        /// Get services by type
        /// </summary>
        [HttpGet("type/{serviceType}")]
        public async Task<IActionResult> GetServicesByType(
            [FromRoute] string serviceType,
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 10)
        {
            var query = new GetServicesByTypeQuery
            {
                ServiceType = serviceType,
                PageNumber = pageNumber,
                PageSize = pageSize,
            };
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 