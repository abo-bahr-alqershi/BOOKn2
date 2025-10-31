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

namespace YemenBooking.Application.Features.Amenities.Queries.GetPopularAmenities
{
    public class GetPopularAmenitiesQueryHandler : IRequestHandler<GetPopularAmenitiesQuery, List<AmenityDto>>
    {
        private readonly IAmenityRepository _amenityRepository;
        private readonly ICurrentUserService _currentUserService;

        public GetPopularAmenitiesQueryHandler(IAmenityRepository amenityRepository, ICurrentUserService currentUserService)
        {
            _amenityRepository = amenityRepository;
            _currentUserService = currentUserService;
        }

        public async Task<List<AmenityDto>> Handle(GetPopularAmenitiesQuery request, CancellationToken cancellationToken)
        {
            var allPa = (await _amenityRepository.GetAllPropertyAmenitiesAsync(cancellationToken)).ToList();
            var grouped = allPa
                .GroupBy(pa => pa.PropertyTypeAmenity.Amenity)
                .OrderByDescending(g => g.Count())
                .Take(request.Limit)
                .Select(g => new AmenityDto
                {
                    Id = g.Key.Id,
                    Name = g.Key.Name,
                    Description = g.Key.Description,
                    Icon = g.Key.Icon,
                    IsActive = g.Key.IsActive,
                    CreatedAt = g.Key.CreatedAt,
                    UpdatedAt = g.Key.UpdatedAt
                })
                .ToList();

            // Normalize DateTime fields to user's local time
            for (int i = 0; i < grouped.Count; i++)
            {
                grouped[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(grouped[i].CreatedAt);
                if (grouped[i].UpdatedAt.HasValue)
                {
                    grouped[i].UpdatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(grouped[i].UpdatedAt.Value);
                }
            }

            return grouped;
        }
    }
}

