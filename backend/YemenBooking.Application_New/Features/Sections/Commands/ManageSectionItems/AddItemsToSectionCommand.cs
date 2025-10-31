using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
    public class AddItemsToSectionCommand : IRequest<ResultDto>
    {
        public Guid SectionId { get; set; }
        public List<Guid> PropertyIds { get; set; } = new();
        public List<Guid> UnitIds { get; set; } = new();
    }
}

