using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
	public class AddPropertyToSectionsCommand : IRequest<ResultDto>
	{
		public Guid PropertyId { get; set; }
		public List<Guid> SectionIds { get; set; } = new();
	}
}