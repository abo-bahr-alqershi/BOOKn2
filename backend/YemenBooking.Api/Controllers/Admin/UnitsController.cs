using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Sections.Commands.ManageSectionItems;
using YemenBooking.Application.Features.Units.Commands.CreateUnit;
using YemenBooking.Application.Features.Units.Commands.DeleteUnit;
using YemenBooking.Application.Features.Units.Commands.UpdateUnit;
using YemenBooking.Application.Features.Units.Queries.GetUnitById;
using YemenBooking.Application.Features.Units.Queries.GetUnitDetails;
using YemenBooking.Application.Features.Units.Queries.SearchUnits;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بتحديث توفر الوحدات للمدراء
    /// Controller for bulk updating unit availability by admins
    /// </summary>
    public class UnitsController : BaseAdminController
    {
        public UnitsController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// جلب جميع الوحدات مع الصفحات والفلاتر
        /// Get all units with pagination and filters
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetAllUnits([FromQuery] SearchUnitsQuery query)
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
        /// إنشاء وحدة جديدة
        /// Create a new unit
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateUnit([FromBody] CreateUnitCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تحديث بيانات وحدة
        /// Update an existing unit
        /// </summary>
        [HttpPut("{id}")]
        public async Task<IActionResult> UpdateUnit(Guid id, [FromBody] UpdateUnitCommand command)
        {
            command.UnitId = id;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// حذف وحدة
        /// Delete a unit
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteUnit(Guid id)
        {
            var command = new DeleteUnitCommand { UnitId = id };
            var result = await _mediator.Send(command);
            if (!result.Success)
                return Conflict(result);
            return Ok(result);
        }

        /// <summary>
        /// إضافة الوحدة إلى أقسام متعددة
        /// Add unit to multiple sections
        /// </summary>
        [HttpPost("{id}/sections")]
        public async Task<IActionResult> AddUnitToSections(Guid id, [FromBody] AddUnitToSectionsCommand command)
        {
            command.UnitId = id;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب بيانات وحدة بواسطة المعرف
        /// Get unit details by ID
        /// </summary>
        [HttpGet("{id}")]
        public async Task<IActionResult> GetUnitById(Guid id)
        {
            var query = new GetUnitByIdQuery { UnitId = id };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على تفاصيل الوحدة
        /// Get unit details including dynamic fields
        /// </summary>
        [HttpGet("{unitId}/details")]
        public async Task<IActionResult> GetUnitDetails(Guid unitId, [FromQuery] bool includeDynamicFields = true)
        {
            var query = new GetUnitByIdQuery { UnitId = unitId, IncludeDynamicFields = includeDynamicFields };
            var result = await _mediator.Send(query);
            return Ok(result);
        }

    }
} 