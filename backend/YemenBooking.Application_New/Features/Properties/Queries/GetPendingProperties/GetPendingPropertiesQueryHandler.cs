using System;
using System.Linq;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Properties.Queries.GetPendingProperties;

namespace YemenBooking.Application.Queries.Properties
{
    /// <summary>
    /// معالج استعلام الحصول على الكيانات في انتظار الموافقة
    /// Handler for GetPendingPropertiesQuery
    /// </summary>
    public class GetPendingPropertiesQueryHandler : IRequestHandler<GetPendingPropertiesQuery, PaginatedResult<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>>
    {
        #region Dependencies
        private readonly IPropertyRepository _propertyRepository;
        private readonly ICurrentUserService _currentUserService;
        private readonly ILogger<GetPendingPropertiesQueryHandler> _logger;
        #endregion

        #region Constructor
        public GetPendingPropertiesQueryHandler(
            IPropertyRepository propertyRepository,
            ICurrentUserService currentUserService,
            ILogger<GetPendingPropertiesQueryHandler> logger)
        {
            _propertyRepository = propertyRepository;
            _currentUserService = currentUserService;
            _logger = logger;
        }
        #endregion

        #region Handler Implementation
        public async Task<PaginatedResult<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>> Handle(GetPendingPropertiesQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("بدء جلب الكيانات في انتظار الموافقة - الصفحة: {PageNumber}, الحجم: {PageSize}",
                request.PageNumber, request.PageSize);

            // Authorization: admin only
            var role = _currentUserService.Role;
            if (role != "Admin")
            {
                _logger.LogWarning("ليس لديك صلاحية لعرض الكيانات في انتظار الموافقة");
                throw new UnauthorizedAccessException("ليس لديك صلاحية لعرض الكيانات في انتظار الموافقة");
            }

            // Build query
            var query = _propertyRepository.GetQueryable()
                .AsNoTracking()
                .Include(p => p.PropertyType)
                .Include(p => p.Owner)
                .Include(p => p.Images.Where(i => i.IsMainImage && !i.IsDeleted))
                .Where(p => !p.IsDeleted && !p.IsApproved);

            // Pagination
            var totalCount = await query.CountAsync(cancellationToken);
            var properties = await query
                .Skip((request.PageNumber - 1) * request.PageSize)
                .Take(request.PageSize)
                .ToListAsync(cancellationToken);

            // Mapping to DTOs
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
                TypeName = p.PropertyType.Name,
                Images = p.Images.Select(i => new PropertyImageDto
                {
                    Id = i.Id,
                    PropertyId = i.PropertyId,
                    UnitId = i.UnitId,
                    Name = i.Name,
                    Url = i.Url,
                    SizeBytes = i.SizeBytes,
                    Type = i.Type,
                    Category = i.Category,
                    Caption = i.Caption,
                    AltText = i.AltText,
                    Tags = i.Tags,
                    Sizes = i.Sizes,
                    IsMain = i.IsMain,
                    DisplayOrder = i.DisplayOrder,
                    UploadedAt = i.UploadedAt,
                    Status = i.Status,
                    AssociationType = i.PropertyId != null ? "Property" : "Unit"
                }).ToList()
            }).ToList();

            // Localize date fields for client
            for (int i = 0; i < dtos.Count; i++)
            {
                dtos[i].CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(dtos[i].CreatedAt);
                if (dtos[i].Images != null)
                {
                    foreach (var image in dtos[i].Images)
                    {
                        image.UploadedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(image.UploadedAt);
                    }
                }
            }

            _logger.LogInformation("تم جلب {Count} كيان من إجمالي {TotalCount} في انتظار الموافقة", dtos.Count, totalCount);
            return new PaginatedResult<YemenBooking.Application.Features.Properties.DTOs.PropertyDto>
            {
                Items = dtos,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalCount = totalCount
            };
        }
        #endregion
    }
} 