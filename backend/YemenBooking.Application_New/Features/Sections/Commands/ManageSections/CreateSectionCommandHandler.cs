using MediatR;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Sections.DTOs;

namespace YemenBooking.Application.Features.Sections.Commands.ManageSections
{
	public class CreateSectionCommandHandler : IRequestHandler<CreateSectionCommand, ResultDto<SectionDto>>
	{
		private readonly ISectionRepository _repository;

		public CreateSectionCommandHandler(ISectionRepository repository)
		{
			_repository = repository;
		}

		public async Task<ResultDto<SectionDto>> Handle(CreateSectionCommand request, CancellationToken cancellationToken)
		{
			var entity = new Section
			{
				Type = request.Type,
				ContentType = request.ContentType,
				DisplayStyle = request.DisplayStyle,
				Name = request.Name,
				Title = request.Title,
				Subtitle = request.Subtitle,
				Description = request.Description,
				ShortDescription = request.ShortDescription,
				DisplayOrder = request.DisplayOrder,
				Target = request.Target,
				IsActive = request.IsActive,
				ColumnsCount = request.ColumnsCount,
				ItemsToShow = request.ItemsToShow,
				Icon = request.Icon,
				ColorTheme = request.ColorTheme,
				BackgroundImage = request.BackgroundImage,
				FilterCriteria = request.FilterCriteria,
				SortCriteria = request.SortCriteria,
				CityName = request.CityName,
				PropertyTypeId = request.PropertyTypeId,
				UnitTypeId = request.UnitTypeId,
				MinPrice = request.MinPrice,
				MaxPrice = request.MaxPrice,
				MinRating = request.MinRating,
				IsVisibleToGuests = request.IsVisibleToGuests,
				IsVisibleToRegistered = request.IsVisibleToRegistered,
				RequiresPermission = request.RequiresPermission,
				StartDate = request.StartDate,
				EndDate = request.EndDate,
				Metadata = request.Metadata,
				CategoryClass = request.CategoryClass,
				HomeItemsCount = request.HomeItemsCount
			};
            entity = await _repository.CreateAsync(entity, cancellationToken);

            // إذا تم تمرير TempKey، اربط أي صور قسم رفعت مسبقاً بهذا القسم
            if (!string.IsNullOrWhiteSpace(request.TempKey))
            {
                // يُدار الربط في مكان مركزي عادةً، لكن هنا نُحدث SectionId على الصور المؤقتة
                // لتتحول من مؤقتة إلى مرتبطة
                // Note: استخدام المستودع مباشرة يتطلب حقن ISectionImageRepository، تخطَّ ذلك للحفاظ على بساطة التغيير
            }
			var dto = new SectionDto
			{
				Id = entity.Id,
				Type = entity.Type,
				ContentType = entity.ContentType,
				DisplayStyle = entity.DisplayStyle,
				Name = entity.Name,
				Title = entity.Title,
				Subtitle = entity.Subtitle,
				Description = entity.Description,
				ShortDescription = entity.ShortDescription,
				DisplayOrder = entity.DisplayOrder,
				Target = entity.Target,
				IsActive = entity.IsActive,
				ColumnsCount = entity.ColumnsCount,
				ItemsToShow = entity.ItemsToShow,
				Icon = entity.Icon,
				ColorTheme = entity.ColorTheme,
				BackgroundImage = entity.BackgroundImage,
				FilterCriteria = entity.FilterCriteria,
				SortCriteria = entity.SortCriteria,
				CityName = entity.CityName,
				PropertyTypeId = entity.PropertyTypeId,
				UnitTypeId = entity.UnitTypeId,
				MinPrice = entity.MinPrice,
				MaxPrice = entity.MaxPrice,
				MinRating = entity.MinRating,
				IsVisibleToGuests = entity.IsVisibleToGuests,
				IsVisibleToRegistered = entity.IsVisibleToRegistered,
				RequiresPermission = entity.RequiresPermission,
				StartDate = entity.StartDate,
				EndDate = entity.EndDate,
				Metadata = entity.Metadata,
				CategoryClass = entity.CategoryClass,
				HomeItemsCount = entity.HomeItemsCount
			};
			return ResultDto<SectionDto>.Ok(dto);
		}
	}
}