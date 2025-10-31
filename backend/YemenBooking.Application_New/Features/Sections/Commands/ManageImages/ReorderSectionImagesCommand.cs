using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Features.Properties.Commands.ManageImages;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.Commands.ManageImages
{
    public class ReorderSectionImagesCommand : IRequest<ResultDto<bool>>
    {
        public List<ImageOrderAssignment> Assignments { get; set; } = new List<ImageOrderAssignment>();
    }
}

