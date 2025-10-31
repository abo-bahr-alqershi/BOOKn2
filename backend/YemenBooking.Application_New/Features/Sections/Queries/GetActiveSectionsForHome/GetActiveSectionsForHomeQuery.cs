using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Features.Sections.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Sections.Queries.GetActiveSectionsForHome
{
    public class GetActiveSectionsForHomeQuery : IRequest<IEnumerable<SectionDto>>
    {
        public string? CityName { get; set; }
    }
}

