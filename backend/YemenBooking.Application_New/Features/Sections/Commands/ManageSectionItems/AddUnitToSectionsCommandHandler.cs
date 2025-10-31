using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
	public class AddUnitToSectionsCommandHandler : IRequestHandler<AddUnitToSectionsCommand, ResultDto>
	{
		private readonly ISectionRepository _repository;

		public AddUnitToSectionsCommandHandler(ISectionRepository repository)
		{
			_repository = repository;
		}

		public async Task<ResultDto> Handle(AddUnitToSectionsCommand request, CancellationToken cancellationToken)
		{
			foreach (var sectionId in request.SectionIds)
			{
				await _repository.AddUnitsAsync(sectionId, new[] { request.UnitId }, cancellationToken);
			}
			return ResultDto.Ok();
		}
	}
}