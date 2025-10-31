using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Common.Exceptions;
using YemenBooking.Application.Features.DynamicFields;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.DynamicFields.Queries.GetUnitTypeFields
{
    /// <summary>
    /// معالج استعلام جلب جميع الحقول الديناميكية لنوع الكيان
    /// Query handler for GetUnitTypeFieldsQuery
    /// </summary>
    public class GetUnitTypeFieldsQueryHandler : IRequestHandler<GetUnitTypeFieldsQuery, List<UnitTypeFieldDto>>
    {
        private readonly IUnitTypeFieldRepository _fieldRepo;
        private readonly ILogger<GetUnitTypeFieldsQueryHandler> _logger;

        public GetUnitTypeFieldsQueryHandler(
            IUnitTypeFieldRepository fieldRepo,
            ILogger<GetUnitTypeFieldsQueryHandler> logger)
        {
            _fieldRepo = fieldRepo;
            _logger = logger;
        }

        public async Task<List<UnitTypeFieldDto>> Handle(GetUnitTypeFieldsQuery request, CancellationToken cancellationToken)
        {
            _logger.LogInformation("جاري معالجة استعلام الحقول الديناميكية لنوع الكيان: {PropertyTypeId}", request.unitTypeId);

            if (!Guid.TryParse(request.unitTypeId, out var typeId))
                throw new ValidationException(nameof(request.unitTypeId), "معرف نوع الكيان غير صالح");

            var query = _fieldRepo.GetQueryable().AsNoTracking()
                .Where(f => f.UnitTypeId == typeId)
                .Where(f => !request.IsActive.HasValue || f.IsActive == request.IsActive.Value)
                .Where(f => !request.IsSearchable.HasValue || f.IsSearchable == request.IsSearchable.Value)
                .Where(f => !request.IsPublic.HasValue || f.IsPublic == request.IsPublic.Value);

            if (!string.IsNullOrWhiteSpace(request.Category))
                query = query.Where(f => f.Category == request.Category);

            if (request.IsForUnits.HasValue)
                query = query.Where(f => f.IsForUnits == request.IsForUnits.Value);

            // Filter by search term on field name or display name
            if (!string.IsNullOrWhiteSpace(request.SearchTerm))
            {
                var term = request.SearchTerm.ToLower();
                query = query.Where(f =>
                    f.DisplayName.ToLower().Contains(term) ||
                    f.FieldName.ToLower().Contains(term)
                );
            }

            var entities = await query.OrderBy(f => f.SortOrder).ToListAsync(cancellationToken);

            return entities.Select(f => new UnitTypeFieldDto
            {
                FieldId = f.Id.ToString(),
                UnitTypeId = f.UnitTypeId.ToString(),
                FieldTypeId = f.FieldTypeId.ToString(),
                FieldName = f.FieldName,
                DisplayName = f.DisplayName,
                Description = f.Description,
                FieldOptions = JsonSerializer.Deserialize<Dictionary<string, object>>(f.FieldOptions) ?? new Dictionary<string, object>(),
                ValidationRules = JsonSerializer.Deserialize<Dictionary<string, object>>(f.ValidationRules) ?? new Dictionary<string, object>(),
                IsRequired = f.IsRequired,
                IsSearchable = f.IsSearchable,
                IsPublic = f.IsPublic,
                SortOrder = f.SortOrder,
                Category = f.Category,
                GroupId = f.FieldGroupFields.FirstOrDefault()?.GroupId.ToString() ?? string.Empty,
                IsForUnits = f.IsForUnits,
                ShowInCards = f.ShowInCards,
                IsPrimaryFilter = f.IsPrimaryFilter,
                Priority = f.Priority
            }).ToList();
        }
    }
} 