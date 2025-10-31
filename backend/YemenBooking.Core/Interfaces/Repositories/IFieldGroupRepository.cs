using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع مجموعات الحقول
/// FieldGroup repository interface
/// </summary>
public interface IFieldGroupRepository : IRepository<FieldGroup>
{
    Task<FieldGroup> CreateFieldGroupAsync(FieldGroup fieldGroup, CancellationToken cancellationToken = default);

    Task<FieldGroup?> GetFieldGroupByIdAsync(Guid groupId, CancellationToken cancellationToken = default);

    Task<FieldGroup> UpdateFieldGroupAsync(FieldGroup fieldGroup, CancellationToken cancellationToken = default);

    Task<bool> DeleteFieldGroupAsync(Guid groupId, CancellationToken cancellationToken = default);

    Task<IEnumerable<FieldGroup>> GetGroupsByUnitTypeIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);
} 