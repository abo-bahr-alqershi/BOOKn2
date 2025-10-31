using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSections
{
    public class ToggleSectionStatusCommand : IRequest<ResultDto>
    {
        public Guid SectionId { get; set; }
        public bool IsActive { get; set; }
    }
}

