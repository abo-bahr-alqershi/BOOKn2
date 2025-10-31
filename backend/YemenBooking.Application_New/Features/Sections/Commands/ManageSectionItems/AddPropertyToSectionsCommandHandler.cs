using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSectionItems
{
	public class AddPropertyToSectionsCommandHandler : IRequestHandler<AddPropertyToSectionsCommand, ResultDto>
	{
		private readonly ISectionRepository _repository;

		public AddPropertyToSectionsCommandHandler(ISectionRepository repository)
		{
			_repository = repository;
		}

		public async Task<ResultDto> Handle(AddPropertyToSectionsCommand request, CancellationToken cancellationToken)
		{
			foreach (var sectionId in request.SectionIds)
			{
				await _repository.AddPropertiesAsync(sectionId, new[] { request.PropertyId }, cancellationToken);
			}
			return ResultDto.Ok();
		}
	}
}