using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Amenities.Commands.ManageAmenities;

/// <summary>
/// أمر لتحديث بيانات المرفق
/// Command to update amenity information
/// </summary>
public class UpdateAmenityCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف المرفق
    /// Amenity ID
    /// </summary>
    public Guid AmenityId { get; set; }

    /// <summary>
    /// اسم المرفق المحدث
    /// Updated amenity name
    /// </summary>
    public string? Name { get; set; }

    /// <summary>
    /// وصف المرفق المحدث
    /// Updated amenity description
    /// </summary>
    public string? Description { get; set; }

    /// <summary>
    /// أيقونة المرفق
    /// Amenity icon
    /// </summary>
    public string Icon { get; set; } = string.Empty;
} 