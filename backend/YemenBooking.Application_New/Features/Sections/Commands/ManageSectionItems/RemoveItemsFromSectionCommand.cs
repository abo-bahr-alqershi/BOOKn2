using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
    public class RemoveItemsFromSectionCommand : IRequest<ResultDto>
    {
        public Guid SectionId { get; set; }
        public List<Guid> ItemIds { get; set; } = new();
    }
}

