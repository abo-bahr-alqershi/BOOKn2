using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Amenities.Commands.AssignAmenities;

/// <summary>
/// أمر لإلغاء إسناد مرفق من عقار
/// Command to unassign an amenity from a property
/// </summary>
public class UnassignAmenityFromPropertyCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف العقار
    /// </summary>
    public Guid PropertyId { get; set; }

    /// <summary>
    /// معرف المرفق
    /// </summary>
    public Guid AmenityId { get; set; }
}

