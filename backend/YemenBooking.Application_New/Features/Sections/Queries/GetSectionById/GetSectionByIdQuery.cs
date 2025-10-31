using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Features.Sections.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Sections.Queries.GetSectionById
{
    public class GetSectionByIdQuery : IRequest<ResultDto<SectionDto>>
    {
        public Guid SectionId { get; set; }
    }
}

