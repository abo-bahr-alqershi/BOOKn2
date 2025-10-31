using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Sections.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Sections.Queries.GetSections
{
	public class GetSectionsQueryHandler : IRequestHandler<GetSectionsQuery, PaginatedResult<SectionDto>>
	{
		private readonly ISectionRepository _repository;
		private readonly ICurrentUserService _currentUserService;

		public GetSectionsQueryHandler(ISectionRepository repository, ICurrentUserService currentUserService)
		{
			_repository = repository;
			_currentUserService = currentUserService;
		}

		public async Task<PaginatedResult<SectionDto>> Handle(GetSectionsQuery request, CancellationToken cancellationToken)
		{
            var (items, total) = await _repository.GetPagedAsync(request.PageNumber, request.PageSize, request.Target, request.Type, request.CityName, cancellationToken);
			var dtoItems = items.Select(s => new SectionDto
			{
				Id = s.Id,
				Type = s.Type,
				ContentType = s.ContentType,
				DisplayStyle = s.DisplayStyle,
				Name = s.Name,
				Title = s.Title,
				Subtitle = s.Subtitle,
				Description = s.Description,
				ShortDescription = s.ShortDescription,
				DisplayOrder = s.DisplayOrder,
				Target = s.Target,
				IsActive = s.IsActive,
				ColumnsCount = s.ColumnsCount,
				ItemsToShow = s.ItemsToShow,
				Icon = s.Icon,
				ColorTheme = s.ColorTheme,
				BackgroundImage = s.BackgroundImage,
				FilterCriteria = s.FilterCriteria,
				SortCriteria = s.SortCriteria,
				CityName = s.CityName,
				PropertyTypeId = s.PropertyTypeId,
				UnitTypeId = s.UnitTypeId,
				MinPrice = s.MinPrice,
				MaxPrice = s.MaxPrice,
				MinRating = s.MinRating,
				IsVisibleToGuests = s.IsVisibleToGuests,
				IsVisibleToRegistered = s.IsVisibleToRegistered,
				RequiresPermission = s.RequiresPermission,
				StartDate = s.StartDate,
				EndDate = s.EndDate,
				Metadata = s.Metadata,
				CategoryClass = s.CategoryClass,
				HomeItemsCount = s.HomeItemsCount
			}).ToList();

			// Convert date fields to user's local time
			for (int i = 0; i < dtoItems.Count; i++)
			{
				if (dtoItems[i].StartDate.HasValue)
				{
					var local = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtoItems[i].StartDate.Value);
					dtoItems[i].StartDate = local;
				}
				if (dtoItems[i].EndDate.HasValue)
				{
					var local = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtoItems[i].EndDate.Value);
					dtoItems[i].EndDate = local;
				}
			}
			return new PaginatedResult<SectionDto>
			{
				Items = dtoItems,
				TotalCount = total,
				PageNumber = request.PageNumber,
				PageSize = request.PageSize
			};
		}
	}
}