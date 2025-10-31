using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Amenities.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Amenities.Queries.GetAmenityStats
{
    public class GetAmenityStatsQueryHandler : IRequestHandler<GetAmenityStatsQuery, AmenityStatsDto>
    {
        private readonly IAmenityRepository _amenityRepository;
        private readonly ICurrentUserService _currentUserService;

        public GetAmenityStatsQueryHandler(IAmenityRepository amenityRepository, ICurrentUserService currentUserService)
        {
            _amenityRepository = amenityRepository;
            _currentUserService = currentUserService;
        }

        public async Task<AmenityStatsDto> Handle(GetAmenityStatsQuery request, CancellationToken cancellationToken)
        {
            var amenities = (await _amenityRepository.GetAllAmenitiesAsync(cancellationToken)).ToList();
            var allPa = (await _amenityRepository.GetAllPropertyAmenitiesAsync(cancellationToken)).ToList();

            var stats = new AmenityStatsDto
            {
                TotalAmenities = amenities.Count,
                ActiveAmenities = amenities.Count(a => a.IsActive),
                TotalAssignments = allPa.Count,
                TotalRevenue = allPa.Sum(pa => (decimal)(pa.ExtraCost?.Amount ?? 0)),
            };

            stats.PopularAmenities = allPa
                .GroupBy(pa => pa.PropertyTypeAmenity.Amenity.Name)
                .OrderByDescending(g => g.Count())
                .Take(10)
                .ToDictionary(g => g.Key, g => g.Count());

            stats.RevenueByAmenity = allPa
                .GroupBy(pa => pa.PropertyTypeAmenity.Amenity.Name)
                .ToDictionary(g => g.Key, g => g.Sum(x => (decimal)(x.ExtraCost?.Amount ?? 0)));

            // No direct DateTime fields in stats, but if future fields added ensure conversion
            return stats;
        }
    }
}

