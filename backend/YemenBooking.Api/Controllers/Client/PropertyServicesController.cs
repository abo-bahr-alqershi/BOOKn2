using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Services.Queries.GetPropertyServices;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// خدمات الكيانات
    /// property services
    /// </summary>
    public class ServicesController : BaseClientController
    {
        public ServicesController(IMediator mediator) : base(mediator) { }

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

        // Other owner-level operations for services are handled via admin controller (with Owner role access)
    }
}