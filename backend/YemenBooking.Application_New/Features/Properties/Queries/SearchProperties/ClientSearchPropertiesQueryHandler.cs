// using MediatR;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features;
// using Microsoft.Extensions.Logging;
// using YemenBooking.Application.Common.Models;
// using PropResultDto = YemenBooking.Application.DTOs.PropertySearch.PropertySearchResultDto;
// using YemenBooking.Application.Features.Properties;
// using YemenBooking.Core.Interfaces.Repositories;
// using YemenBooking.Core.Interfaces;

// namespace YemenBooking.Application.Features.PropertyDto.Queries.SearchProperties;

// /// <summary>
// /// معالج استعلام البحث عن الكيانات للعميل
// /// Handler for client search properties query
// /// </summary>
// public class ClientSearchPropertiesQueryHandler : IRequestHandler<SearchPropertiesQuery, ResultDto<PropertySearchResultDto>>
// {
//     private readonly IUnitOfWork _unitOfWork;
//     private readonly IAmenityRepository _amenityRepository;
//     private readonly ILogger<ClientSearchPropertiesQueryHandler> _logger;

//     public ClientSearchPropertiesQueryHandler(
//         IUnitOfWork unitOfWork,
//         IAmenityRepository amenityRepository,
//         ILogger<ClientSearchPropertiesQueryHandler> logger)
//     {
//         _unitOfWork = unitOfWork;
//         _amenityRepository = amenityRepository;
//         _logger = logger;
//     }

//     /// <summary>
//     /// معالجة استعلام البحث عن الكيانات
//     /// Handle search properties query
//     /// </summary>
//     /// <param name="request">الطلب</param>
//     /// <param name="cancellationToken">رمز الإلغاء</param>
//     /// <returns>نتيجة العملية</returns>
//     public async Task<ResultDto<PropertySearchResultDto>> Handle(SearchPropertiesQuery request, CancellationToken cancellationToken)
//     {
//         try
//         {
//             _logger.LogInformation("بدء البحث عن الكيانات - المدينة: {City}, البحث: {SearchTerm}", request.City, request.SearchTerm);

//             // التحقق من صحة المعاملات
//             var validationError = ValidateRequest(request);
//             if (validationError != null)
//             {
//                 return ResultDto<PropertySearchResultDto>.Failure(validationError);
//             }

//             // البحث في قاعدة البيانات
//             var searchResult = await SearchProperties(request, cancellationToken);

//             _logger.LogInformation("تم العثور على {Count} كيان من أصل {Total}", searchResult.PropertyDto.Count, searchResult.TotalCount);

//             return ResultDto<PropertySearchResultDto>.Ok(searchResult, "تم البحث بنجاح");
//         }
//         catch (Exception ex)
//         {
//             _logger.LogError(ex, "خطأ أثناء البحث عن الكيانات");
//             return ResultDto<PropertySearchResultDto>.Failure("حدث خطأ داخلي أثناء تنفيذ عملية البحث");
//         }
//     }

//     /// <summary>
//     /// التحقق من صحة طلب البحث
//     /// Validate search request
//     /// </summary>
//     private string? ValidateRequest(SearchPropertiesQuery request)
//     {
//         // Basic validation rules
//         if (request.PageNumber < 1)
//         {
//             return "رقم الصفحة يجب أن يكون 1 أو أكبر";
//         }

//         if (request.PageSize < 1 || request.PageSize > 100)
//         {
//             return "حجم الصفحة غير صالح";
//         }

//         if (request.CheckIn.HasValue && request.CheckOut.HasValue && request.CheckIn >= request.CheckOut)
//         {
//             return "تاريخ الدخول يجب أن يكون قبل تاريخ الخروج";
//         }

//         if (request.MinPrice.HasValue && request.MaxPrice.HasValue && request.MinPrice > request.MaxPrice)
//         {
//             return "الحد الأدنى للسعر أكبر من الحد الأقصى";
//         }

//         return null;
//     }

//     /// <summary>
//     /// البحث في قاعدة البيانات
//     /// Search in database
//     /// </summary>
//     private async Task<PropertySearchResultDto> SearchProperties(SearchPropertiesQuery request, CancellationToken cancellationToken)
//     {
//         var propertyRepo = _unitOfWork.Repository<Core.Entities.Property>();
//         var allProperties = await propertyRepo.GetAllAsync(cancellationToken);

