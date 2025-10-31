using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSections
{
    public class ToggleSectionStatusCommandHandler : IRequestHandler<ToggleSectionStatusCommand, ResultDto>
    {
        private readonly ISectionRepository _repository;

        public ToggleSectionStatusCommandHandler(ISectionRepository repository)
        {
            _repository = repository;
        }

        public async Task<ResultDto> Handle(ToggleSectionStatusCommand request, CancellationToken cancellationToken)
        {
            var entity = await _repository.GetByIdAsync(request.SectionId, cancellationToken);
            if (entity == null) return ResultDto.Failure("Section not found");
            entity.IsActive = request.IsActive;
            await _repository.UpdateAsync(entity, cancellationToken);
            return ResultDto.Ok();
        }
    }
}

