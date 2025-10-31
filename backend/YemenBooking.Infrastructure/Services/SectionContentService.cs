using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Sections.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Infrastructure.Services
{
    public class SectionContentService : ISectionContentService
    {
        private readonly ISectionRepository _repository;

        public SectionContentService(ISectionRepository repository)
        {
            _repository = repository;
        }

        public async Task<ResultDto> AssignPropertyItemsAsync(Guid sectionId, IEnumerable<PropertyInSection> items, CancellationToken cancellationToken = default)
        {
            await _repository.AssignPropertyItemsAsync(sectionId, items, cancellationToken);
            return ResultDto.Ok();
        }

        public async Task<ResultDto> AssignUnitItemsAsync(Guid sectionId, IEnumerable<UnitInSection> items, CancellationToken cancellationToken = default)
        {
            await _repository.AssignUnitItemsAsync(sectionId, items, cancellationToken);
            return ResultDto.Ok();
        }
    }
}

