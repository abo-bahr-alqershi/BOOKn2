using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Sections.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Sections.Queries.GetSectionById
{
    public class GetSectionByIdQueryHandler : IRequestHandler<GetSectionByIdQuery, ResultDto<SectionDto>>
    {
        private readonly ISectionRepository _repository;
        private readonly ICurrentUserService _currentUserService;

        public GetSectionByIdQueryHandler(ISectionRepository repository, ICurrentUserService currentUserService)
        {
            _repository = repository;
            _currentUserService = currentUserService;
        }

        public async Task<ResultDto<SectionDto>> Handle(GetSectionByIdQuery request, CancellationToken cancellationToken)
        {
            var s = await _repository.GetByIdAsync(request.SectionId, cancellationToken);
            if (s == null) return ResultDto<SectionDto>.Failure("Section not found");
            var dto = new SectionDto
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
            };
            if (dto.StartDate.HasValue)
                dto.StartDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.StartDate.Value);
            if (dto.EndDate.HasValue)
                dto.EndDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(dto.EndDate.Value);
            return ResultDto<SectionDto>.Ok(dto);
        }
    }
}

