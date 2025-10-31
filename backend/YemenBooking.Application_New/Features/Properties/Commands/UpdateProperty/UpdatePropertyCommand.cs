using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Properties.Commands.UpdateProperty;

/// <summary>
/// أمر لتحديث بيانات الكيان
/// Command to update property information
/// </summary>
public class UpdatePropertyCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الكيان
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// اسم الكيان المحدث
    /// Updated property name
    /// </summary>
    public string? Name { get; set; }

    /// <summary>
    /// العنوان المحدث للكيان
    /// Updated property address
    /// </summary>
    public string? Address { get; set; }

    /// <summary>
    /// وصف الكيان المحدث
    /// Updated property description
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// خط العرض المحدث للموقع الجغرافي
    /// Updated latitude for geographic location
    /// </summary>
    public double? Latitude { get; set; }

    /// <summary>
    /// خط الطول المحدث للموقع الجغرافي
    /// Updated longitude for geographic location
    /// </summary>
    public double? Longitude { get; set; }

    /// <summary>
    /// المدينة المحدثة
    /// Updated city
    /// </summary>
    public string? City { get; set; }

    /// <summary>
    /// تقييم النجوم المحدث
    /// Updated star rating
    /// </summary>
    public int? StarRating { get; set; }

    /// <summary>
    /// صور الكيان المحدثة
    /// Updated property images
    /// </summary>
    public List<string> Images { get; set; } = new List<string>();

    /// <summary>
    /// وصف مختصر
    /// Short description
    /// </summary>
    public string? ShortDescription { get; set; }

    /// <summary>
    /// السعر الأساسي لليلة
    /// Base price per night
    /// </summary>

    /// <summary>
    /// رمز العملة
    /// Currency code
    /// </summary>
    public string? Currency { get; set; }

    /// <summary>
    /// عقار مميز؟
    /// Is featured
    /// </summary>
    public bool? IsFeatured { get; set; }

    /// <summary>
    /// تحديث المالك (اختياري - للمشرف فقط)
    /// New owner id (optional - admin only)
    /// </summary>
    public Guid? OwnerId { get; set; }

    /// <summary>
    /// قائمة معرفات المرافق المراد تعيينها للعقار (تزامن كامل)
    /// List of amenity ids to assign to the property (full sync)
    /// </summary>
    public List<Guid>? AmenityIds { get; set; }

} 