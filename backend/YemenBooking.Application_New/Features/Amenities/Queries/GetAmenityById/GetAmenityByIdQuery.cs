using MediatR;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Amenities.Queries.GetAmenityById
{
    /// <summary>
    /// Query to get amenity by id
    /// </summary>
    public class GetAmenityByIdQuery : IRequest<AmenityDto>
    {
        public Guid AmenityId { get; set; }
    }
}

