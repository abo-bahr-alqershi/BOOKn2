using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Amenities.Commands.ManageAmenities
{
    /// <summary>
    /// Command to toggle amenity status
    /// </summary>
    public class ToggleAmenityStatusCommand : IRequest<ResultDto<bool>>
    {
        public Guid AmenityId { get; set; }
    }
}

