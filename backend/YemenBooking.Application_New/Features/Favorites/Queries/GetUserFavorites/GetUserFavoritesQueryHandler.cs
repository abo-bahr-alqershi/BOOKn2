using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Favorites;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Core.Interfaces.Repositories;
using Microsoft.EntityFrameworkCore; // For EF Core extensions
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features.Analytics.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Favorites.Queries.GetUserFavorites;

/// <summary>
/// معالج استعلام الحصول على قائمة المفضلات للمستخدم
/// Handler for get user favorites query
/// </summary>
public class GetUserFavoritesQueryHandler : IRequestHandler<GetUserFavoritesQuery, ResultDto<UserFavoritesResponse>>
{
    private readonly IFavoriteRepository _favoriteRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IUserRepository _userRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ILogger<GetUserFavoritesQueryHandler> _logger;
    private readonly ICurrentUserService _currentUserService;
    private readonly IAmenityRepository? _amenityRepository; // Optional if exists
    private readonly IPropertyTypeRepository? _propertyTypeRepository; // Optional

    /// <summary>
    /// منشئ معالج استعلام المفضلات
    /// Constructor for get user favorites query handler
    /// </summary>
    /// <param name="favoriteRepository">مستودع المفضلات</param>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="unitRepository">مستودع الوحدات</param>
    /// <param name="logger">مسجل الأحداث</param>
    /// <param name="amenityRepository">مستودع المرافق (اختياري)</param>
    /// <param name="propertyTypeRepository">مستودع أنواع العقارات (اختياري)</param>
    public GetUserFavoritesQueryHandler(
        IFavoriteRepository favoriteRepository,
        IPropertyRepository propertyRepository,
        IUserRepository userRepository,
        IUnitRepository unitRepository,
        ILogger<GetUserFavoritesQueryHandler> logger,
        ICurrentUserService currentUserService,
        IAmenityRepository? amenityRepository = null,
        IPropertyTypeRepository? propertyTypeRepository = null)
    {
        _favoriteRepository = favoriteRepository;
        _propertyRepository = propertyRepository;
        _userRepository = userRepository;
        _unitRepository = unitRepository;
        _logger = logger;
        _currentUserService = currentUserService;
        _amenityRepository = amenityRepository;
        _propertyTypeRepository = propertyTypeRepository;
    }

    /// <summary>
    /// معالجة استعلام الحصول على قائمة المفضلات للمستخدم
    /// Handle get user favorites query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة المفضلات</returns>
    public async Task<ResultDto<UserFavoritesResponse>> Handle(GetUserFavoritesQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام مفضلات المستخدم. معرف المستخدم: {UserId}, الصفحة: {PageNumber}", 
                request.UserId, request.PageNumber);

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
                _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", request.UserId);
                return ResultDto<UserFavoritesResponse>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            // الحصول على المفضلات مع التصفح
            var (favorites, totalCount) = await _favoriteRepository.GetUserFavoritesAsync(
                request.UserId, 
                request.PageNumber, 
                request.PageSize, 
                cancellationToken);

            if (favorites == null || !favorites.Any())
            {
                _logger.LogInformation("لم يتم العثور على مفضلات للمستخدم: {UserId}", request.UserId);
                
                return ResultDto<UserFavoritesResponse>.Ok(
                    new UserFavoritesResponse
                    {
                        Favorites = new List<YemenBooking.Application.Features.Users.DTOs.FavoritePropertyDto>(),
                        TotalCount = 0
                    }, 
                    "لا توجد مفضلات متاحة"
                );
            }

            // تحويل البيانات إلى DTO
            var favoriteDtos = new List<YemenBooking.Application.Features.Users.DTOs.FavoritePropertyDto>();
            
