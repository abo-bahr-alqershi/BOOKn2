using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Amenities.Commands.ManageAmenities;

/// <summary>
/// أمر لإنشاء مرفق جديد
/// Command to create a new amenity
/// </summary>
public class CreateAmenityCommand : IRequest<ResultDto<Guid>>
{
    /// <summary>
    /// اسم المرفق
    /// Amenity name
    /// </summary>
    public string Name { get; set; } = string.Empty;

    /// <summary>
    /// وصف المرفق
    /// Amenity description
    /// </summary>
    public string Description { get; set; } = string.Empty;

    /// <summary>
    /// أيقونة المرفق
    /// Amenity icon
    /// </summary>
    public string Icon { get; set; } = string.Empty;

    /// <summary>
    /// اختيارياً: نوع الكيان الذي سيتم ربط المرفق به مباشرةً بعد الإنشاء
    /// Optional: Property type to immediately link this amenity to after creation
    /// </summary>
    public Guid? PropertyTypeId { get; set; }

    /// <summary>
    /// هل يكون الربط كافتراضي لنوع الكيان
    /// Whether the link should be marked as default for the property type
    /// </summary>
    public bool IsDefaultForType { get; set; } = false;
} 