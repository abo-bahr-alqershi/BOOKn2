using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع أنواع الوحدات
/// Unit type repository interface
/// </summary>
public interface IUnitTypeRepository : IRepository<UnitType>
{
    /// <summary>
    /// إنشاء نوع وحدة جديد
    /// Create new unit type
    /// </summary>
    Task<UnitType> CreateUnitTypeAsync(UnitType unitType, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على نوع الوحدة بواسطة المعرف
    /// Get unit type by id
    /// </summary>
    Task<UnitType?> GetUnitTypeByIdAsync(Guid unitTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على أنواع الوحدات حسب نوع الكيان
    /// Get unit types by property type
    /// </summary>
    Task<IEnumerable<UnitType>> GetUnitTypesByPropertyTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على جميع أنواع الوحدات
    /// Get all unit types
    /// </summary>
    Task<IEnumerable<UnitType>> GetAllUnitTypesAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث نوع الوحدة
    /// Update unit type
    /// </summary>
    Task<UnitType> UpdateUnitTypeAsync(UnitType unitType, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف نوع الوحدة
    /// Delete unit type
    /// </summary>
    Task<bool> DeleteUnitTypeAsync(Guid unitTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على نوع الكيان بواسطة المعرف
    /// Get property type by id
    /// </summary>
    Task<PropertyType?> GetPropertyTypeByIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على أنواع الوحدات حسب معرف نوع العقار
    /// Get unit types by property type ID
    /// </summary>
    Task<IEnumerable<UnitType>> GetByPropertyTypeIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

}
