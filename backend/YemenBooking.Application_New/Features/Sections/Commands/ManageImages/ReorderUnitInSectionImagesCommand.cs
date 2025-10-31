using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.Commands.ManageImages;

namespace YemenBooking.Application.Features.Sections.Commands.ManageImages
{
    public class ReorderUnitInSectionImagesCommand : IRequest<ResultDto<bool>>
    {
        public List<ImageOrderAssignment> Assignments { get; set; } = new List<ImageOrderAssignment>();
    }
}