//         // تطبيق مرشحات البحث
//         var filteredProperties = allProperties.AsEnumerable();

//         // البحث بالنص
//         if (!string.IsNullOrWhiteSpace(request.SearchTerm))
//         {
//             var searchTerm = request.SearchTerm.ToLower();
//             filteredProperties = filteredProperties.Where(p =>
//                 p.Name.ToLower().Contains(searchTerm) ||
//                 p.Description.ToLower().Contains(searchTerm) ||
//                 p.City.ToLower().Contains(searchTerm));
//         }

//         // البحث بالمدينة
//         if (!string.IsNullOrWhiteSpace(request.City))
//         {
//             filteredProperties = filteredProperties.Where(p =>
//                 p.City.ToLower().Contains(request.City.ToLower()));
//         }

//         // البحث بنوع الكيان
//         if (request.PropertyTypeId.HasValue)
//         {
//             filteredProperties = filteredProperties.Where(p =>
//                 p.TypeId == request.PropertyTypeId.Value);
//         }

//         // البحث بتصنيف النجوم
//         if (request.MinStarRating.HasValue)
//         {
//             filteredProperties = filteredProperties.Where(p =>
//                 p.StarRating >= request.MinStarRating.Value);
//         }

//         // حساب إجمالي النتائج قبل التصفية بالصفحات
//         var totalCount = filteredProperties.Count();

//         // تطبيق الترتيب
//         filteredProperties = ApplySorting(filteredProperties, request);

//         // تطبيق الصفحات
//         var paginatedProperties = filteredProperties
//             .Skip((request.PageNumber - 1) * request.PageSize)
//             .Take(request.PageSize)
//             .ToList();

//         // تحويل إلى DTOs
//         var propertyDtos = new List<PropResultDto>();
//         foreach (var property in paginatedProperties)
//         {
//             var dto = await MapToSearchResultDto(property, request, cancellationToken);
//             propertyDtos.Add(dto);
//         }

//         return new PropertySearchResultDto
//         {
//             PropertyDto = propertyDtos,
//             TotalCount = totalCount,
//             CurrentPage = request.PageNumber,
//             TotalPages = (int)Math.Ceiling((double)totalCount / request.PageSize)
//         };
//     }

//     /// <summary>
//     /// تطبيق الترتيب
//     /// Apply sorting
//     /// </summary>
//     private IEnumerable<Core.Entities.Property> ApplySorting(IEnumerable<Core.Entities.Property> properties, SearchPropertiesQuery request)
//     {
//         return request.SortBy?.ToLower() switch
//         {
//             // لاحقاً يمكن حساب أقل سعر للوحدات ضمن ترتيب منفصل بكفاءة
//             "price_asc" => properties.OrderBy(p => p.BasePricePerNight),
//             "price_desc" => properties.OrderByDescending(p => p.BasePricePerNight),
//             "rating" => properties.OrderByDescending(p => p.AverageRating),
//             "name" => properties.OrderBy(p => p.Name),
//             "newest" => properties.OrderByDescending(p => p.CreatedAt),
//             _ => properties.OrderByDescending(p => p.AverageRating) // افتراضي: الأعلى تقييماً
//         };
//     }

//     /// <summary>
//     /// تحويل الكيان إلى DTO
//     /// Map property to search result DTO
//     /// </summary>
//     private async Task<PropResultDto> MapToSearchResultDto(Core.Entities.Property property, SearchPropertiesQuery request, CancellationToken cancellationToken)
//     {
//         // جلب وحدات الكيان لحساب أقل سعر واستخراج العملة
//         var unitRepo = _unitOfWork.Repository<Core.Entities.Unit>();
//         var units = await unitRepo.GetAllAsync(cancellationToken);
//         var unitsForProperty = units.Where(u => u.PropertyId == property.Id).ToList();
//         var minPrice = unitsForProperty.Any() ? unitsForProperty.Min(u => u.BasePrice.Amount) : property.BasePricePerNight;
//         var currency = unitsForProperty.FirstOrDefault()?.BasePrice.Currency ?? (property.Currency ?? "YER");

