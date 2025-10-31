using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Sections.Services {
    public interface ISectionContentService
    {
        Task<ResultDto> AssignPropertyItemsAsync(Guid sectionId, IEnumerable<PropertyInSection> items, CancellationToken cancellationToken = default);
        Task<ResultDto> AssignUnitItemsAsync(Guid sectionId, IEnumerable<UnitInSection> items, CancellationToken cancellationToken = default);
    }
}

