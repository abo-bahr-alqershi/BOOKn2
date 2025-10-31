using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع حقول نوع الكيان
/// UnitTypeField repository interface
/// </summary>
public interface IUnitTypeFieldRepository : IRepository<UnitTypeField>
{
    Task<UnitTypeField> CreateUnitTypeFieldAsync(UnitTypeField unitTypeField, CancellationToken cancellationToken = default);

    Task<UnitTypeField?> GetUnitTypeFieldByIdAsync(Guid fieldId, CancellationToken cancellationToken = default);

    Task<UnitTypeField> UpdateUnitTypeFieldAsync(UnitTypeField unitTypeField, CancellationToken cancellationToken = default);

    Task<bool> DeleteUnitTypeFieldAsync(Guid fieldId, CancellationToken cancellationToken = default);

    Task<IEnumerable<UnitTypeField>> GetFieldsByUnitTypeIdAsync(Guid unitTypeId, CancellationToken cancellationToken = default);
} 