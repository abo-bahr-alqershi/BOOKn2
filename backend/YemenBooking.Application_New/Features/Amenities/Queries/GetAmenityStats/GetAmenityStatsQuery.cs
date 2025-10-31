using MediatR;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Amenities.Queries.GetAmenityStats
{
    /// <summary>
    /// Query to get amenity statistics
    /// </summary>
    public class GetAmenityStatsQuery : IRequest<AmenityStatsDto>
    {
    }
}

