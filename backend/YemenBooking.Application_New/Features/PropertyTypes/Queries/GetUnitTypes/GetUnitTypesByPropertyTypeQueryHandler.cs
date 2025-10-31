using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.PropertyTypes;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Core.Interfaces.Repositories;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.SearchAndFilters.DTOs;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.PropertyTypes.Queries.GetUnitTypes
{
    /// <summary>
    /// معالج استعلام الحصول على أنواع الوحدات لنوع كيان معين
    /// Query handler for GetUnitTypesByPropertyTypeQuery
    /// </summary>
    public class GetUnitTypesByPropertyTypeQueryHandler : IRequestHandler<GetUnitTypesByPropertyTypeQuery, PaginatedResult<UnitTypeDto>>
    {
        private readonly IUnitTypeRepository _repo;
        private readonly IUnitTypeFieldRepository _fieldRepo;
        private readonly ISearchFilterRepository _filterRepo;
        private readonly IFieldGroupRepository _groupRepo;
        private readonly ILogger<GetUnitTypesByPropertyTypeQueryHandler> _logger;

        public GetUnitTypesByPropertyTypeQueryHandler(
            IUnitTypeRepository repo,
            IUnitTypeFieldRepository fieldRepo,
            ISearchFilterRepository filterRepo,
            IFieldGroupRepository groupRepo,
            ILogger<GetUnitTypesByPropertyTypeQueryHandler> logger)
        {
            _repo = repo;
            _fieldRepo = fieldRepo;
            _filterRepo = filterRepo;
            _groupRepo = groupRepo;
            _logger = logger;
        }

        public async Task<PaginatedResult<UnitTypeDto>> Handle(GetUnitTypesByPropertyTypeQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام أنواع الوحدات لنوع الكيان: {PropertyTypeId}", request.PropertyTypeId);

            if (request.PropertyTypeId == Guid.Empty)
                throw new ValidationException(nameof(request.PropertyTypeId), "معرف نوع الكيان غير صالح");

            var unitTypes = await _repo.GetUnitTypesByPropertyTypeAsync(request.PropertyTypeId, cancellationToken);

            var dtos = new List<UnitTypeDto>();
            var fieldEntities = new Dictionary<Guid, List<UnitTypeField>>();
            foreach (var ut in unitTypes)
            {
                // جلب الحقول والدوال قبل التجميع
                if (!fieldEntities.ContainsKey(ut.Id))
                    fieldEntities[ut.Id] = (await _fieldRepo.GetFieldsByUnitTypeIdAsync(ut.Id, cancellationToken)).ToList();
                var fields = fieldEntities[ut.Id];

                var dto = new UnitTypeDto
                {
                    Id = ut.Id,
                    PropertyTypeId = ut.PropertyTypeId,
                    Name = ut.Name,
                    Description = ut.Description,
                    DefaultPricingRules = ut.DefaultPricingRules,
                    Icon = ut.Icon,
                    SystemCommissionRate = ut.SystemCommissionRate,
                    IsHasAdults = ut.IsHasAdults,
                    IsHasChildren = ut.IsHasChildren,
                    IsMultiDays = ut.IsMultiDays,
                    IsRequiredToDetermineTheHour = ut.IsRequiredToDetermineTheHour,
                    Filters = (await _filterRepo.GetQueryable()
                        .AsNoTracking()
                        .Include(sf => sf.UnitTypeField)
                        .Where(sf => sf.UnitTypeField.UnitTypeId == ut.Id && sf.IsActive)
                        .OrderBy(sf => sf.SortOrder)
                        .ToListAsync(cancellationToken))
                        .Select(sf => new SearchFilterDto
                        {
                            FilterId = sf.Id,
                            FieldId = sf.FieldId,
                            FilterType = sf.FilterType,
                            DisplayName = sf.DisplayName,
                            FilterOptions = JsonSerializer.Deserialize<Dictionary<string, object>>(sf.FilterOptions) ?? new Dictionary<string, object>(),
                            IsActive = sf.IsActive,
                            SortOrder = sf.SortOrder,
                            Field = null
                        }).ToList(),
                    FieldGroups = (await _groupRepo.GetGroupsByUnitTypeIdAsync(ut.Id, cancellationToken))
                        .OrderBy(g => g.SortOrder)
                        .Select(g => new FieldGroupDto
                        {
                            GroupId = g.Id.ToString(),
                            UnitTypeId = g.UnitTypeId.ToString(),
                            GroupName = g.GroupName,
                            DisplayName = g.DisplayName,
                            Description = g.Description,
                            SortOrder = g.SortOrder,
                            IsCollapsible = g.IsCollapsible,
                            IsExpandedByDefault = g.IsExpandedByDefault,
                            Fields = g.FieldGroupFields
                                .OrderBy(link => link.SortOrder)
                                .Select(link =>
                                {
                                    var fe = fields.FirstOrDefault(f => f.Id == link.FieldId);
                                    return new UnitTypeFieldDto
                                    {
                                        FieldId = fe.Id.ToString(),
                                        UnitTypeId = fe.UnitTypeId.ToString(),
                                        FieldTypeId = fe.FieldTypeId.ToString(),
                                        FieldName = fe.FieldName,
                                        DisplayName = fe.DisplayName,
                                        Description = fe.Description,
                                        FieldOptions = JsonSerializer.Deserialize<Dictionary<string, object>>(fe.FieldOptions) ?? new Dictionary<string, object>(),
                                        ValidationRules = JsonSerializer.Deserialize<Dictionary<string, object>>(fe.ValidationRules) ?? new Dictionary<string, object>(),
                                        IsRequired = fe.IsRequired,
                                        IsSearchable = fe.IsSearchable,
                                        IsPublic = fe.IsPublic,
                                        SortOrder = fe.SortOrder,
                                        Category = fe.Category,
                                        GroupId = g.Id.ToString()
                                    };
                                })
                                .ToList()
                        }).ToList()
                };
                dtos.Add(dto);
            }

            var totalCount = dtos.Count;
            var items = dtos.Skip((request.PageNumber - 1) * request.PageSize)
                            .Take(request.PageSize)
                            .ToList();

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