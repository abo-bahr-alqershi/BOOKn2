using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Services.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetPropertyDetails;

/// <summary>
/// معالج استعلام الحصول على تفاصيل الكيان للعميل
/// Handler for client get property details query
/// </summary>
public class ClientGetPropertyDetailsQueryHandler : IRequestHandler<GetPropertyDetailsQuery, ResultDto<PropertyDetailsDto>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<ClientGetPropertyDetailsQueryHandler> _logger;

    public ClientGetPropertyDetailsQueryHandler(
        IUnitOfWork unitOfWork,
        ILogger<ClientGetPropertyDetailsQueryHandler> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على تفاصيل الكيان
    /// Handle get property details query
    /// </summary>
    /// <param name="request">الطلب</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة العملية</returns>
    public async Task<ResultDto<PropertyDetailsDto>> Handle(GetPropertyDetailsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("جلب تفاصيل الكيان {PropertyId} للمستخدم {UserId}", request.PropertyId, request.UserId);

            // التحقق من صحة المعاملات
            if (request.PropertyId == Guid.Empty)
            {
                return ResultDto<PropertyDetailsDto>.Failure("معرف الكيان غير صحيح");
            }

            // البحث عن الكيان
            var propertyRepo = _unitOfWork.Repository<Core.Entities.Property>();
            var property = await propertyRepo.GetByIdAsync(request.PropertyId);

            if (property == null)
            {
                _logger.LogWarning("الكيان غير موجود {PropertyId}", request.PropertyId);
                return ResultDto<PropertyDetailsDto>.Failure("الكيان غير موجود");
            }

            // تحويل إلى DTO
            var propertyDetails = await MapToPropertyDetailsDto(property, request.UserId);

            _logger.LogInformation("تم جلب تفاصيل الكيان {PropertyId} بنجاح", request.PropertyId);

            return ResultDto<PropertyDetailsDto>.SuccessResult(propertyDetails);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب تفاصيل الكيان {PropertyId}", request.PropertyId);
            return ResultDto<PropertyDetailsDto>.Failure("حدث خطأ أثناء جلب التفاصيل");
        }
    }

    /// <summary>
    /// تحويل الكيان إلى DTO
    /// Map property to details DTO
    /// </summary>
    private async Task<PropertyDetailsDto> MapToPropertyDetailsDto(Core.Entities.Property property, Guid? userId)
    {
        var dto = new PropertyDetailsDto
        {
            Id = property.Id,
            Name = property.Name,
            PropertyType = await GetPropertyTypeDto(property.TypeId),
            Address = property.Address,
            City = property.City,
            Latitude = property.Latitude,
            Longitude = property.Longitude,
            StarRating = property.StarRating,
            Description = property.Description,
            AverageRating = property.AverageRating,
            ReviewsCount = await GetReviewsCount(property.Id),
            ViewCount = await GetViewCount(property.Id),
            BookingCount = await GetBookingCount(property.Id),
            IsFavorite = await IsInFavorites(property.Id, userId),
            Images = await GetPropertyImages(property.Id),
            Amenities = await GetPropertyAmenities(property.Id),
            Services = await GetPropertyServices(property.Id),
            Policies = await GetPropertyPolicies(property.Id)
        };

        return dto;
    }

    /// <summary>
    /// الحصول على بيانات نوع الكيان
    /// Get property type DTO
    /// </summary>
    private async Task<PropertyTypeDto> GetPropertyTypeDto(Guid propertyTypeId)
    {
        try
        {
            var propertyTypeRepo = _unitOfWork.Repository<Core.Entities.PropertyType>();
            var propertyType = await propertyTypeRepo.GetByIdAsync(propertyTypeId);

            if (propertyType == null)
            {
                return new PropertyTypeDto
                {
                    Id = Guid.Empty,
                    Name = "غير محدد",
                    Description = "نوع غير محدد"
                };
            }

            return new PropertyTypeDto
            {
                Id = propertyType.Id,
                Name = propertyType.Name,
                Description = propertyType.Description ?? string.Empty
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب نوع الكيان {PropertyTypeId}", propertyTypeId);
            return new PropertyTypeDto
            {
                Id = Guid.Empty,
                Name = "غير محدد",
                Description = "خطأ في جلب البيانات"
            };
        }
    }

    /// <summary>
    /// الحصول على عدد المراجعات
    /// Get reviews count
    /// </summary>
    private async Task<int> GetReviewsCount(Guid propertyId)
    {
        try
        {
            var reviewRepo = _unitOfWork.Repository<Core.Entities.Review>();
            var reviews = await reviewRepo.GetAllAsync();
            return reviews.Count(r => r.PropertyId == propertyId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب عدد المراجعات للكيان {PropertyId}", propertyId);
            return 0;
        }
    }

    /// <summary>
    /// الحصول على عدد المشاهدات
    /// Get view count
    /// </summary>
    private async Task<int> GetViewCount(Guid propertyId)
    {
        try
        {
            // سيتم تطوير هذا لاحقاً عند إضافة نظام تتبع المشاهدات
            return 0;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب عدد المشاهدات للكيان {PropertyId}", propertyId);
            return 0;
        }
    }

    /// <summary>
    /// الحصول على عدد الحجوزات
    /// Get booking count
    /// </summary>
    private async Task<int> GetBookingCount(Guid propertyId)
    {
        try
        {
            var bookingRepo = _unitOfWork.Repository<Core.Entities.Booking>();
            var bookings = await bookingRepo.GetAllAsync();
            
            // جلب جميع الوحدات للكيان أولاً
            var unitRepo = _unitOfWork.Repository<Core.Entities.Unit>();
            var units = await unitRepo.GetAllAsync();
            var propertyUnitIds = units.Where(u => u.PropertyId == propertyId).Select(u => u.Id).ToList();

            // حساب الحجوزات لجميع وحدات الكيان
            return bookings.Count(b => propertyUnitIds.Contains(b.UnitId));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب عدد الحجوزات للكيان {PropertyId}", propertyId);
            return 0;
        }
    }

    /// <summary>
    /// التحقق من وجود الكيان في المفضلات
    /// Check if property is in favorites
    /// </summary>
    private async Task<bool> IsInFavorites(Guid propertyId, Guid? userId)
    {
        try
        {
            if (!userId.HasValue) return false;

            var favoriteRepo = _unitOfWork.Repository<Core.Entities.Favorite>();
            var favorites = await favoriteRepo.GetAllAsync();
            return favorites.Any(f =>
                f.UserId == userId.Value &&
                f.PropertyId == propertyId &&
                !f.IsDeleted);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في التحقق من المفضلات للكيان {PropertyId} والمستخدم {UserId}", propertyId, userId);
            return false;
        }
    }

    /// <summary>
    /// الحصول على صور الكيان
    /// Get property images
    /// </summary>
    private async Task<List<PropertyImageDto>> GetPropertyImages(Guid propertyId)
    {
        try
        {
            var imageRepo = _unitOfWork.Repository<Core.Entities.PropertyImage>();
            var images = await imageRepo.GetAllAsync();

            var propertyImages = images
                .Where(img => img.PropertyId.HasValue && img.PropertyId.Value == propertyId && !img.IsDeleted)
                .OrderBy(img => img.DisplayOrder)
                .ThenBy(img => img.CreatedAt)
                .ToList();

            var dtos = propertyImages.Select(img => new PropertyImageDto
            {
                Id = img.Id,
                PropertyId = img.PropertyId,
                UnitId = img.UnitId,
                SectionId = img.SectionId,
                PropertyInSectionId = img.PropertyInSectionId,
                UnitInSectionId = img.UnitInSectionId,
                CityName = img.CityName,
                Name = img.Name ?? string.Empty,
                Url = img.Url ?? string.Empty,
                SizeBytes = img.SizeBytes,
                Type = img.Type ?? string.Empty,
                Category = img.Category,
                Caption = img.Caption ?? string.Empty,
                AltText = img.AltText ?? string.Empty,
                Tags = img.Tags ?? string.Empty,
                Sizes = img.Sizes ?? string.Empty,
                IsMain = img.IsMain || img.IsMainImage,
                DisplayOrder = img.DisplayOrder != 0 ? img.DisplayOrder : img.SortOrder,
                UploadedAt = img.UploadedAt,
                Status = img.Status,
                AssociationType = img.UnitId.HasValue ? "Unit" : "Property"
            }).ToList();

            return dtos;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب صور الكيان {PropertyId}", propertyId);
            return new List<PropertyImageDto>();
        }
    }

    /// <summary>
    /// الحصول على وسائل الراحة
    /// Get property amenities
    /// </summary>
    private async Task<List<PropertyAmenityDto>> GetPropertyAmenities(Guid propertyId)
    {
        try
        {
            // سيتم تطوير هذا لاحقاً عند إضافة ربط الكيانات بوسائل الراحة
            // حالياً سيتم إرجاع وسائل راحة افتراضية
            return new List<PropertyAmenityDto>
            {
                new PropertyAmenityDto
                {
                    Id = Guid.NewGuid(),
                    Name = "واي فاي مجاني",
                    Description = "إنترنت لاسلكي مجاني في جميع الغرف",
                    IconUrl = "/icons/wifi.svg",
                    Category = "إنترنت",
                    IsAvailable = true,
                    ExtraCost = null
                },
                new PropertyAmenityDto
                {
                    Id = Guid.NewGuid(),
                    Name = "مواقف سيارات",
                    Description = "مواقف سيارات مجانية",
                    IconUrl = "/icons/parking.svg",
                    Category = "مواصلات",
                    IsAvailable = true,
                    ExtraCost = null
                },
                new PropertyAmenityDto
                {
                    Id = Guid.NewGuid(),
                    Name = "مكيف هواء",
                    Description = "تكييف هواء في جميع الغرف",
                    IconUrl = "/icons/ac.svg",
                    Category = "راحة",
                    IsAvailable = true,
                    ExtraCost = null
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب وسائل الراحة للكيان {PropertyId}", propertyId);
            return new List<PropertyAmenityDto>();
        }
    }

    /// <summary>
    /// الحصول على خدمات الكيان
    /// Get property services
    /// </summary>
    private async Task<List<PropertyServiceDto>> GetPropertyServices(Guid propertyId)
    {
        try
        {
            // سيتم تطوير هذا لاحقاً عند إضافة نظام الخدمات
            return new List<PropertyServiceDto>
            {
                new PropertyServiceDto
                {
                    Id = Guid.NewGuid(),
                    Name = "خدمة الغسيل",
                    Price = 50,
                    Currency = "YER",
                    PricingModel = "per_item"
                },
                new PropertyServiceDto
                {
                    Id = Guid.NewGuid(),
                    Name = "خدمة النقل من المطار",
                    Price = 200,
                    Currency = "YER",
                    PricingModel = "per_trip"
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب خدمات الكيان {PropertyId}", propertyId);
            return new List<PropertyServiceDto>();
        }
    }

    /// <summary>
    /// الحصول على سياسات الكيان
    /// Get property policies
    /// </summary>
    private async Task<List<PropertyPolicyDto>> GetPropertyPolicies(Guid propertyId)
    {
        try
        {
            // سيتم تطوير هذا لاحقاً عند إضافة نظام السياسات
            return new List<PropertyPolicyDto>
            {
                new PropertyPolicyDto
                {
                    Id = Guid.NewGuid(),
                    Type = "check_in",
                    Description = "تسجيل الوصول من الساعة 3:00 مساءً إلى 11:00 مساءً",
                    Rules = new Dictionary<string, object>
                    {
                        { "earliest_time", "15:00" },
                        { "latest_time", "23:00" }
                    }
                },
                new PropertyPolicyDto
                {
                    Id = Guid.NewGuid(),
                    Type = "check_out",
                    Description = "تسجيل المغادرة حتى الساعة 12:00 ظهراً",
                    Rules = new Dictionary<string, object>
                    {
                        { "latest_time", "12:00" }
                    }
                },
                new PropertyPolicyDto
                {
                    Id = Guid.NewGuid(),
                    Type = "cancellation",
                    Description = "إلغاء مجاني حتى 24 ساعة قبل الوصول",
                    Rules = new Dictionary<string, object>
                    {
                        { "free_cancellation_hours", 24 },
                        { "cancellation_fee_percentage", 50 }
                    }
                }
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ في جلب سياسات الكيان {PropertyId}", propertyId);
            return new List<PropertyPolicyDto>();
        }
    }
}