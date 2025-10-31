using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع السياسات
/// Policy repository interface
/// </summary>
public interface IPolicyRepository : IRepository<PropertyPolicy>
{
    /// <summary>
    /// إنشاء سياسة كيان جديدة
    /// Create new property policy
    /// </summary>
    Task<PropertyPolicy> CreatePropertyPolicyAsync(PropertyPolicy propertyPolicy, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على سياسة بواسطة المعرف
    /// Get policy by id
    /// </summary>
    Task<PropertyPolicy?> GetPolicyByIdAsync(Guid policyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث سياسة الكيان
    /// Update property policy
    /// </summary>
    Task<PropertyPolicy> UpdatePropertyPolicyAsync(PropertyPolicy propertyPolicy, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف السياسة
    /// Delete policy
    /// </summary>
    Task<bool> DeletePolicyAsync(Guid policyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على سياسات الكيان
    /// Get property policies
    /// </summary>
    Task<IEnumerable<PropertyPolicy>> GetPropertyPoliciesAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على السياسات حسب النوع
    /// Get policies by type
    /// </summary>
    Task<IEnumerable<PropertyPolicy>> GetPoliciesByTypeAsync(string policyType, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيان بواسطة المعرف
    /// Get property by id
    /// </summary>
    Task<Property?> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken = default);

}
