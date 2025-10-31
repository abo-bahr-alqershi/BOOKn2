using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Properties.Commands.CreateProperty;
using YemenBooking.Application.Features.Properties.Commands.UpdateProperty;
using YemenBooking.Application.Features.Properties.Commands.DeleteProperty;
using YemenBooking.Application.Features.Properties.Commands.ApproveProperty;
using YemenBooking.Application.Features.Properties.Queries.GetAllProperties;
using YemenBooking.Application.Features.Properties.Queries.GetPendingProperties;
using YemenBooking.Application.Features.Properties.Queries.GetPropertyDetails;
using YemenBooking.Application.Features.Sections.Commands.ManageSectionItems;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بالكيانات للمدراء
    /// Controller for managing properties by admins
    /// </summary>
    public class PropertiesController : BaseAdminController
    {
        private readonly ICurrentUserService _currentUserService;

        public PropertiesController(IMediator mediator, ICurrentUserService currentUserService) : base(mediator) 
        { 
            _currentUserService = currentUserService; 
        }

        /// <summary>
        /// إنشاء كيان جديد
        /// Create a new property
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateProperty([FromBody] CreatePropertyCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث بيانات كيان
        /// Update an existing property
        /// </summary>
        [HttpPut("{propertyId}")]
        public async Task<IActionResult> UpdateProperty(Guid propertyId, [FromBody] UpdatePropertyCommand command)
        {
            command.PropertyId = propertyId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف كيان
        /// Delete a property
        /// </summary>
        [HttpDelete("{propertyId}")]
        public async Task<IActionResult> DeleteProperty(Guid propertyId)
        {
            var command = new DeletePropertyCommand { PropertyId = propertyId };
            var result = await _mediator.Send(command);
            if (!result.Success)
                return Conflict(result);
            return Ok(result);
        }

        /// <summary>
        /// الموافقة على الكيان
        /// Approve a property
        /// </summary>
        [HttpPost("{propertyId}/approve")]
        public async Task<IActionResult> ApproveProperty(Guid propertyId)
        {
            var command = new ApprovePropertyCommand { PropertyId = propertyId, AdminId = _currentUserService.UserId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إضافة الكيان إلى أقسام متعددة
        /// Add property to multiple sections
        /// </summary>
        [HttpPost("{propertyId}/sections")]
        public async Task<IActionResult> AddPropertyToSections(Guid propertyId, [FromBody] AddPropertyToSectionsCommand command)
        {
            command.PropertyId = propertyId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// رفض الكيان
        /// Reject a property
        /// </summary>
        [HttpPost("{propertyId}/reject")]
        public async Task<IActionResult> RejectProperty(Guid propertyId, [FromBody] RejectPropertyCommand command)
        {
            command.PropertyId = propertyId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب جميع الكيانات مع الفلاتر، الفرز، والتصفّح
        /// Get all properties with filters, sorting, and pagination
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllProperties([FromQuery] GetAllPropertiesQuery query)
        {
            var result = await _mediator.Send(query);
            var baseUrl = $"{Request.Scheme}://{Request.Host}";
            foreach (var img in result.Items.Select(i => i.Images).SelectMany(i => i))
            {
                // Ensure absolute Url for the image
                if (!img.Url.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                    img.Url = baseUrl + (img.Url.StartsWith("/") ? img.Url : "/" + img.Url);
                {
                    // Ensure absolute Url for the main image
                    if (!img.Url.StartsWith("http", StringComparison.OrdinalIgnoreCase))
                        img.Url = baseUrl + (img.Url.StartsWith("/") ? img.Url : "/" + img.Url);
                }
            }
            return Ok(result);
        }

        /// <summary>
            /// جلب الكيانات في انتظار الموافقة
            /// Get pending properties
            /// </summary>
            [HttpGet("pending")]
        public async Task<IActionResult> GetPendingProperties([FromQuery] GetPendingPropertiesQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }


        /// <summary>
        /// جلب تفاصيل الكيان مع الحقول الديناميكية
        /// Get property details including dynamic fields
        /// </summary>
        [HttpGet("{propertyId}/details")]
        public async Task<IActionResult> GetPropertyDetails(Guid propertyId, [FromQuery] bool includeUnits = true, [FromQuery] bool includeDynamicFields = true)
        {
            var query = new GetPropertyDetailsQuery { PropertyId = propertyId, IncludeUnits = includeUnits, IncludeDynamicFields = includeDynamicFields };
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
}