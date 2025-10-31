using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.Analytics.Queries {
    /// <summary>
    /// معالج استعلام أفضل الكيانات أداءً
    /// </summary>
    public class GetTopPerformingPropertiesQueryHandler : IRequestHandler<GetTopPerformingPropertiesQuery, IEnumerable<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>>
    {
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetTopPerformingPropertiesQueryHandler> _logger;

        public GetTopPerformingPropertiesQueryHandler(
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            ILogger<GetTopPerformingPropertiesQueryHandler> logger)
        {
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }

        public async Task<IEnumerable<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>> Handle(GetTopPerformingPropertiesQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("Processing Top Performing PropertyDto Query Count {Count}", request.Count);

            var currentUser = await _currentUserService.GetCurrentUserAsync(cancellationToken);
            if (currentUser == null || _currentUserService.Role != "Admin")
                throw new UnauthorizedException("يجب أن تكون مسؤولًا للوصول إلى أفضل الكيانات أداءً");

            var query = _propertyRepository.GetQueryable()
                .AsNoTracking()
                .AsSplitQuery()
                .Include(p => p.Owner)
                .Include(p => p.PropertyType)
                .OrderByDescending(p => p.BookingCount)
                .Take(request.Count);

            var properties = await query.ToListAsync(cancellationToken);

            var dtos = properties.Select(p => new YemenBooking.Application.Features.Properties.DTOs.PropertyDto
            {
                Id = p.Id,
                OwnerId = p.OwnerId,
                TypeId = p.TypeId,
                Name = p.Name,
                Address = p.Address,
                City = p.City,
                Latitude = p.Latitude,
                Longitude = p.Longitude,
                StarRating = p.StarRating,
                Description = p.Description,
                IsApproved = p.IsApproved,
                CreatedAt = p.CreatedAt,
                OwnerName = p.Owner.Name,
                TypeName = p.PropertyType.Name
            }).ToList();

            // If CreatedAt is UTC in DB, convert to user local
            for (int i = 0; i < dtos.Count; i++)
            {
                dtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CreatedAt);
            }

            return dtos;
        }
    }
} 