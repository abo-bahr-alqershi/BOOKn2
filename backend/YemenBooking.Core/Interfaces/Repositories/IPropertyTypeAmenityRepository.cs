using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع مرافق أنواع الكيانات
/// Property type amenity repository interface
/// </summary>
public interface IPropertyTypeAmenityRepository : IRepository<PropertyTypeAmenity>
{
    /// <summary>
    /// تخصيص مرفق لنوع الكيان
    /// Assign amenity to property type
    /// </summary>
    Task<PropertyTypeAmenity> AssignAmenityToPropertyTypeAsync(PropertyTypeAmenity propertyTypeAmenity, CancellationToken cancellationToken = default);

    /// <summary>
    /// إزالة مرفق من نوع الكيان
    /// Remove amenity from property type
    /// </summary>
    Task<bool> RemoveAmenityFromPropertyTypeAsync(Guid propertyTypeId, Guid amenityId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مرافق نوع الكيان
    /// Get amenities by property type
    /// </summary>
    Task<IEnumerable<PropertyTypeAmenity>> GetAmenitiesByPropertyTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على أنواع الكيانات للمرفق
    /// Get property types by amenity
    /// </summary>
    Task<IEnumerable<PropertyTypeAmenity>> GetPropertyTypesByAmenityAsync(Guid amenityId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود مرفق في نوع الكيان
    /// Check if amenity exists in property type
    /// </summary>
    Task<bool> PropertyTypeHasAmenityAsync(Guid propertyTypeId, Guid amenityId, CancellationToken cancellationToken = default);
}
