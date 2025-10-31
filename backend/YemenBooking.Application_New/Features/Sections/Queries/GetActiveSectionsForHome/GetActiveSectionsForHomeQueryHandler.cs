using MediatR;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections.DTOs;

namespace YemenBooking.Application.Features.Sections.Queries.GetActiveSectionsForHome
{
    public class GetActiveSectionsForHomeQueryHandler : IRequestHandler<GetActiveSectionsForHomeQuery, IEnumerable<SectionDto>>
    {
        private readonly ISectionRepository _repository;

        public GetActiveSectionsForHomeQueryHandler(ISectionRepository repository)
        {
            _repository = repository;
        }

        public async Task<IEnumerable<SectionDto>> Handle(GetActiveSectionsForHomeQuery request, CancellationToken cancellationToken)
        {
            var items = await _repository.FindAsync(s => s.IsActive, cancellationToken);
            if (!string.IsNullOrWhiteSpace(request.CityName))
            {
                var city = request.CityName!.Trim();
                items = items.Where(s => string.IsNullOrWhiteSpace(s.CityName) || s.CityName!.Trim().Equals(city, StringComparison.OrdinalIgnoreCase));
            }
            return items
                .OrderBy(s => s.DisplayOrder)
                .Select(s => new SectionDto
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
                });
        }
    }
}

