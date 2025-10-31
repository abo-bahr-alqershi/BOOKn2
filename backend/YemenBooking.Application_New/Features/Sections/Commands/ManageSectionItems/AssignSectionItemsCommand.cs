using System;
using System.Collections.Generic;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
	public class AssignSectionItemsCommand : IRequest<ResultDto>
	{
		public Guid SectionId { get; set; }
		public List<Guid> PropertyIds { get; set; } = new();
		public List<Guid> UnitIds { get; set; } = new();
	}
}