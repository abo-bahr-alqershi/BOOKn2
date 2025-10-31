// using Microsoft.Extensions.Logging;
// using YemenBooking.Core.Entities;
// using YemenBooking.Core.Interfaces;
// using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
// using YemenBooking.Core.Interfaces.Repositories;
// using AdvancedIndexingSystem.Core.Interfaces;
// using AdvancedIndexingSystem.Core.Models;
// using AdvancedIndexingSystem.Core.Services;
// using AdvancedIndexingSystem.Core.Events;
// using Models = AdvancedIndexingSystem.Core.Models;

// namespace YemenBooking.Infrastructure.Services;

// /// <summary>
// /// خدمة الفهرسة للبيانات
// /// Data indexing service
// /// </summary>
// public class IndexingService : IIndexingService
// {
//     #region Events
    
//     /// <summary>
//     /// حدث فهرسة العقار
//     /// Property indexing event
//     /// </summary>
//     public event EventHandler<PropertyIndexingEventArgs>? PropertyIndexed;

//     /// <summary>
//     /// حدث فهرسة الوحدة
//     /// Unit indexing event
//     /// </summary>
//     public event EventHandler<UnitIndexingEventArgs>? UnitIndexed;

//     /// <summary>
//     /// حدث فهرسة التسعير
//     /// Pricing indexing event
//     /// </summary>
//     public event EventHandler<PricingIndexingEventArgs>? PricingIndexed;

//     /// <summary>
//     /// حدث فهرسة الإتاحة
//     /// Availability indexing event
//     /// </summary>
//     public event EventHandler<AvailabilityIndexingEventArgs>? AvailabilityIndexed;

//     #endregion
//     private readonly ILogger<IndexingService> _logger;
//     private readonly IYemenBookingIndexService _indexService;
//     private readonly IPropertyRepository _propertyRepository;
//     private readonly IUnitRepository _unitRepository;
//     private readonly IPropertyAmenityRepository _propertyAmenityRepository;
//     private readonly IUnitFieldValueRepository _unitFieldValueRepository;
//     private readonly IPricingRuleRepository _pricingRuleRepository;
//     private readonly IUnitAvailabilityRepository _availabilityRepository;

//     public IndexingService(
//         ILogger<IndexingService> logger,
//         IYemenBookingIndexService indexService,
//         IPropertyRepository propertyRepository,
//         IUnitRepository unitRepository,
//         IPropertyAmenityRepository propertyAmenityRepository,
//         IUnitFieldValueRepository unitFieldValueRepository,
//         IPricingRuleRepository pricingRuleRepository,
//         IUnitAvailabilityRepository availabilityRepository)
//     {
//         _logger = logger;
//         _indexService = indexService;
//         _propertyRepository = propertyRepository;
//         _unitRepository = unitRepository;
//         _propertyAmenityRepository = propertyAmenityRepository;
//         _unitFieldValueRepository = unitFieldValueRepository;
//         _pricingRuleRepository = pricingRuleRepository;
//         _availabilityRepository = availabilityRepository;
//     }

//     public async Task<bool> IndexPropertyAsync(Property property)
//     {
//         try
//         {
//             var propertyIndexItem = await ConvertToPropertyIndexItemAsync(property);
//             await _indexService.IndexPropertyAsync(propertyIndexItem);
//             await SaveIndexesAsync();
//             _logger.LogInformation("Property {PropertyId} indexed successfully", property.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to index property {PropertyId}", property.Id);
//             return false;
//         }
//     }

//     public async Task<bool> UpdatePropertyIndexAsync(Property property)
//     {
//         try
//         {
//             var propertyIndexItem = await ConvertToPropertyIndexItemAsync(property);
//             await _indexService.IndexPropertyAsync(propertyIndexItem, UpdateOperationType.Update);
            
//             _logger.LogInformation("Property {PropertyId} index updated successfully", property.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to update property index {PropertyId}", property.Id);
//             return false;
//         }
//     }

