using System.Linq;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.PropertyTypes;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetAllUnitTypes
{
    /// <summary>
    /// معالج استعلام للحصول على جميع أنواع الوحدات
    /// Handler for GetAllUnitTypesQuery
    /// </summary>
    public class GetAllUnitTypesQueryHandler : IRequestHandler<GetAllUnitTypesQuery, PaginatedResult<UnitTypeDto>>
    {
        private readonly IUnitTypeRepository _repo;
        private readonly ILogger<GetAllUnitTypesQueryHandler> _logger;

        public GetAllUnitTypesQueryHandler(IUnitTypeRepository repo, ILogger<GetAllUnitTypesQueryHandler> logger)
        {
            _repo = repo;
            _logger = logger;
        }

        public async Task<PaginatedResult<UnitTypeDto>> Handle(GetAllUnitTypesQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام جميع أنواع الوحدات - الصفحة: {PageNumber}, الحجم: {PageSize}", request.PageNumber, request.PageSize);

            var allUnitTypes = await _repo.GetAllUnitTypesAsync(cancellationToken);
            var dtos = allUnitTypes.Select(ut => new UnitTypeDto
            {
                Id = ut.Id,
                PropertyTypeId = ut.PropertyTypeId,
                Name = ut.Name,
                Description = ut.Description,
                DefaultPricingRules = ut.DefaultPricingRules,
                Icon = ut.Icon,
                SystemCommissionRate = ut.SystemCommissionRate,
                FieldGroups = new List<FieldGroupDto>(),
                Filters = new List<SearchFilterDto>(),
                IsHasAdults = ut.IsHasAdults,
                IsHasChildren = ut.IsHasChildren,
                IsMultiDays = ut.IsMultiDays,
                IsRequiredToDetermineTheHour = ut.IsRequiredToDetermineTheHour
            });

            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = request.SearchTerm.Trim().ToLower();
                dtos = dtos.Where(dto => dto.Name.ToLower().Contains(term));
            }

            var dtoList = dtos.ToList();
            var totalCount = dtoList.Count;
            var items = dtoList.Skip((request.PageNumber - 1) * request.PageSize).Take(request.PageSize).ToList();

            return new PaginatedResult<UnitTypeDto>
            {
                Items = items,
                PageNumber = request.PageNumber,
                PageSize = request.PageSize,
                TotalCount = totalCount
            };
        }
    }
} 