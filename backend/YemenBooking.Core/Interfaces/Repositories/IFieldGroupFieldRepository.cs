using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع روابط الحقول والمجموعات
/// FieldGroupField repository interface
/// </summary>
public interface IFieldGroupFieldRepository : IRepository<FieldGroupField>
{
    /// <summary>
    /// ربط حقل بمجموعة
    /// Assign field to group
    /// </summary>
    Task<FieldGroupField> AssignFieldToGroupAsync(FieldGroupField fieldGroupField, CancellationToken cancellationToken = default);

    /// <summary>
    /// إزالة حقل من مجموعة
    /// Remove field from group
    /// </summary>
    Task<bool> RemoveFieldFromGroupAsync(Guid fieldId, Guid groupId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الحقول المرتبطة بمجموعة
    /// Get fields by group
    /// </summary>
    Task<IEnumerable<FieldGroupField>> GetFieldsByGroupIdAsync(Guid groupId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على المجموعات المرتبطة بحقل
    /// Get groups by field
    /// </summary>
    Task<IEnumerable<FieldGroupField>> GetGroupsByFieldIdAsync(Guid fieldId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود ارتباط بين الحقل والمجموعة
    /// Check if field is in group
    /// </summary>
    Task<bool> GroupHasFieldAsync(Guid groupId, Guid fieldId, CancellationToken cancellationToken = default);
} 