//     public async Task<bool> RemovePropertyIndexAsync(Guid propertyId)
//     {
//         try
//         {
//             // Find and remove the property from city index first
//             var property = await _propertyRepository.GetByIdAsync(propertyId);
//             if (property != null)
//             {
//                 await _indexService.RemovePropertyFromCityIndexAsync(property.City, propertyId.ToString());
//             }
            
//             _logger.LogInformation("Property {PropertyId} removed from index successfully", propertyId);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to remove property {PropertyId} from index", propertyId);
//             return false;
//         }
//     }

//     public async Task<bool> IndexUnitAsync(Unit unit)
//     {
//         try
//         {
//             var unitIndexItem = await ConvertToUnitIndexItemAsync(unit);
//             await _indexService.IndexUnitAsync(unitIndexItem);
            
//             _logger.LogInformation("Unit {UnitId} indexed successfully", unit.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to index unit {UnitId}", unit.Id);
//             return false;
//         }
//     }

//     public async Task<bool> UpdateUnitIndexAsync(Unit unit)
//     {
//         try
//         {
//             var unitIndexItem = await ConvertToUnitIndexItemAsync(unit);
//             await _indexService.IndexUnitAsync(unitIndexItem, UpdateOperationType.Update);
            
//             _logger.LogInformation("Unit {UnitId} index updated successfully", unit.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to update unit index {UnitId}", unit.Id);
//             return false;
//         }
//     }

//     public async Task<bool> RemoveUnitIndexAsync(Guid unitId)
//     {
//         try
//         {
//             // The interface doesn't have RemoveUnitAsync - we would need to remove from pricing/availability indexes
//             await _indexService.RemovePricingIndexAsync(unitId.ToString());
//             await _indexService.RemoveAvailabilityIndexAsync(unitId.ToString());
            
//             _logger.LogInformation("Unit {UnitId} removed from index successfully", unitId);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to remove unit {UnitId} from index", unitId);
//             return false;
//         }
//     }

//     public async Task<bool> IndexPricingRuleAsync(PricingRule pricingRule)
//     {
//         try
//         {
//             var pricingIndexItem = ConvertToPricingIndexItem(pricingRule);
//             await _indexService.IndexPricingAsync(pricingIndexItem);
            
//             _logger.LogInformation("Pricing rule {PricingRuleId} indexed successfully", pricingRule.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to index pricing rule {PricingRuleId}", pricingRule.Id);
//             return false;
//         }
//     }

//     public async Task<bool> UpdatePricingRuleIndexAsync(PricingRule pricingRule)
//     {
//         try
//         {
//             var pricingIndexItem = ConvertToPricingIndexItem(pricingRule);
//             await _indexService.IndexPricingAsync(pricingIndexItem);
            
//             _logger.LogInformation("Pricing rule {PricingRuleId} index updated successfully", pricingRule.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to update pricing rule index {PricingRuleId}", pricingRule.Id);
//             return false;
//         }
//     }

//     public async Task<bool> RemovePricingRuleIndexAsync(Guid pricingRuleId)
//     {
//         try
//         {
//             await _indexService.RemovePricingIndexAsync(pricingRuleId.ToString());
            
//             _logger.LogInformation("Pricing rule {PricingRuleId} removed from index successfully", pricingRuleId);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to remove pricing rule {PricingRuleId} from index", pricingRuleId);
//             return false;
//         }
//     }

//     private async Task<PropertyIndexItem> ConvertToPropertyIndexItemAsync(Property property)
//     {
//         // Get amenities for this property
//         var amenities = await _propertyAmenityRepository.GetAllAsync(CancellationToken.None);
//         var propertyAmenities = amenities.Where(pa => pa.PropertyId == property.Id);

