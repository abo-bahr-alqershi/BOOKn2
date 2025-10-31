using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع خدمات الكيانات
/// Property service repository interface
/// </summary>
public interface IPropertyServiceRepository : IRepository<PropertyService>
{
    /// <summary>
    /// إنشاء خدمة كيان جديدة
    /// Create new property service
    /// </summary>
    Task<PropertyService> CreatePropertyServiceAsync(PropertyService propertyService, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على خدمة الكيان بواسطة المعرف
    /// Get property service by id
    /// </summary>
    Task<PropertyService?> GetPropertyServiceByIdAsync(Guid propertyServiceId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على خدمة بواسطة المعرف
    /// Get service by id
    /// </summary>
    Task<PropertyService?> GetServiceByIdAsync(Guid serviceId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث خدمة الكيان
    /// Update property service
    /// </summary>
    Task<PropertyService> UpdatePropertyServiceAsync(PropertyService propertyService, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف خدمة الكيان
    /// Delete property service
    /// </summary>
    Task<bool> DeletePropertyServiceAsync(Guid propertyServiceId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على خدمات الكيان
    /// Get property services
    /// </summary>
    Task<IEnumerable<PropertyService>> GetPropertyServicesAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الخدمات حسب النوع
    /// Get services by type
    /// </summary>
    Task<IEnumerable<PropertyService>> GetServicesByTypeAsync(string serviceType, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيان بواسطة المعرف
    /// Get property by id
    /// </summary>
    Task<Property?> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود مراجع للحجوزات تستخدم هذه الخدمة
    /// Check if any booking references this service
    /// </summary>
    Task<bool> ServiceHasBookingReferencesAsync(Guid serviceId, CancellationToken cancellationToken = default);

}
