using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Sections.Commands.ManageSections;
using YemenBooking.Application.Features.Sections.Commands.ManageSectionItems;
using YemenBooking.Application.Features.Sections.Queries.GetSections;
using YemenBooking.Application.Features.Sections.Queries.GetSectionById;

namespace YemenBooking.Api.Controllers.Admin
{
	public class SectionsController : BaseAdminController
	{
		public SectionsController(IMediator mediator) : base(mediator) { }

		[HttpGet]
		public async Task<IActionResult> GetSections([FromQuery] GetSectionsQuery query)
		{
			var result = await _mediator.Send(query);
			return Ok(result);
		}

		[HttpGet("{sectionId}")]
		public async Task<IActionResult> GetSectionById(Guid sectionId)
		{
			var result = await _mediator.Send(new GetSectionByIdQuery { SectionId = sectionId });
			return Ok(result);
		}

		[HttpPost]
		public async Task<IActionResult> CreateSection([FromBody] CreateSectionCommand command)
		{
			var result = await _mediator.Send(command);
			return Ok(result);
		}

		[HttpPost("{sectionId}/toggle-status")]
		public async Task<IActionResult> ToggleStatus(Guid sectionId, [FromBody] ToggleSectionStatusCommand command)
		{
			command.SectionId = sectionId;
			var result = await _mediator.Send(command);
			return Ok(result);
		}

		[HttpPut("{sectionId}")]
		public async Task<IActionResult> UpdateSection(Guid sectionId, [FromBody] UpdateSectionCommand command)
		{
			command.SectionId = sectionId;
			var result = await _mediator.Send(command);
			return Ok(result);
		}

		[HttpDelete("{sectionId}")]
		public async Task<IActionResult> DeleteSection(Guid sectionId)
		{
			var result = await _mediator.Send(new DeleteSectionCommand { SectionId = sectionId });
			return Ok(result);
		}

        [HttpPost("{sectionId}/assign-items")]
        public async Task<IActionResult> AssignItems(Guid sectionId, [FromBody] AssignSectionItemsCommand command)
        {
            command.SectionId = sectionId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

		[HttpPost("{sectionId}/add-items")]
		public async Task<IActionResult> AddItems(Guid sectionId, [FromBody] AddItemsToSectionCommand command)
		{
			command.SectionId = sectionId;
			var result = await _mediator.Send(command);
			return Ok(result);
		}

        [HttpPost("{sectionId}/remove-items")]
        public async Task<IActionResult> RemoveItems(Guid sectionId, [FromBody] RemoveItemsFromSectionCommand command)
        {
            command.SectionId = sectionId;
            var result = await _mediator.Send(command);
            return Ok(result);
        }

		[HttpPost("{sectionId}/reorder-items")]
		public async Task<IActionResult> ReorderItems(Guid sectionId, [FromBody] UpdateItemOrderCommand command)
		{
			command.SectionId = sectionId;
			var result = await _mediator.Send(command);
			return Ok(result);
		}
	}
}