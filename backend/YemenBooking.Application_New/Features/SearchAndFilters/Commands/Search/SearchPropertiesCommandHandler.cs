using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using PropertySearchResultDto = YemenBooking.Application.Features.SearchAndFilters.DTOs.PropertySearchResultDto;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Specifications;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using Newtonsoft.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.AuditLog.Services;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Application.Features.Units.Services;

namespace YemenBooking.Application.Features.SearchAndFilters.Commands.Search;

/// <summary>
/// معالج أمر البحث في الكيانات
/// Search properties command handler and includes:
/// - التحقق من صحة البيانات المدخلة
/// - التحقق من معايير البحث
/// - تطبيق الفلاتر الديناميكية
/// - البحث الجغرافي (حسب الموقع)
/// - ترتيب وتصفح النتائج
/// - حساب الإحصائيات
/// - تسجيل عمليات البحث
/// 
/// Searches for properties with dynamic filtering and includes:
/// - Input data validation
/// - Search criteria validation
/// - Dynamic filters application
/// - Geographic search (location-based)
/// - Results sorting and pagination
/// - StatisticsDto calculation
/// - Search logging
/// </summary>
public class SearchPropertiesCommandHandler : IRequestHandler<SearchPropertiesCommand, ResultDto<SearchPropertiesResponse>>
{
    private readonly IPropertyRepository _propertyRepository;
    private readonly ISearchFilterRepository _searchFilterRepository;
    private readonly IUnitTypeFieldRepository _unitTypeFieldRepository;
    private readonly IAvailabilityService _availabilityService;
    private readonly ISearchService _searchService;
    private readonly ICurrentUserService _currentUserService;
    private readonly IAuditService _auditService;
    private readonly ILogger<SearchPropertiesCommandHandler> _logger;
    private readonly ISearchLogRepository _searchLogRepository;

    public SearchPropertiesCommandHandler(
        IPropertyRepository propertyRepository,
        ISearchFilterRepository searchFilterRepository,
        IUnitTypeFieldRepository unitTypeFieldRepository,
        IAvailabilityService availabilityService,
        ISearchService searchService,
        ICurrentUserService currentUserService,
        IAuditService auditService,
        ILogger<SearchPropertiesCommandHandler> logger,
        ISearchLogRepository searchLogRepository)
    {
        _propertyRepository = propertyRepository;
        _searchFilterRepository = searchFilterRepository;
        _unitTypeFieldRepository = unitTypeFieldRepository;
        _availabilityService = availabilityService;
        _searchService = searchService;
        _currentUserService = currentUserService;
        _auditService = auditService;
        _logger = logger;
        _searchLogRepository = searchLogRepository;
    }

    /// <summary>
    /// تنفيذ أمر البحث في الكيانات
    /// Execute search properties command
    /// </summary>
    public async Task<ResultDto<SearchPropertiesResponse>> Handle(SearchPropertiesCommand request, CancellationToken cancellationToken)
    {
        var stopwatch = Stopwatch.StartNew();
        
        try
        {
            _logger.LogInformation("بدء معالجة أمر البحث في الكيانات");

            // 1. التحقق من صحة البيانات المدخلة
            var inputValidation = ValidateInputData(request);
            if (!inputValidation.IsSuccess)
                return ResultDto<SearchPropertiesResponse>.Failure(inputValidation.Message ?? "خطأ في التحقق من البيانات", inputValidation.Code);

            // 2. تطبيع تواريخ الإدخال: حوّل من التوقيت المحلي للمستخدم إلى UTC
            if (request.CheckIn.HasValue)
                request.CheckIn = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckIn.Value);
            if (request.CheckOut.HasValue)
                request.CheckOut = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckOut.Value);

            // 3. بناء معايير البحث
            var searchParameters = await BuildSearchParametersAsync(request, cancellationToken);

