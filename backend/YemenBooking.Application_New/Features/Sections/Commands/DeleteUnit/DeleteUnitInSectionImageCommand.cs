using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.Commands.DeleteUnit
{
    public class DeleteUnitInSectionImageCommand : IRequest<ResultDto<bool>>
    {
        public Guid ImageId { get; set; }
        public bool Permanent { get; set; } = false;
    }
}

