using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.PropertyTypes.DTOs;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using System.Text.Json;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetPropertyTypesWithUnits
{
    /// <summary>
    /// معالج استعلام يعيد أنواع العقارات مع أنواع الوحدات التابعة لها في استعلام واحد
    /// Handler to get property types with their unit types in a single roundtrip
    /// </summary>
    public class GetPropertyTypesWithUnitsQueryHandler : IRequestHandler<GetPropertyTypesWithUnitsQuery, ResultDto<List<PropertyTypeWithUnitsDto>>>
    {
        private readonly IPropertyTypeRepository _propertyTypeRepository;
        private readonly IUnitTypeRepository _unitTypeRepository;
        private readonly IPropertyRepository _propertyRepository;
        private readonly ILogger<GetPropertyTypesWithUnitsQueryHandler> _logger;

        public GetPropertyTypesWithUnitsQueryHandler(
            IPropertyTypeRepository propertyTypeRepository,
            IUnitTypeRepository unitTypeRepository,
            IPropertyRepository propertyRepository,
            ILogger<GetPropertyTypesWithUnitsQueryHandler> logger)
        {
            _propertyTypeRepository = propertyTypeRepository;
            _unitTypeRepository = unitTypeRepository;
            _propertyRepository = propertyRepository;
            _logger = logger;
        }

        public async Task<ResultDto<List<PropertyTypeWithUnitsDto>>> Handle(GetPropertyTypesWithUnitsQuery request, CancellationToken cancellationToken)
        {
            try
            {
                _logger.LogInformation("Fetching property types with unit types in one query");

                var allPropertyTypes = await _propertyTypeRepository.GetAllPropertyTypesAsync(cancellationToken);
                var propertyTypes = allPropertyTypes?.Where(pt => pt.IsActive).ToList() ?? new();

                // Early return
                if (propertyTypes.Count == 0)
                {
                    return ResultDto<List<PropertyTypeWithUnitsDto>>.Ok(new List<PropertyTypeWithUnitsDto>(), "لا توجد أنواع عقارات متاحة حالياً");
                }

                // Preload counts for performance
                var allProperties = await _propertyRepository.GetAllAsync(cancellationToken) ?? new List<YemenBooking.Core.Entities.Property>();

                var result = new List<PropertyTypeWithUnitsDto>();
                foreach (var pt in propertyTypes)
                {
                    // Fetch unit types for this property type
                    var unitTypes = await _unitTypeRepository.GetByPropertyTypeIdAsync(pt.Id, cancellationToken) 
                                   ?? new List<YemenBooking.Core.Entities.UnitType>();

                    var unitTypeDtos = unitTypes.Select(unitType => new UnitTypeDto
                    {
                        Id = unitType.Id,
                        PropertyTypeId = unitType.PropertyTypeId,
                        Name = unitType.Name ?? string.Empty,
                        Description = unitType.Description ?? string.Empty,
                        MaxCapacity = unitType.MaxCapacity,
                        Icon = unitType.Icon ?? string.Empty,
                        SystemCommissionRate = unitType.SystemCommissionRate,
                        IsHasAdults = unitType.IsHasAdults,
                        IsHasChildren = unitType.IsHasChildren,
                        IsMultiDays = unitType.IsMultiDays,
                        IsRequiredToDetermineTheHour = unitType.IsRequiredToDetermineTheHour,
                        // keep groups/filters empty here for home usage to reduce payload
                        FieldGroups = new List<FieldGroupDto>(),
                        Filters = new List<SearchFilterDto>(),
                        Fields = unitType.UnitTypeFields?.Select(f => new UnitTypeFieldDto
                        {
                            FieldId = f.Id.ToString(),
                            UnitTypeId = unitType.Id.ToString(),
                            FieldTypeId = f.FieldTypeId,
                            FieldName = f.FieldName,
                            DisplayName = f.DisplayName,
                            Description = f.Description,
                            FieldOptions = new Dictionary<string, object>(),
                            ValidationRules = new Dictionary<string, object>(),
                            IsRequired = f.IsRequired,
                            IsSearchable = f.IsSearchable,
                            IsPublic = f.IsPublic,
                            SortOrder = f.SortOrder,
                            Category = f.Category,
                            GroupId = null,
                            IsForUnits = f.IsForUnits,
                            ShowInCards = f.ShowInCards,
                            IsPrimaryFilter = f.IsPrimaryFilter,
                            Priority = f.Priority
                        }).ToList() ?? new List<UnitTypeFieldDto>()
                    }).ToList();

                    List<string> defaultAmenitiesList = new List<string>();
                    if (!string.IsNullOrWhiteSpace(pt.DefaultAmenities))
                    {
                        try
                        {
                            defaultAmenitiesList = JsonSerializer.Deserialize<List<string>>(pt.DefaultAmenities) ?? new List<string>();
                        }
                        catch
                        {
                            defaultAmenitiesList = new List<string>();
                        }
                    }

                    var dto = new PropertyTypeWithUnitsDto
                    {
                        Id = pt.Id,
                        Name = pt.Name ?? string.Empty,
                        Description = pt.Description ?? string.Empty,
                        Icon = pt.Icon ?? string.Empty,
                        DefaultAmenities = defaultAmenitiesList,
                        PropertiesCount = allProperties.Count(p => p.TypeId == pt.Id),
                        UnitTypes = unitTypeDtos
                    };

                    result.Add(dto);
                }

                // Order property types by properties count then name
                result = result
                    .OrderByDescending(x => x.PropertiesCount)
                    .ThenBy(x => x.Name)
                    .ToList();

                return ResultDto<List<PropertyTypeWithUnitsDto>>.Ok(result, $"تم الحصول على {result.Count} نوع عقار مع أنواع الوحدات");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error while fetching property types with units");
                return ResultDto<List<PropertyTypeWithUnitsDto>>.Failed($"حدث خطأ أثناء الحصول على أنواع العقارات مع الوحدات: {ex.Message}", "GET_PROPERTY_TYPES_WITH_UNITS_ERROR");
            }
        }
    }
}
