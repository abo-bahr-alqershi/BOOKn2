using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
    public class RemoveItemsFromSectionCommandHandler : IRequestHandler<RemoveItemsFromSectionCommand, ResultDto>
    {
        private readonly ISectionRepository _repository;

        public RemoveItemsFromSectionCommandHandler(ISectionRepository repository)
        {
            _repository = repository;
        }

        public async Task<ResultDto> Handle(RemoveItemsFromSectionCommand request, CancellationToken cancellationToken)
        {
            foreach (var id in request.ItemIds)
            {
                await _repository.RemoveItemAsync(request.SectionId, id, cancellationToken);
            }
            return ResultDto.Ok();
        }
    }
}

