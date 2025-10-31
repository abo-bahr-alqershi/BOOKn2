using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Sections.Queries.GetAllSections
{
    public class GetAllSectionsQueryHandler : IRequestHandler<GetAllSectionsQuery, IEnumerable<SectionDto>>
    {
        private readonly ISectionRepository _repository;
        private readonly ICurrentUserService _currentUserService;

        public GetAllSectionsQueryHandler(ISectionRepository repository, ICurrentUserService currentUserService)
        {
            _repository = repository;
            _currentUserService = currentUserService;
        }

        public async Task<IEnumerable<SectionDto>> Handle(GetAllSectionsQuery request, CancellationToken cancellationToken)
        {
            var items = await _repository.GetAllAsync(cancellationToken);
            var dtos = items.OrderBy(s => s.DisplayOrder).Select(s => new SectionDto
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
                Metadata = s.Metadata
            }).ToList();

            for (int i = 0; i < dtos.Count; i++)
            {
                if (dtos[i].StartDate.HasValue)
                {
                    dtos[i].StartDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].StartDate.Value);
                }
                if (dtos[i].EndDate.HasValue)
                {
                    dtos[i].EndDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].EndDate.Value);
                }
            }

            return dtos;
        }
    }
}