            foreach (var favorite in favorites)
            {
                // الحصول على تفاصيل العقار
                var property = await _propertyRepository.GetPropertyByIdAsync(favorite.PropertyId, cancellationToken);
                if (property == null)
                {
                    _logger.LogWarning("لم يتم العثور على العقار: {PropertyId}", favorite.PropertyId);
                    continue; // تخطي هذا العقار إذا لم يعد موجوداً
                }

                // نوع العقار واسم المالك
                string ownerName = string.Empty;
                string typeName = string.Empty;
                if (property.OwnerId != Guid.Empty)
                {
                    var owner = await _userRepository.GetByIdAsync(property.OwnerId, cancellationToken);
                    ownerName = owner?.Name ?? string.Empty;
                }
                if (property.TypeId != Guid.Empty && _propertyTypeRepository != null)
                {
                    var pType = await _propertyTypeRepository.GetByIdAsync(property.TypeId, cancellationToken);
                    typeName = pType?.Name ?? string.Empty;
                }

                // الصور (اختيار الصورة الرئيسية + أخرى بشكل مبسط)
                var images = new List<FavoritePropertyImageDto>();
                if (property.Images != null && property.Images.Any())
                {
                    foreach (var img in property.Images)
                    {
                        images.Add(new FavoritePropertyImageDto
                        {
                            Id = img.Id,
                            PropertyId = img.PropertyId,
                            UnitId = img.UnitId,
                            Name = img.Name,
                            Url = img.Url,
                            SizeBytes = img.SizeBytes,
                            Type = img.Type,
                            Category = img.Category.ToString(),
                            Caption = img.Caption,
                            AltText = img.AltText,
                            Tags = img.Tags,
                            Sizes = img.Sizes,
                            IsMain = img.IsMain || img.IsMainImage,
                            DisplayOrder = img.DisplayOrder != 0 ? img.DisplayOrder : img.SortOrder,
                            UploadedAt = img.UploadedAt,
                            Status = img.Status.ToString(),
                            AssociationType = img.UnitId.HasValue ? "Unit" : "Property"
                        });
                    }
                }

                var mainImageUrl = images.FirstOrDefault(i => i.IsMain)?.Url ?? images.FirstOrDefault()?.Url ?? string.Empty;

                // المرافق: تسطيح property.Amenities -> المرافق الأساسية
                var amenityDtos = new List<FavoriteAmenityDto>();
                if (property.Amenities != null && property.Amenities.Any())
                {
                    foreach (var pa in property.Amenities)
                    {
                        var amenity = pa.PropertyTypeAmenity?.Amenity; // التنقل إذا تم تحميله
                        if (amenity != null)
                        {
                            amenityDtos.Add(new FavoriteAmenityDto
                            {
                                Id = amenity.Id,
                                Name = amenity.Name,
                                Description = amenity.Description,
                                IconUrl = string.Empty, // غير مخزن بعد
                                Category = string.Empty,
                                IsActive = pa.IsAvailable,
                                DisplayOrder = 0,
                                CreatedAt = amenity.CreatedAt
                            });
                        }
                    }
                }

                // التقييمات والمراجعات
                var reviewsCount = property.Reviews?.Count ?? 0;
                var averageRating = property.AverageRating;

                // أقل سعر من الوحدات
                decimal minPrice = 0;
                var units = await _unitRepository.GetActiveByPropertyIdAsync(property.Id, cancellationToken);
                if (units != null && units.Any())
                {
                    minPrice = units.Select(u => u.BasePrice.Amount).DefaultIfEmpty(0).Min();
                }

                favoriteDtos.Add(new YemenBooking.Application.Features.Users.DTOs.FavoritePropertyDto
                {
                    FavoriteId = favorite.Id,
                    UserId = favorite.UserId,
                    PropertyId = property.Id,
                    PropertyName = property.Name ?? string.Empty,
                    PropertyImage = mainImageUrl,
                    PropertyLocation = property.City ?? property.Address ?? string.Empty,
                    TypeId = property.TypeId,
                    TypeName = typeName,
                    OwnerName = ownerName,
                    Address = property.Address ?? string.Empty,
                    City = property.City ?? string.Empty,
                    Latitude = property.Latitude,
                    Longitude = property.Longitude,
                    StarRating = property.StarRating,
                    AverageRating = averageRating,
                    ReviewsCount = reviewsCount,
                    MinPrice = minPrice,
                    Currency = property.Currency ?? "YER",
                    Images = images,
                    Amenities = amenityDtos,
                    CreatedAt = favorite.DateAdded
                });
            }

            // ترتيب المفضلات حسب تاريخ الإضافة (الأحدث أولاً)
            favoriteDtos = favoriteDtos.OrderByDescending(f => f.CreatedAt).ToList();

            // Localize all datetime fields for client
            for (int i = 0; i < favoriteDtos.Count; i++)
            {
                favoriteDtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(favoriteDtos[i].CreatedAt);
                if (favoriteDtos[i].Images != null)
                {
                    for (int j = 0; j < favoriteDtos[i].Images.Count; j++)
                    {
                        favoriteDtos[i].Images[j].UploadedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(favoriteDtos[i].Images[j].UploadedAt);
                    }
                }
                if (favoriteDtos[i].Amenities != null)
                {
                    for (int k = 0; k < favoriteDtos[i].Amenities.Count; k++)
                    {
                        favoriteDtos[i].Amenities[k].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(favoriteDtos[i].Amenities[k].CreatedAt);
                    }
                }
            }

            var response = new UserFavoritesResponse
            {
                Favorites = favoriteDtos,
                TotalCount = totalCount
            };

            _logger.LogInformation("تم الحصول على {Count} مفضلة للمستخدم {UserId} بنجاح", favoriteDtos.Count, request.UserId);

            return ResultDto<UserFavoritesResponse>.Ok(
                response, 
                $"تم الحصول على {favoriteDtos.Count} مفضلة من أصل {totalCount}"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على مفضلات المستخدم. معرف المستخدم: {UserId}", request.UserId);
            return ResultDto<UserFavoritesResponse>.Failed(
                $"حدث خطأ أثناء الحصول على المفضلات: {ex.Message}", 
                "GET_USER_FAVORITES_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<UserFavoritesResponse> ValidateRequest(GetUserFavoritesQuery request)
    {
        if (request.UserId == Guid.Empty)
        {
            _logger.LogWarning("معرف المستخدم مطلوب");
            return ResultDto<UserFavoritesResponse>.Failed("معرف المستخدم مطلوب", "USER_ID_REQUIRED");
        }

        if (request.PageNumber < 1)
        {
            _logger.LogWarning("رقم الصفحة يجب أن يكون أكبر من صفر");
            return ResultDto<UserFavoritesResponse>.Failed("رقم الصفحة يجب أن يكون أكبر من صفر", "INVALID_PAGE_NUMBER");
        }

        if (request.PageSize < 1 || request.PageSize > 100)
        {
            _logger.LogWarning("حجم الصفحة يجب أن يكون بين 1 و 100");
            return ResultDto<UserFavoritesResponse>.Failed("حجم الصفحة يجب أن يكون بين 1 و 100", "INVALID_PAGE_SIZE");
        }

        return ResultDto<UserFavoritesResponse>.Ok(null, "البيانات صحيحة");
    }
}
