using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
	public class AssignSectionItemsCommandHandler : IRequestHandler<AssignSectionItemsCommand, ResultDto>
	{
		private readonly ISectionRepository _repository;

		public AssignSectionItemsCommandHandler(ISectionRepository repository)
		{
			_repository = repository;
		}

        public async Task<ResultDto> Handle(AssignSectionItemsCommand request, CancellationToken cancellationToken)
        {
            if (request.PropertyIds.Count > 0)
            {
                await _repository.AssignPropertiesAsync(request.SectionId, request.PropertyIds, cancellationToken);
            }
            else if (request.UnitIds.Count > 0)
            {
                await _repository.AssignUnitsAsync(request.SectionId, request.UnitIds, cancellationToken);
            }
            else
            {
                // Clear rich items when both lists are empty
                await _repository.AssignPropertyItemsAsync(request.SectionId, Array.Empty<PropertyInSection>(), cancellationToken);
                await _repository.AssignUnitItemsAsync(request.SectionId, Array.Empty<UnitInSection>(), cancellationToken);
            }
            return ResultDto.Ok();
        }
	}
}