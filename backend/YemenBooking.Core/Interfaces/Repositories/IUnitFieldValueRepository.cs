using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع قيم الحقول للوحدات
/// UnitFieldValue repository interface
/// </summary>
public interface IUnitFieldValueRepository : IRepository<UnitFieldValue>
{
    Task<UnitFieldValue> CreateUnitFieldValueAsync(UnitFieldValue unitFieldValue, CancellationToken cancellationToken = default);

    Task<UnitFieldValue?> GetUnitFieldValueByIdAsync(Guid valueId, CancellationToken cancellationToken = default);

    Task<UnitFieldValue> UpdateUnitFieldValueAsync(UnitFieldValue unitFieldValue, CancellationToken cancellationToken = default);

    Task<bool> DeleteUnitFieldValueAsync(Guid valueId, CancellationToken cancellationToken = default);

    Task<IEnumerable<UnitFieldValue>> GetValuesByUnitIdAsync(Guid unitId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على القيم بواسطة معرف الحقل
    /// Get values by field ID
    /// </summary>
    Task<IEnumerable<UnitFieldValue>> GetByFieldIdAsync(Guid fieldId, CancellationToken cancellationToken = default);
}