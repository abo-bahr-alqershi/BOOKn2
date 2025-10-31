using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
    public class AddItemsToSectionCommandHandler : IRequestHandler<AddItemsToSectionCommand, ResultDto>
    {
        private readonly ISectionRepository _repository;

        public AddItemsToSectionCommandHandler(ISectionRepository repository)
        {
            _repository = repository;
        }

        public async Task<ResultDto> Handle(AddItemsToSectionCommand request, CancellationToken cancellationToken)
        {
            if (request.PropertyIds?.Count > 0)
                await _repository.AddPropertiesAsync(request.SectionId, request.PropertyIds, cancellationToken);
            if (request.UnitIds?.Count > 0)
                await _repository.AddUnitsAsync(request.SectionId, request.UnitIds, cancellationToken);
            return ResultDto.Ok();
        }
    }
}

