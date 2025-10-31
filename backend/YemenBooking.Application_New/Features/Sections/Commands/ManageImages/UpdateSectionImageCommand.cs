using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Sections.Commands.ManageImages
{
    public class UpdateSectionImageCommand : IRequest<ResultDto<ImageDto>>
    {
        public Guid ImageId { get; set; }
        public Guid? SectionId { get; set; }
        public string? TempKey { get; set; }
        public string? Alt { get; set; }
        public bool? IsPrimary { get; set; }
        public int? Order { get; set; }
        public List<string>? Tags { get; set; }
        public ImageCategory? Category { get; set; }
    }
}

