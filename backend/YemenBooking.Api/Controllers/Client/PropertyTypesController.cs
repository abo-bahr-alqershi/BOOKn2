using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.PropertyTypes.Queries.GetPropertyTypes;
using YemenBooking.Application.Common.Models;
using System.Collections.Generic;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.PropertyTypes.DTOs;
using YemenBooking.Application.Features.PropertyTypes.Queries.GetPropertyTypesWithUnits;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر أنواع العقارات للعملاء
    /// Client Property Types Controller
    /// </summary>
    public class PropertyTypesController : BaseClientController
    {
        public PropertyTypesController(IMediator mediator) : base(mediator)
        {
        }

        /// <summary>
        /// الحصول على جميع أنواع العقارات
        /// Get all property types
        /// </summary>
        /// <returns>قائمة أنواع العقارات</returns>
        [HttpGet]
        [AllowAnonymous]
        public async Task<ActionResult<ResultDto<List<PropertyTypeDto>>>> GetPropertyTypes()
        {
            var query = new GetPropertyTypesQuery();
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على أنواع العقارات مع أنواع الوحدات التابعة لها في استعلام واحد
        /// Get property types with their unit types in a single call
        /// </summary>
        [HttpGet("with-units")]
        [AllowAnonymous]
        public async Task<ActionResult<ResultDto<List<PropertyTypeWithUnitsDto>>>> GetPropertyTypesWithUnits()
        {
            var result = await _mediator.Send(new GetPropertyTypesWithUnitsQuery());
            return Ok(result);
        }
    }
}