            // 3. تنفيذ البحث الأساسي
            var specification = new PropertySearchSpecification(searchParameters);
            var (properties, totalCount) = await _propertyRepository.GetPagedWithSpecificationAsync(
                specification, cancellationToken);
                
            // 5. التحقق من التوفر (إذا تم تحديد تواريخ)
            if (request.CheckIn.HasValue && request.CheckOut.HasValue)
            {
                properties = await FilterByAvailabilityAsync(properties, request.CheckIn.Value,
                    request.CheckOut.Value, request.GuestCount ?? 1, cancellationToken);
                totalCount = properties.Count();
            }

            // 6. البحث الجغرافي
            if (request.Latitude.HasValue && request.Longitude.HasValue && request.RadiusKm.HasValue)
            {
                properties = await FilterByLocationAsync(properties, request.Latitude.Value, 
                    request.Longitude.Value, request.RadiusKm.Value, cancellationToken);
                totalCount = properties.Count();
            }

            // 7. ترتيب النتائج
            properties = ApplySorting(properties, request.SortBy, request.SortDirection);

            // 8. التصفح
            var paginatedProperties = properties
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToList();

            // 9. تحويل النتائج إلى DTO
            var propertyItems = await ConvertToPropertySearchItemsAsync(paginatedProperties, request, cancellationToken);

            // 10. حساب الإحصائيات
            var statistics = CalculateSearchStatistics(properties, request, stopwatch.ElapsedMilliseconds);

            // 11. إنشاء نتيجة البحث
            var result = new SearchPropertiesResponse
            {
                Properties = propertyItems,
                TotalCount = totalCount,
                CurrentPage = request.PageNumber,
                PageSize = request.PageSize,
                TotalPages = (int)Math.Ceiling((double)totalCount / request.PageSize),
                HasPreviousPage = request.PageNumber > 1,
                HasNextPage = request.PageNumber < Math.Ceiling((double)totalCount / request.PageSize),
                Statistics = statistics,
                AppliedFilters = new SearchFiltersDto(), // Will be populated if needed
                SearchTimeMs = stopwatch.ElapsedMilliseconds
            };

            // 12. تسجيل عملية البحث
            await LogSearchOperationAsync(request, totalCount, stopwatch.ElapsedMilliseconds);

            stopwatch.Stop();
            _logger.LogInformation("تم إنجاز البحث بنجاح. النتائج: {Count}, الوقت: {Duration}ms", 
                totalCount, stopwatch.ElapsedMilliseconds);

            // سجل عملية البحث
            await _searchLogRepository.AddAsync(new SearchLog
            {
                UserId = _currentUserService.UserId,
                SearchType = "Property",
                CriteriaJson = JsonConvert.SerializeObject(request),
                ResultCount = totalCount,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize
            }, cancellationToken);

