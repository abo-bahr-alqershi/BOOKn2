using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Sections.Queries.GetImages
{
    public class GetSectionImagesQuery : IRequest<ResultDto<PaginatedResultDto<ImageDto>>>
    {
        public Guid? SectionId { get; set; }
        public string? TempKey { get; set; }
        public string? SortBy { get; set; } = "order";
        public string? SortOrder { get; set; } = "asc";
        public int Page { get; set; } = 1;
        public int Limit { get; set; } = 50;
    }
}