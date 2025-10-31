using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
	public class AddUnitToSectionsCommand : IRequest<ResultDto>
	{
		public Guid UnitId { get; set; }
		public List<Guid> SectionIds { get; set; } = new();
	}
}