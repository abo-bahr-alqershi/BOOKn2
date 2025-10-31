using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع مرافق الكيانات
/// Property amenity repository interface
/// </summary>
public interface IPropertyAmenityRepository : IRepository<PropertyAmenity>
{
    /// <summary>
    /// تحديث مرفق الكيان
    /// Update property amenity
    /// </summary>
    Task<PropertyAmenity> UpdatePropertyAmenityAsync(PropertyAmenity propertyAmenity, CancellationToken cancellationToken = default);

    /// <summary>
    /// إضافة مرفق للكيان
    /// Add amenity to property
    /// </summary>
    Task<PropertyAmenity> AddAmenityToPropertyAsync(PropertyAmenity propertyAmenity, CancellationToken cancellationToken = default);

    /// <summary>
    /// إزالة مرفق من الكيان
    /// Remove amenity from property
    /// </summary>
    Task<bool> RemoveAmenityFromPropertyAsync(Guid propertyId, Guid amenityId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مرافق الكيان
    /// Get property amenities
    /// </summary>
    Task<IEnumerable<PropertyAmenity>> GetPropertyAmenitiesAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مرافق الكيان حسب الكيان
    /// Get amenities by property
    /// </summary>
    Task<IEnumerable<PropertyAmenity>> GetAmenitiesByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default);
}
