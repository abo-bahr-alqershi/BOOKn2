using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.PropertyTypes;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Interfaces.Repositories;
using System.Text.Json;
using System.Collections.Generic; // added for List<>
using YemenBooking.Application.Features.Properties.DTOs;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetAllPropertyTypes
{
    /// <summary>
    /// معالج استعلام الحصول على جميع أنواع الكيانات
    /// Query handler for GetAllPropertyTypesQuery
    /// </summary>
    public class GetAllPropertyTypesQueryHandler : IRequestHandler<GetAllPropertyTypesQuery, PaginatedResult<PropertyTypeDto>>
    {
        private readonly IPropertyTypeRepository _repo;
        private readonly ILogger<GetAllPropertyTypesQueryHandler> _logger;

        public GetAllPropertyTypesQueryHandler(
            IPropertyTypeRepository repo,
            ILogger<GetAllPropertyTypesQueryHandler> logger)
        {
            _repo = repo;
            _logger = logger;
        }

        public async Task<PaginatedResult<PropertyTypeDto>> Handle(GetAllPropertyTypesQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام جميع أنواع الكيانات - الصفحة: {PageNumber}, الحجم: {PageSize}", request.PageNumber, request.PageSize);

            var all = await _repo.GetAllPropertyTypesAsync(cancellationToken);
            var dtos = all.Select(pt =>
            {
                var dto = new PropertyTypeDto
                {
                    Id = pt.Id,
                    Name = pt.Name,
                    Description = pt.Description,
                    Icon = pt.Icon,
                    PropertiesCount = pt.Properties?.Count ?? 0,
                    UnitTypeIds = pt.UnitTypes?.Select(ut => ut.Id).ToList() ?? new List<Guid>()
                };

                // Safe JSON parse for DefaultAmenities
                if (!string.IsNullOrWhiteSpace(pt.DefaultAmenities))
                {
                    try
                    {
                        var parsed = JsonSerializer.Deserialize<List<string>>(pt.DefaultAmenities.Trim());
                        dto.DefaultAmenities = parsed ?? new List<string>();
                    }
                    catch (JsonException jsonEx)
                    {
                        _logger.LogWarning(jsonEx, "تعذر قراءة قيم DefaultAmenities كنص JSON صالح لنوع الكيان {PropertyTypeId}. القيمة الأصلية: {Value}. سيتم تعيين قائمة فارغة.", pt.Id, pt.DefaultAmenities);
                        dto.DefaultAmenities = new List<string>();
                    }
                }
                else
                {
                    dto.DefaultAmenities = new List<string>();
                }

                return dto;
            }).ToList();

            var totalCount = dtos.Count;
            var items = dtos.Skip((request.PageNumber - 1) * request.PageSize)
                            .Take(request.PageSize)
                            .ToList();

            return new PaginatedResult<PropertyTypeDto>
            {
                Items = items,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalCount = totalCount
            };
        }
    }
}