using MediatR;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Amenities.Queries.GetPopularAmenities
{
    /// <summary>
    /// Query to get popular amenities
    /// </summary>
    public class GetPopularAmenitiesQuery : IRequest<List<AmenityDto>>
    {
        public int Limit { get; set; } = 10;
    }
}