//         // Compute min/max price from unit base prices
//         var units = property.Units?.ToList() ?? new List<Unit>();
//         var unitPrices = units.Select(u => (decimal?)u.BasePrice.Amount).Where(a => a.HasValue).Select(a => a!.Value).ToList();
//         var minPrice = unitPrices.Any() ? unitPrices.Min() : 0m;
//         var maxPrice = unitPrices.Any() ? unitPrices.Max() : 0m;

//         // Collect unit type ids and service ids for property-level filters
//         var unitTypeIds = units.Select(u => u.UnitTypeId.ToString()).Distinct().ToList();
//         var serviceIds = property.Services?.Select(s => s.Id.ToString()).Distinct().ToList() ?? new List<string>();

//         return new PropertyIndexItem
//         {
//             Id = property.Id.ToString(),
//             Name = property.Name,
//             Address = property.Address,
//             City = property.City,
//             PropertyType = property.PropertyType?.Name ?? "Unknown",
//             Latitude = property.Latitude,
//             Longitude = property.Longitude,
//             StarRating = property.StarRating,
//             Description = property.Description ?? string.Empty,
//             IsApproved = property.IsApproved,
//             CreatedAt = property.CreatedAt,
//             ViewCount = property.ViewCount,
//             BookingCount = property.BookingCount,
//             AverageRating = property.AverageRating,
//             MinPrice = minPrice,
//             MaxPrice = maxPrice,
//             AmenityIds = propertyAmenities.Select(a => a.PtaId.ToString()).ToList(),
//             UnitIds = units.Select(u => u.Id.ToString()).ToList(),
//             ImageUrls = property.Images?.Select(img => img.Url).ToList() ?? new List<string>(),
//             CustomFields = new Dictionary<string, object>(),
//             UnitTypeIds = unitTypeIds,
//             ServiceIds = serviceIds
//         };
//     }

//     private async Task<UnitIndexItem> ConvertToUnitIndexItemAsync(Unit unit)
//     {
//         // Get field values for this unit
//         var fieldValues = await _unitFieldValueRepository.GetAllAsync(CancellationToken.None);
//         var unitFieldValues = fieldValues.Where(fv => fv.UnitId == unit.Id);

//         // Get pricing rules for this unit
//         var pricingRules = await _pricingRuleRepository.GetAllAsync(CancellationToken.None);
//         var unitPricingRules = pricingRules.Where(pr => pr.UnitId == unit.Id);

//         // Get dynamic fields data
//         var dynamicFields = unitFieldValues.ToDictionary(
//             fv => fv.UnitTypeField?.FieldName ?? fv.UnitTypeFieldId.ToString(),
//             fv => (object)(fv.FieldValue ?? string.Empty)
//         );

//         // Get pricing data
//         var pricing = unitPricingRules.Select(pr => pr.PriceType.ToString()).ToList();

//         // Get availability for this unit
//         var availability = await _availabilityRepository.GetAllAsync(CancellationToken.None);
//         var unitAvailability = availability.Where(av => av.UnitId == unit.Id);

//         return new UnitIndexItem
//         {
//             Id = unit.Id.ToString(),
//             PropertyId = unit.PropertyId.ToString(),
//             Name = unit.Name,
//             UnitType = unit.UnitType?.Name ?? "Unknown",
//             BasePrice = unit.BasePrice.Amount,
//             Currency = "USD", // Default currency
//             MaxCapacity = unit.MaxCapacity,
//             IsAvailable = unit.IsAvailable,
//             ViewCount = unit.ViewCount,
//             BookingCount = unit.BookingCount,
//             DynamicFields = dynamicFields,
//             PricingRules = pricing.Select(p => (object)p).ToList(),
//             Availability = unitAvailability.Select(av => (object)av.StartDate.ToString("yyyy-MM-dd")).ToList(),
//             ImageUrls = unit.Images?.Select(img => img.Url).ToList() ?? new List<string>(),
//             CustomFeatures = unit.CustomFeatures ?? string.Empty,
//             CreatedAt = unit.CreatedAt,
//             LastUpdated = unit.UpdatedAt
//         };
//     }

