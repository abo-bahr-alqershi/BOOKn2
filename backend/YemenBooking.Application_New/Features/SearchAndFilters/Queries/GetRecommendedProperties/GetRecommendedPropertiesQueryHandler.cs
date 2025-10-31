using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.SearchAndFilters;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.SearchAndFilters;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.SearchAndFilters.Queries.GetRecommendedProperties;

/// <summary>
/// معالج استعلام الحصول على العقارات الموصى بها للمستخدم
/// Handler for get recommended properties query
/// </summary>
public class GetRecommendedPropertiesQueryHandler : IRequestHandler<GetRecommendedPropertiesQuery, ResultDto<PaginatedResult<PropertySearchResultDto>>>
{
    private readonly IUserRepository _userRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IFavoriteRepository _favoriteRepository;
    private readonly IReviewRepository _reviewRepository;
    private readonly IPropertyImageRepository _propertyImageRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ILogger<GetRecommendedPropertiesQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام العقارات الموصى بها
    /// Constructor for get recommended properties query handler
    /// </summary>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="favoriteRepository">مستودع المفضلات</param>
    /// <param name="reviewRepository">مستودع المراجعات</param>
    /// <param name="propertyImageRepository">مستودع صور العقارات</param>
    /// <param name="unitRepository">مستودع الوحدات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetRecommendedPropertiesQueryHandler(
        IUserRepository userRepository,
        IPropertyRepository propertyRepository,
        IBookingRepository bookingRepository,
        IFavoriteRepository favoriteRepository,
        IReviewRepository reviewRepository,
        IPropertyImageRepository propertyImageRepository,
        IUnitRepository unitRepository,
        ILogger<GetRecommendedPropertiesQueryHandler> logger)
    {
        _userRepository = userRepository;
        _propertyRepository = propertyRepository;
        _bookingRepository = bookingRepository;
        _favoriteRepository = favoriteRepository;
        _reviewRepository = reviewRepository;
        _propertyImageRepository = propertyImageRepository;
        _unitRepository = unitRepository;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على العقارات الموصى بها للمستخدم
    /// Handle get recommended properties query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة العقارات الموصى بها</returns>
    public async Task<ResultDto<PaginatedResult<PropertySearchResultDto>>> Handle(GetRecommendedPropertiesQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام العقارات الموصى بها. معرف المستخدم: {UserId}, العدد: {Count}, المدينة: {City}", 
                request.UserId, request.Count, request.City);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // التحقق من وجود المستخدم
            var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
            if (user == null)
            {
                _logger.LogWarning("المستخدم غير موجود. معرف المستخدم: {UserId}", request.UserId);
                return ResultDto<PaginatedResult<PropertySearchResultDto>>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            // الحصول على جميع العقارات النشطة
            var activeProperties = await _propertyRepository.GetActivePropertiesAsync(cancellationToken);
            
            if (activeProperties == null || !activeProperties.Any())
            {
                _logger.LogInformation("لا توجد عقارات نشطة في النظام");
                return ResultDto<PaginatedResult<PropertySearchResultDto>>.Ok(
                    new PaginatedResult<PropertySearchResultDto>
                    {
                        Items = new List<PropertySearchResultDto>(),
                        TotalCount = 0,
                        PageNumber = 1,
                        PageSize = request.Count
                    }, 
                    "لا توجد عقارات متاحة للتوصية"
                );
            }

            // تطبيق فلتر المدينة إذا تم تحديدها
            if (!string.IsNullOrWhiteSpace(request.City))
            {
                activeProperties = activeProperties.Where(p => 
                    p.City != null && p.City.Equals(request.City, StringComparison.OrdinalIgnoreCase));
            }

            var propertiesList = activeProperties.ToList();

            // جلب تفضيلات المستخدم وسجل الحجوزات
            var userPreferences = await GetUserPreferences(request.UserId, cancellationToken);

            // حساب درجة التوصية لكل عقار
            var recommendedProperties = new List<(Core.Entities.Property property, double score)>();

            foreach (var property in propertiesList)
            {
                var score = await CalculateRecommendationScore(property, userPreferences, cancellationToken);
                recommendedProperties.Add((property, score));
            }

            // ترتيب العقارات حسب درجة التوصية
            var sortedProperties = recommendedProperties
                .OrderByDescending(p => p.score)
                .Take(request.Count)
                .Select(p => p.property)
                .ToList();

            // تحويل إلى DTOs
            var propertyDtos = new List<PropertySearchResultDto>();

            foreach (var property in sortedProperties)
            {
                var propertyDto = await ConvertToPropertySearchResultDto(property, cancellationToken);
                if (propertyDto != null)
                {
                    propertyDtos.Add(propertyDto);
                }
            }

            var result = new PaginatedResult<PropertySearchResultDto>
            {
                Items = propertyDtos,
                TotalCount = propertyDtos.Count,
                PageNumber = 1,
                PageSize = request.Count
            };

            _logger.LogInformation("تم العثور على {Count} عقار موصى به للمستخدم", propertyDtos.Count);

            return ResultDto<PaginatedResult<PropertySearchResultDto>>.Ok(
                result, 
                $"تم العثور على {propertyDtos.Count} عقار موصى به"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب العقارات الموصى بها للمستخدم: {UserId}", request.UserId);
            return ResultDto<PaginatedResult<PropertySearchResultDto>>.Failed(
                $"حدث خطأ أثناء جلب العقارات الموصى بها: {ex.Message}", 
                "GET_RECOMMENDED_PROPERTIES_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<PaginatedResult<PropertySearchResultDto>> ValidateRequest(GetRecommendedPropertiesQuery request)
    {
        if (request.UserId == Guid.Empty)
        {
            _logger.LogWarning("معرف المستخدم غير صحيح");
            return ResultDto<PaginatedResult<PropertySearchResultDto>>.Failed("معرف المستخدم مطلوب", "INVALID_USER_ID");
        }

        if (request.Count < 1 || request.Count > 50)
        {
            _logger.LogWarning("عدد العقارات المطلوبة غير صحيح: {Count}", request.Count);
            return ResultDto<PaginatedResult<PropertySearchResultDto>>.Failed(
                "عدد العقارات يجب أن يكون بين 1 و 50", 
                "INVALID_COUNT"
            );
        }

        return ResultDto<PaginatedResult<PropertySearchResultDto>>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// الحصول على تفضيلات المستخدم
    /// Get user preferences
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>تفضيلات المستخدم</returns>
    private async Task<UserPreferences> GetUserPreferences(Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var preferences = new UserPreferences();

            // جلب سجل الحجوزات
            var userBookings = await _bookingRepository.GetByUserIdAsync(userId, cancellationToken);
            if (userBookings != null && userBookings.Any())
            {
                var completedBookings = userBookings.Where(b => b.Status == BookingStatus.Completed).ToList();
                
                if (completedBookings.Any())
                {
                    // المدن المفضلة
                    preferences.PreferredCities = completedBookings
                        .Where(b => b.Unit?.Property?.City != null)
                        .GroupBy(b => b.Unit!.Property!.City!)
                        .OrderByDescending(g => g.Count())
                        .Take(3)
                        .Select(g => g.Key)
                        .ToList();

                    // أنواع العقارات المفضلة
                    preferences.PreferredPropertyTypes = completedBookings
                        .GroupBy(b => b.Unit?.Property?.TypeId)
                        .Where(g => g.Key.HasValue)
                        .OrderByDescending(g => g.Count())
                        .Take(3)
                        .Select(g => g.Key!.Value)
                        .ToList();

                    // متوسط المبلغ المنفق
                    preferences.AverageBudget = (decimal)completedBookings.Average(b => b.TotalPrice.Amount);
                }
            }

            // جلب المفضلات
            var userFavorites = await _favoriteRepository.GetByUserIdAsync(userId, cancellationToken);
            if (userFavorites != null && userFavorites.Any())
            {
                preferences.FavoritePropertyIds = userFavorites.Select(f => f.PropertyId).ToList();
            }

            return preferences;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب تفضيلات المستخدم: {UserId}", userId);
            return new UserPreferences();
        }
    }

    /// <summary>
    /// حساب درجة التوصية للعقار
    /// Calculate recommendation score for property
    /// </summary>
    /// <param name="property">العقار</param>
    /// <param name="userPreferences">تفضيلات المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>درجة التوصية</returns>
    private async Task<double> CalculateRecommendationScore(Core.Entities.Property property, UserPreferences userPreferences, CancellationToken cancellationToken)
    {
        try
        {
            double score = 0;

            // درجة أساسية للعقار (تقييم + شعبية)
            var reviews = await _reviewRepository.GetByPropertyIdAsync(property.Id, cancellationToken);
            if (reviews != null && reviews.Any())
            {
                var averageRating = reviews.Average(r => r.AverageRating);
                score += (double)averageRating * 20; // وزن التقييم
                score += Math.Min(reviews.Count(), 10) * 5; // وزن عدد المراجعات (حد أقصى 50 نقطة)
            }

            // إذا كان العقار في المفضلات
            if (userPreferences.FavoritePropertyIds.Contains(property.Id))
            {
                score += 100; // نقاط إضافية كبيرة للمفضلات
            }

            // إذا كان العقار في مدينة مفضلة
            if (property.City != null && userPreferences.PreferredCities.Contains(property.City))
            {
                var cityIndex = userPreferences.PreferredCities.IndexOf(property.City);
                score += (3 - cityIndex) * 30; // نقاط أكثر للمدن الأكثر تفضيلاً
            }

            // إذا كان نوع العقار مفضل
            if (userPreferences.PreferredPropertyTypes.Contains(property.TypeId))
            {
                var typeIndex = userPreferences.PreferredPropertyTypes.IndexOf(property.TypeId);
                score += (3 - typeIndex) * 25; // نقاط أكثر للأنواع الأكثر تفضيلاً
            }

            // مطابقة الميزانية
            var units = await _unitRepository.GetActiveByPropertyIdAsync(property.Id, cancellationToken);
            if (units != null && units.Any() && userPreferences.AverageBudget > 0)
            {
                var minPriceDecimal = (decimal)units.Min(u => u.BasePrice);
                var budgetDifference = Math.Abs((decimal)(minPriceDecimal - userPreferences.AverageBudget));
                var budgetScore = Math.Max(0, 50 - (budgetDifference / userPreferences.AverageBudget * 100));
                score += (double)budgetScore;
            }

            // نقاط إضافية للعقارات الجديدة أو المحدثة مؤخراً
            var daysSinceCreated = (DateTime.UtcNow - property.CreatedAt).Days;
            if (daysSinceCreated <= 30)
            {
                score += 20; // نقاط للعقارات الجديدة
            }

            // نقاط للعقارات عالية التقييم
            if (property.StarRating >= 4)
            {
                score += property.StarRating * 10;
            }

            return Math.Max(0, score);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حساب درجة التوصية للعقار: {PropertyId}", property.Id);
            return 0;
        }
    }

    /// <summary>
    /// تحويل العقار إلى DTO للبحث
    /// Convert property to search result DTO
    /// </summary>
    /// <param name="property">العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>DTO العقار للبحث</returns>
    private async Task<PropertySearchResultDto?> ConvertToPropertySearchResultDto(Core.Entities.Property property, CancellationToken cancellationToken)
    {
        try
        {
            // جلب الصور
            var images = await _propertyImageRepository.GetByPropertyIdAsync(property.Id, cancellationToken);
            var mainImageUrl = images?.FirstOrDefault(img => img.IsMain)?.Url ?? 
                              images?.FirstOrDefault()?.Url;

            // جلب المراجعات
            var reviews = await _reviewRepository.GetByPropertyIdAsync(property.Id, cancellationToken);
            var averageRating = reviews?.Any() == true ? reviews.Average(r => r.AverageRating) : 0;
            var reviewsCount = reviews?.Count() ?? 0;

            // جلب أقل سعر
            var units = await _unitRepository.GetActiveByPropertyIdAsync(property.Id, cancellationToken);
            var minPrice = units?.Any() == true ? units.Min(u => (decimal)u.BasePrice) : 0m;

            return new PropertySearchResultDto
            {
                Id = property.Id,
                Name = property.Name ?? string.Empty,
                Description = property.Description ?? string.Empty,
                Address = property.Address ?? string.Empty,
                City = property.City ?? string.Empty,
                StarRating = property.StarRating,
                AverageRating = Math.Round(averageRating, 1),
                ReviewsCount = reviewsCount,
                MinPrice = minPrice,
                Currency = "YER",
                MainImageUrl = mainImageUrl,
                IsRecommended = true, // جميع النتائج موصى بها
                DistanceKm = null // لا نحسب المسافة في التوصيات
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء تحويل العقار إلى DTO: {PropertyId}", property.Id);
            return null;
        }
    }

    /// <summary>
    /// فئة تفضيلات المستخدم
    /// User preferences class
    /// </summary>
    private class UserPreferences
    {
        public List<string> PreferredCities { get; set; } = new();
        public List<Guid> PreferredPropertyTypes { get; set; } = new();
        public List<Guid> FavoritePropertyIds { get; set; } = new();
        public decimal AverageBudget { get; set; } = 0;
    }
}