//         var dto = new PropResultDto
//         {
//             Id = property.Id,
//             Name = property.Name,
//             PropertyType = await GetPropertyTypeName(property.TypeId, cancellationToken),
//             Address = property.Address,
//             City = property.City,
//             StarRating = property.StarRating,
//             AverageRating = property.AverageRating,
//             ReviewsCount = await GetReviewsCount(property.Id, cancellationToken),
//             MinPrice = minPrice,
//             Currency = currency,
//             MainImageUrl = GetMainImageUrl(property.Id),
//             MainAmenities = await GetMainAmenities(property.Id, cancellationToken)
//         };

//         // حساب المسافة إذا تم توفير إحداثيات
//         if (request.Latitude.HasValue && request.Longitude.HasValue && 
//             property.Latitude != 0 && property.Longitude != 0)
//         {
//             dto.DistanceKm = CalculateDistance(
//                 (double)request.Latitude.Value, (double)request.Longitude.Value,
//                 (double)property.Latitude, (double)property.Longitude);
//         }

//         return dto;
//     }

//     /// <summary>
//     /// الحصول على اسم نوع الكيان
//     /// Get property type name
//     /// </summary>
//     private async Task<string> GetPropertyTypeName(Guid propertyTypeId, CancellationToken cancellationToken)
//     {
//         try
//         {
//             var propertyTypeRepo = _unitOfWork.Repository<Core.Entities.PropertyType>();
//             var propertyType = await propertyTypeRepo.GetByIdAsync(propertyTypeId, cancellationToken);
//             return propertyType?.Name ?? "غير محدد";
//         }
//         catch
//         {
//             return "غير محدد";
//         }
//     }

//     /// <summary>
//     /// الحصول على عدد المراجعات
//     /// Get reviews count
//     /// </summary>
//     private async Task<int> GetReviewsCount(Guid propertyId, CancellationToken cancellationToken)
//     {
//         try
//         {
//             var reviewRepo = _unitOfWork.Repository<Core.Entities.Review>();
//             var reviews = await reviewRepo.GetAllAsync(cancellationToken);
//             return reviews.Count(r => r.PropertyId == propertyId);
//         }
//         catch
//         {
//             return 0;
//         }
//     }

//     /// <summary>
//     /// الحصول على رابط الصورة الرئيسية
//     /// Get main image URL
//     /// </summary>
//     private string GetMainImageUrl(Guid propertyId)
//     {
//         // صورة افتراضية - سيتم تحسينه لاحقاً
//         return "/images/property-placeholder.jpg";
//     }

//     /// <summary>
//     /// الحصول على وسائل الراحة الرئيسية
//     /// Get main amenities
//     /// </summary>
//     private async Task<List<string>> GetMainAmenities(Guid propertyId, CancellationToken cancellationToken)
//     {
//         try
//         {
//             var amenities = await _amenityRepository.GetAmenitiesByPropertyAsync(propertyId, cancellationToken);
//             return amenities
//                 .Where(pa => pa.IsAvailable && pa.PropertyTypeAmenity?.Amenity != null)
//                 .Select(pa => pa.PropertyTypeAmenity!.Amenity.Name)
//                 .Distinct()
//                 .Take(8)
//                 .ToList();
//         }
//         catch
//         {
//             return new List<string>();
//         }
//     }

//     /// <summary>
//     /// حساب المسافة بين نقطتين بالكيلومتر
//     /// Calculate distance between two points in kilometers
//     /// </summary>
//     private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
//     {
//         const double earthRadius = 6371; // نصف قطر الأرض بالكيلومتر

//         var lat1Rad = Math.PI * lat1 / 180;
//         var lat2Rad = Math.PI * lat2 / 180;
//         var deltaLat = Math.PI * (lat2 - lat1) / 180;
//         var deltaLon = Math.PI * (lon2 - lon1) / 180;

//         var a = Math.Sin(deltaLat / 2) * Math.Sin(deltaLat / 2) +
//                 Math.Cos(lat1Rad) * Math.Cos(lat2Rad) *
//                 Math.Sin(deltaLon / 2) * Math.Sin(deltaLon / 2);

//         var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

//         return earthRadius * c;
//     }
// }