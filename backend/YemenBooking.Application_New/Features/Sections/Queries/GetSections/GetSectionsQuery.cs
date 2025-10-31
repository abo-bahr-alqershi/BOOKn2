using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Sections.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Sections.Queries.GetSections
{
	public class GetSectionsQuery : PaginationDto, IRequest<PaginatedResult<SectionDto>>
	{
		public SectionTarget? Target { get; set; }
		public SectionType? Type { get; set; }
		public ContentType? ContentType { get; set; }
		public string? CityName { get; set; }
	}
}