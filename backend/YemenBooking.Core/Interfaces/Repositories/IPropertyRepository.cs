using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع الكيانات
/// Property repository interface
/// </summary>
public interface IPropertyRepository : IRepository<Property>
{
    /// <summary>
    /// إنشاء كيان جديد
    /// Create new property
    /// </summary>
    Task<Property> CreatePropertyAsync(Property property, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على كيان بواسطة المعرف
    /// Get property by id
    /// </summary>
    Task<Property?> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيان مع الوحدات
    /// Get property with units
    /// </summary>
    Task<Property?> GetPropertyWithUnitsAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيان مع المرافق
    /// Get property with amenities
    /// </summary>
    Task<Property?> GetPropertyWithAmenitiesAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث الكيان
    /// Update property
    /// </summary>
    Task<Property> UpdatePropertyAsync(Property property, CancellationToken cancellationToken = default);

    /// <summary>
    /// الموافقة على الكيان
    /// Approve property
    /// </summary>
    Task<bool> ApprovePropertyAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// رفض الكيان
    /// Reject property
    /// </summary>
    Task<bool> RejectPropertyAsync(Guid propertyId, string reason, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف الكيان
    /// Delete property
    /// </summary>
    Task<bool> DeletePropertyAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على كيانات المالك
    /// Get properties by owner
    /// </summary>
    Task<IEnumerable<Property>> GetPropertiesByOwnerAsync(Guid ownerId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيانات حسب النوع
    /// Get properties by type
    /// </summary>
    Task<IEnumerable<Property>> GetPropertiesByTypeAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيانات حسب المدينة
    /// Get properties by city
    /// </summary>
    Task<IEnumerable<Property>> GetPropertiesByCityAsync(string city, CancellationToken cancellationToken = default);

    /// <summary>
    /// البحث عن الكيانات
    /// Search properties
    /// </summary>
    Task<IEnumerable<Property>> SearchPropertiesAsync(string searchTerm, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيانات القريبة من موقع
    /// Get properties near location
    /// </summary>
    Task<IEnumerable<Property>> GetPropertiesNearLocationAsync(
        double latitude,
        double longitude,
        double radiusKm,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيانات المعلقة
    /// Get pending properties
    /// </summary>
    Task<IEnumerable<Property>> GetPendingPropertiesAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيانات الشائعة
    /// Get popular destinations
    /// </summary>
    Task<IEnumerable<Property>> GetPopularDestinationsAsync(int count, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيانات المقترحة
    /// Get recommended properties
    /// </summary>
    Task<IEnumerable<Property>> GetRecommendedPropertiesAsync(
        Guid userId,
        int count,
        CancellationToken cancellationToken = default);
        
            /// <summary>
    /// الحصول على المالك بواسطة المعرف
    /// Get owner by id
    /// </summary>
    Task<User?> GetOwnerByIdAsync(Guid ownerId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على نوع الكيان بواسطة المعرف
    /// Get property type by id
    /// </summary>
    Task<PropertyType?> GetPropertyTypeByIdAsync(Guid propertyTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود حجوزات نشطة
    /// Check active bookings
    /// </summary>
    Task<bool> CheckActiveBookingsAsync(Guid propertyId, CancellationToken cancellationToken = default);
    /// <summary>
    /// الحصول على عدد الحجوزات للعقار
    /// Get total booking count for a property
    /// </summary>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد الحجوزات</returns>
    Task<int> GetPropertyBookingCountAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// عدد الوحدات المرتبطة بالعقار
    /// Units count for the property
    /// </summary>
    Task<int> GetUnitsCountAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// عدد الخدمات المرتبطة بالعقار
    /// Services count for the property
    /// </summary>
    Task<int> GetServicesCountAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// عدد المرافق المرتبطة بالعقار
    /// Amenities count for the property
    /// </summary>
    Task<int> GetAmenitiesCountAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// عدد المدفوعات المرتبطة بحجوزات هذا العقار
    /// Payments count for bookings of this property
    /// </summary>
    Task<int> GetPaymentsCountAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مرافق الكيان
    /// Get property amenities
    /// </summary>
    Task<IEnumerable<PropertyAmenity>> GetPropertyAmenitiesAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث مرافق الكيان
    /// Update property amenity
    /// </summary>
    Task<bool> UpdatePropertyAmenityAsync(
        Guid propertyId, 
        Guid amenityId, 
        bool isAvailable, 
        decimal? additionalCost = null, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// حساب مؤشرات أداء الكيان
    /// Calculate property performance metrics
    /// </summary>
    Task<object> CalculatePerformanceMetricsAsync(
        Guid propertyId, 
        DateTime fromDate, 
        DateTime toDate, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على أفضل الكيانات أداء وفق عدد الحجوزات
    /// Get top performing properties by booking count
    /// </summary>
    Task<IEnumerable<Property>> GetTopPerformingPropertiesAsync(int count, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على سياسة الإلغاء للكيان
    /// Get cancellation policy for a property
    /// </summary>
    Task<PropertyPolicy?> GetCancellationPolicyAsync(Guid propertyId, CancellationToken cancellationToken = default);
}