//     private Models.PricingIndexItem ConvertToPricingIndexItem(PricingRule pricingRule)
//     {
//         return new Models.PricingIndexItem
//         {
//             Id = pricingRule.Id.ToString(),
//             UnitId = pricingRule.UnitId.ToString(),
//             PriceType = pricingRule.PriceType,
//             PriceAmount = pricingRule.PriceAmount,
//             Currency = pricingRule.Currency ?? "USD",
//             StartDate = pricingRule.StartDate,
//             EndDate = pricingRule.EndDate,
//             CreatedAt = pricingRule.CreatedAt,
//             LastUpdated = pricingRule.UpdatedAt
//         };
//     }

//     public async Task<bool> IndexAvailabilityAsync(UnitAvailability availability)
//     {
//         try
//         {
//             var availabilityIndexItem = ConvertToAvailabilityIndexItem(availability);
//             await _indexService.IndexAvailabilityAsync(availabilityIndexItem);
            
//             _logger.LogInformation("Availability {AvailabilityId} indexed successfully", availability.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to index availability {AvailabilityId}", availability.Id);
//             return false;
//         }
//     }

//     public async Task<bool> UpdateAvailabilityIndexAsync(UnitAvailability availability)
//     {
//         try
//         {
//             var availabilityIndexItem = ConvertToAvailabilityIndexItem(availability);
//             await _indexService.IndexAvailabilityAsync(availabilityIndexItem, UpdateOperationType.Update);
            
//             _logger.LogInformation("Availability {AvailabilityId} index updated successfully", availability.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to update availability index {AvailabilityId}", availability.Id);
//             return false;
//         }
//     }

//     public async Task<bool> RemoveAvailabilityIndexAsync(Guid availabilityId)
//     {
//         try
//         {
//             await _indexService.RemoveAvailabilityIndexAsync(availabilityId.ToString());
            
//             _logger.LogInformation("Availability {AvailabilityId} removed from index successfully", availabilityId);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to remove availability {AvailabilityId} from index", availabilityId);
//             return false;
//         }
//     }

//     private Models.AvailabilityIndexItem ConvertToAvailabilityIndexItem(UnitAvailability availability)
//     {
//         return new Models.AvailabilityIndexItem
//         {
//             Id = availability.Id.ToString(),
//             UnitId = availability.UnitId.ToString(),
//             StartDate = availability.StartDate,
//             EndDate = availability.EndDate,
//             Status = availability.Status,
//             Reason = availability.Reason,
//             CreatedAt = availability.CreatedAt,
//             LastUpdated = availability.UpdatedAt
//         };
//     }

//     // Placeholder implementations for other entity types
//     public async Task<bool> IndexPropertyAmenityAsync(PropertyAmenity propertyAmenity)
//     {
//         try
//         {
//             await _indexService.AssociatePropertyWithFacilityAsync(
//                 propertyAmenity.PropertyId.ToString(),
//                 propertyAmenity.PropertyTypeAmenity?.Amenity?.Name ?? "Unknown",
//                 new Dictionary<string, object>()
//             );
            
//             _logger.LogInformation("PropertyAmenity {PropertyAmenityId} indexed successfully", propertyAmenity.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to index PropertyAmenity {PropertyAmenityId}", propertyAmenity.Id);
//             return false;
//         }
//     }

//     public async Task<bool> RemovePropertyAmenityIndexAsync(Guid propertyId, Guid amenityId)
//     {
//         try
//         {
//             await _indexService.DissociatePropertyFromFacilityAsync(
//                 propertyId.ToString(),
//                 amenityId.ToString()
//             );
            
//             _logger.LogInformation("PropertyAmenity removed from index for Property {PropertyId} and Amenity {AmenityId}", propertyId, amenityId);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to remove PropertyAmenity from index for Property {PropertyId} and Amenity {AmenityId}", propertyId, amenityId);
//             return false;
//         }
//     }

