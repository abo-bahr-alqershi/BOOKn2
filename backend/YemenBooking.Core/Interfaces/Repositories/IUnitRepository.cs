using System.Linq.Expressions;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع الوحدات
/// Unit repository interface
/// </summary>
public interface IUnitRepository : IRepository<Unit>
{
    /// <summary>
    /// إنشاء وحدة جديدة
    /// Create new unit
    /// </summary>
    Task<Unit> CreateUnitAsync(Unit unit, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على وحدة بواسطة المعرف
    /// Get unit by id
    /// </summary>
    Task<Unit?> GetUnitByIdAsync(Guid unitId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على وحدة مع البيانات المرتبطة
    /// Get unit by id with related data (dynamic fields, pricing, availability)
    /// </summary>
    Task<Unit?> GetByIdWithRelatedDataAsync(Guid unitId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث الوحدة
    /// Update unit
    /// </summary>
    Task<Unit> UpdateUnitAsync(Unit unit, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف الوحدة
    /// Delete unit
    /// </summary>
    Task<bool> DeleteUnitAsync(Guid unitId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على وحدات الكيان
    /// Get units by property
    /// </summary>
    Task<IEnumerable<Unit>> GetUnitsByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الوحدات المتاحة
    /// Get available units
    /// </summary>
    Task<IEnumerable<Unit>> GetAvailableUnitsAsync(
        Guid propertyId,
        DateTime checkIn,
        DateTime checkOut,
        int guestCount,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الوحدات حسب النوع
    /// Get units by type
    /// </summary>
    Task<IEnumerable<Unit>> GetUnitsByTypeAsync(Guid unitTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الوحدات المتاحة (نشطة) لعقار معين
    /// Get active (available) units for a property
    /// </summary>
    Task<IEnumerable<Unit>> GetActiveByPropertyIdAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيان بواسطة المعرف
    /// Get property by id
    /// </summary>
    Task<Property?> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على نوع الوحدة بواسطة المعرف
    /// Get unit type by id
    /// </summary>
    Task<UnitType?> GetUnitTypeByIdAsync(Guid unitTypeId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث توفر الوحدة
    /// Update availability
    /// </summary>
    Task<bool> UpdateAvailabilityAsync(
        Guid unitId,
        DateTime fromDate,
        DateTime toDate,
        bool isAvailable,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود حجوزات نشطة
    /// Check active bookings
    /// </summary>
    Task<bool> CheckActiveBookingsAsync(Guid unitId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود أي حجوزات للوحدة (بغض النظر عن الحالة)
    /// Check if the unit has any bookings regardless of status
    /// </summary>
    Task<bool> HasAnyBookingsAsync(Guid unitId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود أي مدفوعات مرتبطة بحجوزات هذه الوحدة (حتى وإن كانت مستردة)
    /// Check if there are any payments associated with bookings of this unit (including refunded)
    /// </summary>
    Task<bool> HasAnyPaymentsAsync(Guid unitId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على توفر الوحدة
    /// Get unit availability
    /// </summary>
    Task<IDictionary<DateTime, bool>> GetUnitAvailabilityAsync(
        Guid unitId,
        DateTime fromDate,
        DateTime toDate,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الوحدة مع البيانات المرتبطة
    /// Get unit by id with includes
    /// </summary>
    Task<Unit> GetByIdWithIncludesAsync(Guid id, params Expression<Func<Unit, object>>[] includes);

    /// <summary>
    /// الحصول على الوحدة مع نوع الوحدة
    /// Get unit by id with unit type
    /// </summary>
    Task<Unit> GetByIdWithUnitTypeAsync(Guid id);
}
