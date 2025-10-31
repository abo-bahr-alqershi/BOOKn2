using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections.DTOs;
using YemenBooking.Application.Features.Sections.Services;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Infrastructure.Services
{
    public class SectionService : ISectionService
    {
        private readonly ISectionRepository _repository;

        public SectionService(ISectionRepository repository)
        {
            _repository = repository;
        }

        public async Task<ResultDto<SectionDto>> CreateAsync(CreateSectionDto dto, CancellationToken cancellationToken = default)
        {
            var entity = new Section
            {
                Type = dto.Type,
                ContentType = dto.ContentType,
                DisplayStyle = dto.DisplayStyle,
                Name = dto.Name,
                Title = dto.Title,
                Subtitle = dto.Subtitle,
                Description = dto.Description,
                ShortDescription = dto.ShortDescription,
                DisplayOrder = dto.DisplayOrder,
                Target = dto.Target,
                IsActive = dto.IsActive,
                ColumnsCount = dto.ColumnsCount,
                ItemsToShow = dto.ItemsToShow,
                Icon = dto.Icon,
                ColorTheme = dto.ColorTheme,
                BackgroundImage = dto.BackgroundImage,
                FilterCriteria = dto.FilterCriteria,
                SortCriteria = dto.SortCriteria,
                CityName = dto.CityName,
                PropertyTypeId = dto.PropertyTypeId,
                UnitTypeId = dto.UnitTypeId,
                MinPrice = dto.MinPrice,
                MaxPrice = dto.MaxPrice,
                MinRating = dto.MinRating,
                IsVisibleToGuests = dto.IsVisibleToGuests,
                IsVisibleToRegistered = dto.IsVisibleToRegistered,
                RequiresPermission = dto.RequiresPermission,
                StartDate = dto.StartDate,
                EndDate = dto.EndDate,
                Metadata = dto.Metadata
            };

            entity = await _repository.CreateAsync(entity, cancellationToken);
            return ResultDto<SectionDto>.Ok(Map(entity));
        }

        public async Task<ResultDto<SectionDto>> UpdateAsync(UpdateSectionDto dto, CancellationToken cancellationToken = default)
        {
            var entity = await _repository.GetByIdAsync(dto.SectionId, cancellationToken);
            if (entity == null) return ResultDto<SectionDto>.Failure("Section not found");

            entity.Type = dto.Type;
            entity.ContentType = dto.ContentType;
            entity.DisplayStyle = dto.DisplayStyle;
            entity.Name = dto.Name;
            entity.Title = dto.Title;
            entity.Subtitle = dto.Subtitle;
            entity.Description = dto.Description;
            entity.ShortDescription = dto.ShortDescription;
            entity.DisplayOrder = dto.DisplayOrder;
            entity.Target = dto.Target;
            entity.IsActive = dto.IsActive;
            entity.ColumnsCount = dto.ColumnsCount;
            entity.ItemsToShow = dto.ItemsToShow;
            entity.Icon = dto.Icon;
            entity.ColorTheme = dto.ColorTheme;
            entity.BackgroundImage = dto.BackgroundImage;
            entity.FilterCriteria = dto.FilterCriteria;
            entity.SortCriteria = dto.SortCriteria;
            entity.CityName = dto.CityName;
            entity.PropertyTypeId = dto.PropertyTypeId;
            entity.UnitTypeId = dto.UnitTypeId;
            entity.MinPrice = dto.MinPrice;
            entity.MaxPrice = dto.MaxPrice;
            entity.MinRating = dto.MinRating;
            entity.IsVisibleToGuests = dto.IsVisibleToGuests;
            entity.IsVisibleToRegistered = dto.IsVisibleToRegistered;
            entity.RequiresPermission = dto.RequiresPermission;
            entity.StartDate = dto.StartDate;
            entity.EndDate = dto.EndDate;
            entity.Metadata = dto.Metadata;

            await _repository.UpdateAsync(entity, cancellationToken);
            return ResultDto<SectionDto>.Ok(Map(entity));
        }

        public async Task<ResultDto> ToggleStatusAsync(Guid sectionId, bool isActive, CancellationToken cancellationToken = default)
        {
            var entity = await _repository.GetByIdAsync(sectionId, cancellationToken);
            if (entity == null) return ResultDto.Failure("Section not found");
            entity.IsActive = isActive;
            await _repository.UpdateAsync(entity, cancellationToken);
            return ResultDto.Ok();
        }

        private static SectionDto Map(Section s) => new()
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
        };
    }
}