//     public async Task<bool> IndexPropertyTypeAsync(PropertyType propertyType)
//     {
//         try
//         {
//             var propertyTypeIndexItem = new PropertyTypeIndexItem
//             {
//                 Id = propertyType.Id.ToString(),
//                 TypeName = propertyType.Name,
//                 Description = propertyType.Description,
//                 AssociatedFields = new List<string>(),
//                 DefaultAmenities = new List<string>(),
//                 SupportedUnitTypes = new List<string>()
//             };
            
//             await _indexService.IndexPropertyTypeAsync(propertyTypeIndexItem);
//             _logger.LogInformation("PropertyType {PropertyTypeId} indexed successfully", propertyType.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to index PropertyType {PropertyTypeId}", propertyType.Id);
//             return false;
//         }
//     }

//     public async Task<bool> UpdatePropertyTypeIndexAsync(PropertyType propertyType)
//     {
//         // Same as index for upsert behavior
//         return await IndexPropertyTypeAsync(propertyType);
//     }

//     public async Task<bool> IndexUnitTypeAsync(UnitType unitType)
//     {
//         try
//         {
//             var unitTypeIndexItem = new UnitTypeIndexItem
//             {
//                 Id = unitType.Id.ToString(),
//                 TypeName = unitType.Name,
//                 Description = unitType.Description,
//                 PropertyTypeId = unitType.PropertyTypeId.ToString(),
//                 MaxCapacity = 1,
//                 AssociatedFields = new List<string>()
//             };
            
//             await _indexService.IndexUnitTypeAsync(unitTypeIndexItem);
//             _logger.LogInformation("UnitType {UnitTypeId} indexed successfully", unitType.Id);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to index UnitType {UnitTypeId}", unitType.Id);
//             return false;
//         }
//     }

//     public async Task<bool> UpdateUnitTypeIndexAsync(UnitType unitType)
//     {
//         // Same as index for upsert behavior
//         return await IndexUnitTypeAsync(unitType);
//     }

//     public async Task<bool> UpdateCityIndexAsync(string cityName, Guid propertyId, bool isAdd = true)
//     {
//         try
//         {
//             if (isAdd)
//             {
//                 await _indexService.AddPropertyToCityIndexAsync(cityName, propertyId.ToString());
//             }
//             else
//             {
//                 await _indexService.RemovePropertyFromCityIndexAsync(cityName, propertyId.ToString());
//             }
            
//             _logger.LogInformation("City {CityName} updated for Property {PropertyId}, IsAdd: {IsAdd}", cityName, propertyId, isAdd);
//             return true;
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "Failed to update city index for {CityName} and Property {PropertyId}", cityName, propertyId);
//             return false;
//         }
//     }

//     public async Task<List<PropertyIndexItem>> SearchPropertiesAsync(PropertySearchRequest request)
//     {
//         var result = await _indexService.SearchPropertiesAsync(request);
//         return result.Items.ToList();
//     }

//     public async Task<List<UnitIndexItem>> SearchUnitsAsync(UnitSearchRequest request)
//     {
//         var result = await _indexService.SearchUnitsAsync(request);
//         return result.Items.ToList();
//     }

//     public async Task<bool> InitializeAsync()
//     {
//         return await _indexService.InitializeAsync();
//     }

//     public async Task<bool> SaveIndexesAsync()
//     {
//         return await _indexService.SaveIndexesAsync();
//     }

//     public async Task<bool> LoadIndexesAsync()
//     {
//         return await _indexService.LoadAllIndexesAsync("./indexes");
//     }
// }

// /// <summary>
// /// إعدادات خدمة الفهرسة
// /// Indexing service settings
// /// </summary>
// public class IndexingSettings
// {
//     public string IndexBasePath { get; set; } = "./indexes";
//     public int AutoSaveIntervalMinutes { get; set; } = 30;
//     public bool EnableAutoSave { get; set; } = true;
// }