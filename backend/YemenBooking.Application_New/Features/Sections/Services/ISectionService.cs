using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Features.Sections.DTOs;

namespace YemenBooking.Application.Features.Sections.Services {
    public interface ISectionService
    {
        Task<ResultDto<SectionDto>> CreateAsync(CreateSectionDto dto, CancellationToken cancellationToken = default);
        Task<ResultDto<SectionDto>> UpdateAsync(UpdateSectionDto dto, CancellationToken cancellationToken = default);
        Task<ResultDto> ToggleStatusAsync(Guid sectionId, bool isActive, CancellationToken cancellationToken = default);
    }
}

