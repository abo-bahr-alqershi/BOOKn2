using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع أنواع الكيانات
/// Property type repository interface
/// </summary>
public interface IPropertyTypeRepository : IRepository<PropertyType>
{
    /// <summary>
    /// إنشاء نوع كيان جديد
    /// Create new property type
    /// </summary>
    Task<PropertyType> CreatePropertyTypeAsync(PropertyType propertyType, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على نوع الكيان بواسطة المعرف
    /// Get property type by id
    /// </summary>
    Task<PropertyType?> GetPropertyTypeByIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على جميع أنواع الكيانات
    /// Get all property types
    /// </summary>
    Task<IEnumerable<PropertyType>> GetAllPropertyTypesAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على نوع الكيان مع المرافق
    /// Get property type with amenities
    /// </summary>
    Task<PropertyType?> GetPropertyTypeWithAmenitiesAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث نوع الكيان
    /// Update property type
    /// </summary>
    Task<PropertyType> UpdatePropertyTypeAsync(PropertyType propertyType, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف نوع الكيان
    /// Delete property type
    /// </summary>
    Task<bool> DeletePropertyTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);
}
