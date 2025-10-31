using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع الموظفين
/// Staff repository interface
/// </summary>
public interface IStaffRepository : IRepository<Staff>
{
    /// <summary>
    /// إضافة موظف جديد
    /// Add new staff
    /// </summary>
    Task<Staff> AddStaffAsync(Staff staff, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على موظف بواسطة المعرف
    /// Get staff by id
    /// </summary>
    Task<Staff?> GetStaffByIdAsync(Guid staffId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث الموظف
    /// Update staff
    /// </summary>
    Task<Staff> UpdateStaffAsync(Staff staff, CancellationToken cancellationToken = default);

    /// <summary>
    /// إزالة الموظف
    /// Remove staff
    /// </summary>
    Task<bool> RemoveStaffAsync(Guid staffId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على موظفي الكيان
    /// Get staff by property
    /// </summary>
    Task<IEnumerable<Staff>> GetStaffByPropertyAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على بيانات الموظف للمستخدم
    /// Get staff by user
    /// </summary>
    Task<Staff?> GetStaffByUserAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الموظفين حسب المنصب
    /// Get staff by position
    /// </summary>
    Task<IEnumerable<Staff>> GetStaffByPositionAsync(string position, Guid? propertyId = null, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على المستخدم بواسطة المعرف
    /// Get user by id
    /// </summary>
    Task<User?> GetUserByIdAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الكيان بواسطة المعرف
    /// Get property by id
    /// </summary>
    Task<Property?> GetPropertyByIdAsync(Guid propertyId, CancellationToken cancellationToken = default);

}
