using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع المرافق
/// Amenity repository interface
/// </summary>
public interface IAmenityRepository : IRepository<Amenity>
{
    /// <summary>
    /// إنشاء مرفق جديد
    /// Create new amenity
    /// </summary>
    Task<Amenity> CreateAmenityAsync(Amenity amenity, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مرفق بواسطة المعرف
    /// Get amenity by id
    /// </summary>
    Task<Amenity?> GetAmenityByIdAsync(Guid amenityId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث المرفق
    /// Update amenity
    /// </summary>
    Task<Amenity> UpdateAmenityAsync(Amenity amenity, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف المرفق
    /// Delete amenity
    /// </summary>
    Task<bool> DeleteAmenityAsync(Guid amenityId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على جميع المرافق
    /// Get all amenities
    /// </summary>
    Task<IEnumerable<Amenity>> GetAllAmenitiesAsync(CancellationToken cancellationToken = default);

        /// <summary>
    /// الحصول على نوع الكيان بواسطة المعرف
    /// Get property type by id
    /// </summary>
    Task<PropertyType?> GetPropertyTypeByIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تخصيص مرفق لنوع الكيان
    /// Assign amenity to property type
    /// </summary>
    Task<PropertyTypeAmenity> AssignAmenityToPropertyTypeAsync(
        Guid propertyTypeId, 
        Guid amenityId, 
        bool isDefault = false, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مرافق نوع الكيان
    /// Get amenities by property type
    /// </summary>
    Task<IEnumerable<PropertyTypeAmenity>> GetAmenitiesByPropertyTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مرافق الكيان
    /// Get amenities by property
    /// </summary>
    Task<IEnumerable<PropertyAmenity>> GetAmenitiesByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Retrieves all property-amenity assignments including navigation for filtering
    /// </summary>
    Task<IEnumerable<PropertyAmenity>> GetAllPropertyAmenitiesAsync(CancellationToken cancellationToken = default);
}