            return ResultDto<SearchPropertiesResponse>.Ok(result, "تم البحث بنجاح");
        }
        catch (Exception ex)
        {
            stopwatch.Stop();
            _logger.LogError(ex, "خطأ أثناء البحث في الكيانات");
            return ResultDto<SearchPropertiesResponse>.Failure("حدث خطأ أثناء البحث في الكيانات");
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate input data
    /// </summary>
    private ResultDto<SearchPropertiesResponse> ValidateInputData(SearchPropertiesCommand request)
    {
        var errors = new List<string>();

        // التحقق من التواريخ
        if (request.CheckIn.HasValue && request.CheckOut.HasValue)
        {
            if (request.CheckIn.Value >= request.CheckOut.Value)
                errors.Add("تاريخ الخروج يجب أن يكون بعد تاريخ الدخول");

            if (request.CheckIn.Value < DateTime.Today)
                errors.Add("تاريخ الدخول لا يمكن أن يكون في الماضي");
        }

        // التحقق من عدد الضيوف
        if (request.GuestCount.HasValue && request.GuestCount.Value <= 0)
            errors.Add("عدد الضيوف يجب أن يكون أكبر من صفر");

        // التحقق من الصفحات
        if (request.PageNumber <= 0)
            errors.Add("رقم الصفحة يجب أن يكون أكبر من صفر");

        if (request.PageSize <= 0 || request.PageSize > 100)
            errors.Add("حجم الصفحة يجب أن يكون بين 1 و 100");

        // التحقق من النطاق السعري
        if (request.MinPrice.HasValue && request.MinPrice.Value < 0)
            errors.Add("الحد الأدنى للسعر لا يمكن أن يكون سالب");

        if (request.MaxPrice.HasValue && request.MaxPrice.Value < 0)
            errors.Add("الحد الأقصى للسعر لا يمكن أن يكون سالب");

        if (request.MinPrice.HasValue && request.MaxPrice.HasValue && request.MinPrice.Value > request.MaxPrice.Value)
            errors.Add("الحد الأدنى للسعر لا يمكن أن يكون أكبر من الحد الأقصى");

        // التحقق من الموقع الجغرافي
        if (request.Latitude.HasValue && (request.Latitude.Value < -90 || request.Latitude.Value > 90))
            errors.Add("خط العرض يجب أن يكون بين -90 و 90");

        if (request.Longitude.HasValue && (request.Longitude.Value < -180 || request.Longitude.Value > 180))
            errors.Add("خط الطول يجب أن يكون بين -180 و 180");

        if (request.RadiusKm.HasValue && request.RadiusKm.Value <= 0)
            errors.Add("نطاق البحث يجب أن يكون أكبر من صفر");

        if (errors.Any())
        {
            return ResultDto<SearchPropertiesResponse>.Failure(
                "بيانات غير صحيحة: " + string.Join(", ", errors), "INVALID_INPUT");
        }

        return ResultDto<SearchPropertiesResponse>.Ok(new SearchPropertiesResponse());
    }

    /// <summary>
    /// بناء معايير البحث
    /// Build search parameters
    /// </summary>
    private Task<PropertySearchParameters> BuildSearchParametersAsync(
        SearchPropertiesCommand request, CancellationToken cancellationToken)
    {
        return Task.FromResult(new PropertySearchParameters
        {
            SearchTerm = request.SearchTerm,
            PropertyTypeId = request.PropertyTypeId,
            MinPrice = request.MinPrice,
            MaxPrice = request.MaxPrice,
            AmenityIds = request.AmenityIds,
            StarRatings = request.StarRatings?.ToArray(),
            MinAverageRating = (double?)request.MinAverageRating,
            IsApproved = true, // نعرض فقط الكيانات المعتمدة
            PageNumber = request.PageNumber,
            PageSize = request.PageSize
        });
    }




    /// <summary>
    /// التحقق من وجود القيمة في النطاق
    /// Check if value is in range
    /// </summary>
    private bool IsInRange(string? value, object? filterValue, Dictionary<string, object>? options)
    {
        if (string.IsNullOrEmpty(value) || filterValue == null) return false;

        if (decimal.TryParse(value, out var numValue))
        {
            var min = options?.ContainsKey("min") == true ? Convert.ToDecimal(options["min"]) : decimal.MinValue;
            var max = options?.ContainsKey("max") == true ? Convert.ToDecimal(options["max"]) : decimal.MaxValue;
            return numValue >= min && numValue <= max;
        }

        return false;
    }

    /// <summary>
    /// التحقق من أن القيمة أكبر من المحدد
    /// Check if value is greater than specified
    /// </summary>
    private bool IsGreater(string? value, object? filterValue)
    {
        if (string.IsNullOrEmpty(value) || filterValue == null) return false;

        if (decimal.TryParse(value, out var numValue) && decimal.TryParse(filterValue.ToString(), out var filterNum))
        {
            return numValue > filterNum;
        }

        return false;
    }

    /// <summary>
    /// التحقق من أن القيمة أقل من المحدد
    /// Check if value is less than specified
    /// </summary>
    private bool IsLess(string? value, object? filterValue)
    {
        if (string.IsNullOrEmpty(value) || filterValue == null) return false;

        if (decimal.TryParse(value, out var numValue) && decimal.TryParse(filterValue.ToString(), out var filterNum))
        {
            return numValue < filterNum;
        }

        return false;
    }

    /// <summary>
    /// فلترة حسب التوفر
    /// Filter by availability
    /// </summary>
    private async Task<IEnumerable<Property>> FilterByAvailabilityAsync(
        IEnumerable<Property> properties, 
        DateTime checkIn, 
        DateTime checkOut, 
        int guestCount, 
        CancellationToken cancellationToken)
    {
        var availableProperties = new List<Property>();

        foreach (var property in properties)
        {
            var availableUnits = await _availabilityService.GetAvailableUnitsInPropertyAsync(
                property.Id, checkIn, checkOut, guestCount, cancellationToken);

            if (availableUnits.Any())
            {
                availableProperties.Add(property);
            }
        }

        return availableProperties;
    }

    /// <summary>
    /// فلترة حسب الموقع الجغرافي
    /// Filter by geographic location
    /// </summary>
    private async Task<IEnumerable<Property>> FilterByLocationAsync(
        IEnumerable<Property> properties, 
        double latitude, 
        double longitude, 
        double radiusKm, 
        CancellationToken cancellationToken)
    {
        // يمكن استخدام خدمة البحث الجغرافي هنا
        var nearbyProperties = await _searchService.SearchPropertiesAsync(
            "", null, null, null, null, null, null, null, 
            latitude, longitude, radiusKm, cancellationToken);

        var nearbyIds = nearbyProperties.Select(p => p.Id).ToHashSet();
        return properties.Where(p => nearbyIds.Contains(p.Id));
    }

    /// <summary>
    /// تطبيق الترتيب
    /// Apply sorting
    /// </summary>
    private IEnumerable<Property> ApplySorting(IEnumerable<Property> properties, string? sortBy, string sortDirection)
    {
        var isDescending = sortDirection?.ToLower() == "desc";

        return sortBy?.ToLower() switch
        {
            "name" => isDescending ? properties.OrderByDescending(p => p.Name) : properties.OrderBy(p => p.Name),
            "price" => isDescending ? properties.OrderByDescending(p => p.Units.Min(u => u.BasePrice.Amount)) : 
                                     properties.OrderBy(p => p.Units.Min(u => u.BasePrice.Amount)),
            "rating" => isDescending ? properties.OrderByDescending(p => p.Reviews.Any() ? 
                                      p.Reviews.Average(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0) : 0) :
                                      properties.OrderBy(p => p.Reviews.Any() ? 
                                      p.Reviews.Average(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0) : 0),
            "created" => isDescending ? properties.OrderByDescending(p => p.CreatedAt) : properties.OrderBy(p => p.CreatedAt),
            _ => properties.OrderBy(p => p.Name)
        };
    }

    /// <summary>
    /// تحويل الكيانات إلى عناصر البحث
    /// Convert properties to search items
    /// </summary>
    private async Task<List<PropertySearchResultDto>> ConvertToPropertySearchItemsAsync(
        List<Property> properties, 
        SearchPropertiesCommand request, 
        CancellationToken cancellationToken)
    {
        var items = new List<PropertySearchResultDto>();

        foreach (var property in properties)
        {
            var item = new PropertySearchResultDto
            {
                Id = property.Id,
                Name = property.Name,
                Description = property.Description,
                City = property.City,
                Address = property.Address,
                StarRating = property.StarRating,
                PropertyType = property.PropertyType?.Name ?? "",
                MinPrice = property.Units.Any() ? property.Units.Min(u => u.BasePrice.Amount) : 0,
                Currency = property.Units.FirstOrDefault()?.BasePrice.Currency ?? "YER",
                MaxCapacity = property.Units.Any() ? property.Units.Max(u => u.MaxCapacity) : 0,
                IsFeatured = false, // Property doesn't have IsFeatured, set default
                LastUpdated = property.UpdatedAt
            };

            // حساب متوسط التقييم
            if (property.Reviews.Any())
            {
                item.AverageRating = property.Reviews.Average(r => (r.Cleanliness + r.Service + r.Location + r.Value) / 4.0m);
                item.ReviewsCount = property.Reviews.Count;
            }

            // الصور
            if (property.Images.Any())
            {
                item.MainImageUrl = property.Images.FirstOrDefault(i => i.IsMain)?.Url ?? 
                                   property.Images.First().Url;
                item.ImageUrls = property.Images.Take(5).Select(i => i.Url).ToList();
            }

            // المرافق
            item.MainAmenities = property.Amenities.Where(a => a.IsAvailable)
                .Select(a => a.PropertyTypeAmenity.Amenity.Name).ToList();

            // التحقق من التوفر
            if (request.CheckIn.HasValue && request.CheckOut.HasValue)
            {
                var availableUnits = await _availabilityService.GetAvailableUnitsInPropertyAsync(
                    property.Id, request.CheckIn.Value, request.CheckOut.Value, 
                    request.GuestCount ?? 1, cancellationToken);
                item.IsAvailable = availableUnits.Any();
                item.AvailableUnitsCount = availableUnits.Count();
            }
            else
            {
                item.IsAvailable = property.Units.Any(u => u.IsAvailable);
                item.AvailableUnitsCount = property.Units.Count(u => u.IsAvailable);
            }

            // حساب المسافة
            if (request.Latitude.HasValue && request.Longitude.HasValue &&
                property.Latitude != 0 && property.Longitude != 0)
            {
                item.DistanceKm = CalculateDistance(request.Latitude.Value, request.Longitude.Value,
                    (double)property.Latitude, (double)property.Longitude);
            }


            items.Add(item);
        }

        return items;
    }

    /// <summary>
    /// حساب المسافة بين نقطتين جغرافيتين
    /// Calculate distance between two geographic points
    /// </summary>
    private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        var R = 6371; // Earth's radius in kilometers
        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);
        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);
        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        return R * c;
    }

    private double ToRadians(double degrees) => degrees * Math.PI / 180;

    /// <summary>
    /// حساب إحصائيات البحث
    /// Calculate search statistics
    /// </summary>
    private YemenBooking.Application.Features.SearchAndFilters.DTOs.SearchStatisticsDto CalculateSearchStatistics(
        IEnumerable<Property> properties, 
        SearchPropertiesCommand request, 
        long searchDurationMs)
    {
        var propertiesList = properties.ToList();
        
        return new YemenBooking.Application.Features.SearchAndFilters.DTOs.SearchStatisticsDto
        {
            PropertiesByType = propertiesList
                .GroupBy(p => p.PropertyType?.Name ?? "غير محدد")
                .ToDictionary(g => g.Key, g => g.Count()),
            AverageRating = propertiesList.Any() ? (double)propertiesList.Average(p => p.AverageRating) : 0
        };
    }

    /// <summary>
    /// تسجيل عملية البحث
    /// Log search operation
    /// </summary>
    private async Task LogSearchOperationAsync(SearchPropertiesCommand request, int resultCount, long durationMs)
    {
        try
        {
            var notes = $"بحث في الكيانات - النتائج: {resultCount}، المدة: {durationMs}ms - بواسطة {_currentUserService.Username} (ID={_currentUserService.UserId})";
            await _auditService.LogAuditAsync(
                entityType: "PropertySearch",
                entityId: _currentUserService.UserId,
                action: AuditAction.VIEW,
                oldValues: null,
                newValues: Newtonsoft.Json.JsonConvert.SerializeObject(new { ResultCount = resultCount, DurationMs = durationMs }),
                performedBy: _currentUserService.UserId,
                notes: notes,
                cancellationToken: default);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "فشل في تسجيل عملية البحث");
        }
    }
}
