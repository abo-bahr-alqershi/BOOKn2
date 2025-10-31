using MediatR;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters;
using YemenBooking.Application.Features.Sections;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Sections.Queries.GetSectionItems
{
	public class GetSectionItemsQueryHandler : IRequestHandler<GetSectionItemsQuery, PaginatedResult<object>>
	{
    	private readonly ISectionRepository _sections;
		private readonly IPropertyRepository _properties;
		private readonly IUnitRepository _units;
        private readonly IPropertyImageRepository _images;
        private readonly IPropertyInSectionImageRepository _propertyInSectionImages;
        private readonly IUnitInSectionImageRepository _unitInSectionImages;
        private readonly ICurrentUserService _currentUserService;

		public GetSectionItemsQueryHandler(
			ISectionRepository sections,
            IPropertyRepository properties,
            IUnitRepository units,
            IPropertyImageRepository images,
            IPropertyInSectionImageRepository propertyInSectionImages,
            IUnitInSectionImageRepository unitInSectionImages,
            ICurrentUserService currentUserService)
		{
			_sections = sections;
			_properties = properties;
			_units = units;
			_images = images;
			_propertyInSectionImages = propertyInSectionImages;
			_unitInSectionImages = unitInSectionImages;
            _currentUserService = currentUserService;
		}

		public async Task<PaginatedResult<object>> Handle(GetSectionItemsQuery request, CancellationToken cancellationToken)
		{
			if (request.PageNumber <= 0) request.PageNumber = 1;
			if (request.PageSize <= 0) request.PageSize = 10;

			var section = await _sections.GetByIdAsync(request.SectionId, cancellationToken);
			if (section == null || section.ContentType == ContentType.None)
				return PaginatedResult<object>.Empty(request.PageNumber, request.PageSize);

			// Use rich tables instead of legacy SectionItems
            if (section.Target == SectionTarget.Properties)
            {
                var allItems = (await _sections.GetPropertyItemsAsync(request.SectionId, cancellationToken)).ToList();
                var total = allItems.Count;
                if (total == 0)
                    return PaginatedResult<object>.Empty(request.PageNumber, request.PageSize);

                var pagedItems = allItems
                    .OrderBy(i => i.DisplayOrder)
                    .Skip((request.PageNumber - 1) * request.PageSize)
                    .Take(request.PageSize)
                    .ToList();

                var resultObjects = new List<object>();
                foreach (var p in pagedItems)
                {
                    // Priority 1: images stored in dedicated PropertyInSectionImage table
                    var sectionImgs = (await _propertyInSectionImages.GetByPropertyInSectionIdAsync(p.Id, cancellationToken))
                        .OrderBy(i => i.DisplayOrder)
                        .ToList();

                    List<PropertyImageDto> additional;
                    if (sectionImgs.Count > 0)
                    {
                        additional = sectionImgs.Select(i => new PropertyImageDto
                        {
                            Id = i.Id,
                            PropertyId = null,
                            UnitId = null,
                            SectionId = null,
                            PropertyInSectionId = p.Id,
                            UnitInSectionId = null,
                            CityName = null,
                            Name = i.Name,
                            Url = i.Url,
                            SizeBytes = i.SizeBytes,
                            Type = i.Type,
                            Category = i.Category,
                            Caption = i.Caption,
                            AltText = i.AltText,
                            Tags = i.Tags,
                            Sizes = i.Sizes ?? string.Empty,
                            IsMain = i.IsMainImage,
                            DisplayOrder = i.DisplayOrder,
                            UploadedAt = i.UploadedAt,
                            Status = i.Status,
                            AssociationType = "Property"
                        }).ToList();
                    }
                    else
                    {
                        // Fallback: property images
                        var propImgs = (await _images.GetImagesByPropertyAsync(p.PropertyId, cancellationToken))
                            .OrderBy(i => i.DisplayOrder)
                            .ToList();
                        additional = propImgs.Select(i => new PropertyImageDto
                        {
                            Id = i.Id,
                            PropertyId = i.PropertyId,
                            UnitId = i.UnitId,
                            SectionId = i.SectionId,
                            PropertyInSectionId = i.PropertyInSectionId,
                            UnitInSectionId = i.UnitInSectionId,
                            CityName = i.CityName,
                            Name = i.Name,
                            Url = i.Url,
                            SizeBytes = i.SizeBytes,
                            Type = i.Type,
                            Category = i.Category,
                            Caption = i.Caption,
                            AltText = i.AltText,
                            Tags = i.Tags,
                            Sizes = i.Sizes,
                            IsMain = i.IsMainImage,
                            DisplayOrder = i.DisplayOrder,
                            UploadedAt = i.UploadedAt,
                            Status = i.Status,
                            AssociationType = i.UnitId.HasValue ? "Unit" : "Property"
                        }).ToList();
                    }

                    var hasSectionImages = sectionImgs.Count > 0;
                    var mainImage = hasSectionImages
                        ? (additional.FirstOrDefault(i => i.IsMain)?.Url ?? additional.FirstOrDefault()?.Url)
                        : (string.IsNullOrWhiteSpace(p.MainImage)
                            ? (additional.FirstOrDefault(i => i.IsMain)?.Url ?? additional.FirstOrDefault()?.Url)
                            : p.MainImage);
                    var mainImageId = additional.FirstOrDefault(i => i.IsMain)?.Id;

                    var obj = new
                    {
                        Id = p.PropertyId,
                        PropertyInSectionId = p.Id,
                        Name = p.PropertyName,
                        Description = p.ShortDescription ?? string.Empty,
                        City = p.City,
                        Address = p.Address,
                        StarRating = p.StarRating,
                        AverageRating = p.AverageRating,
                        ReviewCount = p.ReviewsCount,
                        MinPrice = p.BasePrice,
                        Currency = p.Currency,
                        MainImageUrl = mainImage,
                        MainImageId = mainImageId,
                        ImageUrls = additional.Select(a => a.Url).ToList(),
                        AdditionalImages = additional,
                        Amenities = new List<string>(),
                        PropertyType = p.PropertyType,
                        DistanceKm = (decimal?)null,
                        IsAvailable = true,
                        AvailableUnitsCount = 0,
                        MaxCapacity = 0,
                        IsFeatured = p.IsFeatured,
                        LastUpdated = DateTime.UtcNow
                    };
                    // Localize image UploadedAt and LastUpdated
                    var localizedAdditional = new List<PropertyImageDto>();
                    foreach (var a in additional)
                    {
                        a.UploadedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(a.UploadedAt);
                        localizedAdditional.Add(a);
                    }
                    var localizedLastUpdated = await _currentUserService.ConvertFromUtcToUserLocalAsync(obj.LastUpdated);
                    resultObjects.Add(new
                    {
                        obj.Id,
                        obj.PropertyInSectionId,
                        obj.Name,
                        obj.Description,
                        obj.City,
                        obj.Address,
                        obj.StarRating,
                        obj.AverageRating,
                        obj.ReviewCount,
                        obj.MinPrice,
                        obj.Currency,
                        obj.MainImageUrl,
                        obj.MainImageId,
                        obj.ImageUrls,
                        AdditionalImages = localizedAdditional,
                        obj.Amenities,
                        obj.PropertyType,
                        obj.DistanceKm,
                        obj.IsAvailable,
                        obj.AvailableUnitsCount,
                        obj.MaxCapacity,
                        obj.IsFeatured,
                        LastUpdated = localizedLastUpdated
                    });
                }
                return PaginatedResult<object>.Create(resultObjects, request.PageNumber, request.PageSize, total);
            }
            else
            {
                var allItems = (await _sections.GetUnitItemsAsync(request.SectionId, cancellationToken)).ToList();
                var total = allItems.Count;
                if (total == 0)
                    return PaginatedResult<object>.Empty(request.PageNumber, request.PageSize);

                var pagedItems = allItems
                    .OrderBy(i => i.DisplayOrder)
                    .Skip((request.PageNumber - 1) * request.PageSize)
                    .Take(request.PageSize)
                    .ToList();

                var resultItems = new List<object>();
                foreach (var u in pagedItems)
                {
                    // Priority 1: images stored in dedicated UnitInSectionImage table
                    var sectionImgs = (await _unitInSectionImages.GetByUnitInSectionIdAsync(u.Id, cancellationToken))
                        .OrderBy(i => i.DisplayOrder)
                        .ToList();

                    List<PropertyImageDto> additional;
                    if (sectionImgs.Count > 0)
                    {
                        additional = sectionImgs.Select(i => new PropertyImageDto
                        {
                            Id = i.Id,
                            PropertyId = null,
                            UnitId = null,
                            SectionId = null,
                            PropertyInSectionId = null,
                            UnitInSectionId = u.Id,
                            CityName = null,
                            Name = i.Name,
                            Url = i.Url,
                            SizeBytes = i.SizeBytes,
                            Type = i.Type,
                            Category = i.Category,
                            Caption = i.Caption,
                            AltText = i.AltText,
                            Tags = i.Tags,
                            Sizes = i.Sizes ?? string.Empty,
                            IsMain = i.IsMainImage,
                            DisplayOrder = i.DisplayOrder,
                            UploadedAt = i.UploadedAt,
                            Status = i.Status,
                            AssociationType = "Unit"
                        }).ToList();
                    }
                    else
                    {
                        // Fallback: unit images first, then property images if unit has none
                        var unitImgs = (await _images.GetImagesByUnitAsync(u.UnitId, cancellationToken))
                            .OrderBy(i => i.DisplayOrder)
                            .ToList();

                        if (unitImgs.Count == 0)
                        {
                            var propImgs = (await _images.GetImagesByPropertyAsync(u.PropertyId, cancellationToken))
                                .OrderBy(i => i.DisplayOrder)
                                .ToList();
                            additional = propImgs.Select(i => new PropertyImageDto
                            {
                                Id = i.Id,
                                PropertyId = i.PropertyId,
                                UnitId = i.UnitId,
                                SectionId = i.SectionId,
                                PropertyInSectionId = i.PropertyInSectionId,
                                UnitInSectionId = i.UnitInSectionId,
                                CityName = i.CityName,
                                Name = i.Name,
                                Url = i.Url,
                                SizeBytes = i.SizeBytes,
                                Type = i.Type,
                                Category = i.Category,
                                Caption = i.Caption,
                                AltText = i.AltText,
                                Tags = i.Tags,
                                Sizes = i.Sizes,
                                IsMain = i.IsMainImage,
                                DisplayOrder = i.DisplayOrder,
                                UploadedAt = i.UploadedAt,
                                Status = i.Status,
                                AssociationType = i.UnitId.HasValue ? "Unit" : "Property"
                            }).ToList();
                        }
                        else
                        {
                            additional = unitImgs.Select(i => new PropertyImageDto
                            {
                                Id = i.Id,
                                PropertyId = i.PropertyId,
                                UnitId = i.UnitId,
                                SectionId = i.SectionId,
                                PropertyInSectionId = i.PropertyInSectionId,
                                UnitInSectionId = i.UnitInSectionId,
                                CityName = i.CityName,
                                Name = i.Name,
                                Url = i.Url,
                                SizeBytes = i.SizeBytes,
                                Type = i.Type,
                                Category = i.Category,
                                Caption = i.Caption,
                                AltText = i.AltText,
                                Tags = i.Tags,
                                Sizes = i.Sizes,
                                IsMain = i.IsMainImage,
                                DisplayOrder = i.DisplayOrder,
                                UploadedAt = i.UploadedAt,
                                Status = i.Status,
                                AssociationType = i.UnitId.HasValue ? "Unit" : "Property"
                            }).ToList();
                        }
                    }

                    var hasUnitSectionImages = sectionImgs.Count > 0;
                    var mainImage = hasUnitSectionImages
                        ? (additional.FirstOrDefault(i => i.IsMain)?.Url ?? additional.FirstOrDefault()?.Url)
                        : (string.IsNullOrWhiteSpace(u.MainImage)
                            ? (additional.FirstOrDefault(i => i.IsMain)?.Url ?? additional.FirstOrDefault()?.Url)
                            : u.MainImage);
                    var mainImageId = additional.FirstOrDefault(i => i.IsMain)?.Id;

                    var obj = new
                    {
                        Id = u.UnitId,
                        UnitInSectionId = u.Id,
                        Name = u.UnitName,
                        PropertyId = u.PropertyId,
                        UnitTypeId = u.UnitTypeId,
                        IsAvailable = u.IsAvailable,
                        MaxCapacity = u.MaxCapacity,
                        MainImageUrl = mainImage,
                        MainImageId = mainImageId,
                        ImageUrls = additional.Select(a => a.Url).ToList(),
                        AdditionalImages = additional,
                        Badge = u.Badge,
                        BadgeColor = u.BadgeColor,
                        DiscountPercentage = u.DiscountPercentage,
                        DiscountedPrice = u.DiscountedPrice
                    };
                    // Localize image UploadedAt
                    var localizedAdditional = new List<PropertyImageDto>();
                    foreach (var a in additional)
                    {
                        a.UploadedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(a.UploadedAt);
                        localizedAdditional.Add(a);
                    }
                    resultItems.Add(new
                    {
                        obj.Id,
                        obj.UnitInSectionId,
                        obj.Name,
                        obj.PropertyId,
                        obj.UnitTypeId,
                        obj.IsAvailable,
                        obj.MaxCapacity,
                        obj.MainImageUrl,
                        obj.MainImageId,
                        obj.ImageUrls,
                        AdditionalImages = localizedAdditional,
                        obj.Badge,
                        obj.BadgeColor,
                        obj.DiscountPercentage,
                        obj.DiscountedPrice
                    });
                }

                return PaginatedResult<object>.Create(resultItems, request.PageNumber, request.PageSize, total);
            }
		}
	}
}