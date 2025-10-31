using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetNearbyProperties;

/// <summary>
/// معالج استعلام الحصول على العقارات القريبة
/// Handler for get nearby properties query
/// </summary>
public class GetNearbyPropertiesQueryHandler : IRequestHandler<GetNearbyPropertiesQuery, ResultDto<List<NearbyPropertyDto>>>
{
    private readonly IPropertyRepository _propertyRepository;
    private readonly IReviewRepository _reviewRepository;
    private readonly IPropertyImageRepository _propertyImageRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ILogger<GetNearbyPropertiesQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام العقارات القريبة
    /// Constructor for get nearby properties query handler
    /// </summary>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="reviewRepository">مستودع المراجعات</param>
    /// <param name="propertyImageRepository">مستودع صور العقارات</param>
    /// <param name="unitRepository">مستودع الوحدات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetNearbyPropertiesQueryHandler(
        IPropertyRepository propertyRepository,
        IReviewRepository reviewRepository,
        IPropertyImageRepository propertyImageRepository,
        IUnitRepository unitRepository,
        ILogger<GetNearbyPropertiesQueryHandler> logger)
    {
        _propertyRepository = propertyRepository;
        _reviewRepository = reviewRepository;
        _propertyImageRepository = propertyImageRepository;
        _unitRepository = unitRepository;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على العقارات القريبة
    /// Handle get nearby properties query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة العقارات القريبة</returns>
    public async Task<ResultDto<List<NearbyPropertyDto>>> Handle(GetNearbyPropertiesQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام العقارات القريبة. الموقع: ({Latitude}, {Longitude}), نصف القطر: {RadiusKm} كم, العدد الأقصى: {MaxResults}", 
                request.Latitude, request.Longitude, request.RadiusKm, request.MaxResults);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // الحصول على جميع العقارات النشطة
            var allProperties = await _propertyRepository.GetActivePropertiesAsync(cancellationToken);
            
            if (allProperties == null || !allProperties.Any())
            {
                _logger.LogInformation("لا توجد عقارات نشطة في النظام");
                
                return ResultDto<List<NearbyPropertyDto>>.Ok(
                    new List<NearbyPropertyDto>(), 
                    "لا توجد عقارات متاحة في المنطقة المحددة"
                );
            }

            // فلترة العقارات حسب نوع العقار إذا تم تحديده
            if (request.PropertyTypeId.HasValue)
            {
                allProperties = allProperties.Where(p => p.TypeId == request.PropertyTypeId.Value);
            }

            // حساب المسافة وفلترة العقارات ضمن نصف القطر المحدد
            var nearbyProperties = new List<(Core.Entities.Property Property, double Distance)>();

            foreach (var property in allProperties)
            {
                // التحقق من وجود إحداثيات للعقار
                if (property.Latitude == 0 || property.Longitude == 0)
                {
                    continue;
                }

                // حساب المسافة
                var distance = CalculateDistance(
                    (double)request.Latitude, (double)request.Longitude,
                    (double)property.Latitude, (double)property.Longitude);

                // إضافة العقار إذا كان ضمن نصف القطر المحدد
                if (distance <= request.RadiusKm)
                {
                    nearbyProperties.Add((Property: property, Distance: distance));
                }
            }

            if (!nearbyProperties.Any())
            {
                _logger.LogInformation("لا توجد عقارات ضمن نصف القطر المحدد: {RadiusKm} كم", request.RadiusKm);
                
                return ResultDto<List<NearbyPropertyDto>>.Ok(
                    new List<NearbyPropertyDto>(), 
                    $"لا توجد عقارات ضمن نصف قطر {request.RadiusKm} كم من الموقع المحدد"
                );
            }

            // ترتيب العقارات حسب المسافة
            var sortedProperties = nearbyProperties
                .OrderBy(p => p.Distance)
                .Take(request.MaxResults)
                .ToList();

            // تحويل إلى DTOs مع جلب البيانات المرتبطة
            var nearbyPropertyDtos = new List<NearbyPropertyDto>();

            foreach (var (property, distance) in sortedProperties)
            {
                // جلب متوسط التقييم
                var reviews = await _reviewRepository.GetByPropertyIdAsync(property.Id, cancellationToken);
                var averageRating = reviews?.Any() == true ? reviews.Average(r => r.AverageRating) : 0;

                // جلب الصورة الرئيسية
                var propertyImages = await _propertyImageRepository.GetByPropertyIdAsync(property.Id, cancellationToken);
                var mainImageUrl = propertyImages?.FirstOrDefault(img => img.IsMain)?.Url ?? 
                                  propertyImages?.FirstOrDefault()?.Url;

                // جلب أقل سعر متاح
                var minPrice = await GetMinAvailablePrice(property.Id, cancellationToken);

                var nearbyPropertyDto = new NearbyPropertyDto
                {
                    Id = property.Id,
                    Name = property.Name ?? string.Empty,
                    Address = property.Address ?? string.Empty,
                    DistanceKm = Math.Round(distance, 2),
                    AverageRating = Math.Round(averageRating, 1),
                    MinPrice = minPrice,
                    MainImageUrl = mainImageUrl
                };

                nearbyPropertyDtos.Add(nearbyPropertyDto);
            }

            _logger.LogInformation("تم العثور على {Count} عقار قريب من الموقع المحدد", nearbyPropertyDtos.Count);

            return ResultDto<List<NearbyPropertyDto>>.Ok(
                nearbyPropertyDtos, 
                $"تم العثور على {nearbyPropertyDtos.Count} عقار ضمن نصف قطر {request.RadiusKm} كم"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء البحث عن العقارات القريبة");
            return ResultDto<List<NearbyPropertyDto>>.Failed(
                $"حدث خطأ أثناء البحث عن العقارات القريبة: {ex.Message}", 
                "GET_NEARBY_PROPERTIES_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<List<NearbyPropertyDto>> ValidateRequest(GetNearbyPropertiesQuery request)
    {
        // التحقق من صحة إحداثيات الموقع
        if (Math.Abs(request.Latitude) > 90)
        {
            _logger.LogWarning("خط العرض غير صحيح: {Latitude}", request.Latitude);
            return ResultDto<List<NearbyPropertyDto>>.Failed("خط العرض يجب أن يكون بين -90 و 90", "INVALID_LATITUDE");
        }

        if (Math.Abs(request.Longitude) > 180)
        {
            _logger.LogWarning("خط الطول غير صحيح: {Longitude}", request.Longitude);
            return ResultDto<List<NearbyPropertyDto>>.Failed("خط الطول يجب أن يكون بين -180 و 180", "INVALID_LONGITUDE");
        }

        // التحقق من نصف القطر
        if (request.RadiusKm <= 0 || request.RadiusKm > 1000)
        {
            _logger.LogWarning("نصف القطر غير صحيح: {RadiusKm}", request.RadiusKm);
            return ResultDto<List<NearbyPropertyDto>>.Failed("نصف القطر يجب أن يكون بين 0.1 و 1000 كم", "INVALID_RADIUS");
        }

        // التحقق من العدد الأقصى للنتائج
        if (request.MaxResults < 1 || request.MaxResults > 100)
        {
            _logger.LogWarning("العدد الأقصى للنتائج غير صحيح: {MaxResults}", request.MaxResults);
            return ResultDto<List<NearbyPropertyDto>>.Failed("العدد الأقصى للنتائج يجب أن يكون بين 1 و 100", "INVALID_MAX_RESULTS");
        }

        return ResultDto<List<NearbyPropertyDto>>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// حساب المسافة بين نقطتين باستخدام صيغة هافرسين
    /// Calculate distance between two points using Haversine formula
    /// </summary>
    /// <param name="lat1">خط العرض الأول</param>
    /// <param name="lon1">خط الطول الأول</param>
    /// <param name="lat2">خط العرض الثاني</param>
    /// <param name="lon2">خط الطول الثاني</param>
    /// <returns>المسافة بالكيلومتر</returns>
    private double CalculateDistance(double lat1, double lon1, double lat2, double lon2)
    {
        const double R = 6371; // نصف قطر الأرض بالكيلومتر

        var dLat = ToRadians(lat2 - lat1);
        var dLon = ToRadians(lon2 - lon1);

        var a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                Math.Cos(ToRadians(lat1)) * Math.Cos(ToRadians(lat2)) *
                Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        var c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));
        var distance = R * c;

        return distance;
    }

    /// <summary>
    /// تحويل الدرجات إلى راديان
    /// Convert degrees to radians
    /// </summary>
    /// <param name="degrees">الدرجات</param>
    /// <returns>الراديان</returns>
    private double ToRadians(double degrees)
    {
        return degrees * (Math.PI / 180);
    }

    /// <summary>
    /// الحصول على أقل سعر متاح للعقار
    /// Get minimum available price for property
    /// </summary>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>أقل سعر متاح</returns>
    private async Task<decimal?> GetMinAvailablePrice(Guid propertyId, CancellationToken cancellationToken)
    {
        try
        {
            // الحصول على جميع الوحدات النشطة في العقار
            var units = await _unitRepository.GetActiveByPropertyIdAsync(propertyId, cancellationToken);
            
            if (units == null || !units.Any())
            {
                return null;
            }

            // العثور على أقل سعر أساسي
            var minBasePrice = units.Min(u => (decimal)u.BasePrice);

            // تطبيق أي خصومات متاحة
            var unitsWithDiscounts = units.Where(u => u.DiscountPercentage > 0).ToList();
            if (unitsWithDiscounts.Any())
            {
                var minDiscountedPrice = unitsWithDiscounts.Min(u => 
                    (decimal)u.BasePrice - ((decimal)u.BasePrice * u.DiscountPercentage / 100));
                
                return Math.Min(minBasePrice, minDiscountedPrice);
            }

            return minBasePrice;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حساب أقل سعر متاح للعقار: {PropertyId}", propertyId);
            return null;
        }
    }
}
