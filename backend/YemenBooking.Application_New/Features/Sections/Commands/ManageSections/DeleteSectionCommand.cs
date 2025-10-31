using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSections
{
	public class DeleteSectionCommand : IRequest<ResultDto>
	{
		public Guid SectionId { get; set; }
	}
}