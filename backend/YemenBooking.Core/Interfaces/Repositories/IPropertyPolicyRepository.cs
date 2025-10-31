using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع سياسات العقار
/// Property policy repository interface
/// </summary>
public interface IPropertyPolicyRepository
{
    /// <summary>
    /// الحصول على سياسات العقار حسب معرف العقار
    /// Get property policies by property ID
    /// </summary>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة سياسات العقار</returns>
    Task<IEnumerable<PropertyPolicy>> GetByPropertyIdAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على سياسة العقار حسب المعرف
    /// Get property policy by ID
    /// </summary>
    /// <param name="id">معرف السياسة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>سياسة العقار</returns>
    Task<PropertyPolicy?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// إنشاء سياسة عقار جديدة
    /// Create new property policy
    /// </summary>
    /// <param name="propertyPolicy">سياسة العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>سياسة العقار المنشأة</returns>
    Task<PropertyPolicy> CreateAsync(PropertyPolicy propertyPolicy, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث سياسة العقار
    /// Update property policy
    /// </summary>
    /// <param name="propertyPolicy">سياسة العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>سياسة العقار المحدثة</returns>
    Task<PropertyPolicy> UpdateAsync(PropertyPolicy propertyPolicy, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف سياسة العقار
    /// Delete property policy
    /// </summary>
    /// <param name="id">معرف السياسة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة الحذف</returns>
    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على سياسات العقار حسب النوع
    /// Get property policies by type
    /// </summary>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="policyType">نوع السياسة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة سياسات العقار</returns>
    Task<IEnumerable<PropertyPolicy>> GetByPropertyIdAndTypeAsync(Guid propertyId, string policyType, CancellationToken cancellationToken = default);
}
