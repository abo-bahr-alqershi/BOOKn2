using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Amenities.Commands.AssignAmenities;

/// <summary>
/// أمر لتخصيص مرفق لكيان
/// Command to assign an amenity to a property
/// </summary>
public class AssignAmenityToPropertyCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف الكيان
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// معرف المرفق
    /// Amenity ID
    /// </summary>
    public Guid AmenityId { get; set; }

    /// <summary>
    /// Is the amenity available for the property
    /// </summary>
    public bool IsAvailable { get; set; } = true;

    /// <summary>
    /// Optional extra cost
    /// </summary>
    public decimal? ExtraCost { get; set; }

    /// <summary>
    /// Optional description
    /// </summary>
    public string? Description { get; set; }
} 