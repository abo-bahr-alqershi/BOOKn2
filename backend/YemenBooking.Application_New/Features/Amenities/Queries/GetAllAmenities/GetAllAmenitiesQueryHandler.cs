using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Amenities.Queries.GetAllAmenities;

/// <summary>
/// معالج استعلام الحصول على جميع وسائل الراحة
/// Handler for get all amenities query
/// </summary>
public class GetAllAmenitiesQueryHandler : IRequestHandler<GetAllAmenitiesQuery, ResultDto<List<AmenityDto>>>
{
    private readonly IAmenityRepository _amenityRepository;
    private readonly ILogger<GetAllAmenitiesQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام الحصول على جميع وسائل الراحة
    /// Constructor for get all amenities query handler
    /// </summary>
    /// <param name="amenityRepository">مستودع وسائل الراحة</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetAllAmenitiesQueryHandler(
        IAmenityRepository amenityRepository,
        ILogger<GetAllAmenitiesQueryHandler> logger)
    {
        _amenityRepository = amenityRepository;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على جميع وسائل الراحة
    /// Handle get all amenities query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة وسائل الراحة</returns>
    public async Task<ResultDto<List<AmenityDto>>> Handle(GetAllAmenitiesQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام الحصول على جميع وسائل الراحة. الفئة: {Category}", request.Category ?? "جميع الفئات");

            // الحصول على وسائل الراحة من قاعدة البيانات
            var allAmenities = await _amenityRepository.GetAllAsync(cancellationToken);
            var amenities = string.IsNullOrWhiteSpace(request.Category)
                ? allAmenities?.Where(a => a.IsActive)
                : allAmenities?.Where(a => a.IsActive && a.Name.Contains(request.Category, StringComparison.OrdinalIgnoreCase));

            if (amenities == null || !amenities.Any())
            {
                _logger.LogInformation("لم يتم العثور على وسائل راحة للفئة: {Category}", request.Category ?? "جميع الفئات");
                
                return ResultDto<List<AmenityDto>>.Ok(
                    new List<AmenityDto>(), 
                    "لا توجد وسائل راحة متاحة حالياً"
                );
            }

            // تحويل البيانات إلى DTO
            var amenityDtos = amenities.Select(amenity => new AmenityDto
            {
                Id = amenity.Id,
                Name = amenity.Name,
                Description = amenity.Description ?? string.Empty,
                IconUrl = string.Empty, // يمكن إضافة هذه الخاصية لاحقاً
                Category = amenity.Name ?? string.Empty // استخدام الاسم كفئة مؤقتة
            }).ToList();

            // ترتيب وسائل الراحة حسب الفئة ثم الاسم
            amenityDtos = amenityDtos
                .OrderBy(a => a.Category)
                .ThenBy(a => a.Name)
                .ToList();

            _logger.LogInformation("تم الحصول على {Count} وسيلة راحة بنجاح", amenityDtos.Count);

            return ResultDto<List<AmenityDto>>.Ok(
                amenityDtos, 
                $"تم الحصول على {amenityDtos.Count} وسيلة راحة"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على وسائل الراحة. الفئة: {Category}", request.Category);
            return ResultDto<List<AmenityDto>>.Failed(
                $"حدث خطأ أثناء الحصول على وسائل الراحة: {ex.Message}", 
                "GET_AMENITIES_ERROR"
            );
        }
    }
}
