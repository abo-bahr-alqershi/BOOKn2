using System;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Sections.Queries.GetSectionItems
{
	public class GetSectionItemsQuery : PaginationDto, IRequest<PaginatedResult<object>>
	{
		public Guid SectionId { get; set; }
	}
}