using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع الأدوار
/// Role repository interface
/// </summary>
public interface IRoleRepository : IRepository<Role>
{
    /// <summary>
    /// الحصول على الدور بواسطة المعرف
    /// Get role by id
    /// </summary>
    Task<Role?> GetRoleByIdAsync(Guid roleId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على جميع الأدوار
    /// Get all roles
    /// </summary>
    Task<IEnumerable<Role>> GetAllRolesAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// إنشاء دور جديد
    /// Create new role
    /// </summary>
    Task<Role> CreateRoleAsync(Role role, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث الدور
    /// Update role
    /// </summary>
    Task<Role> UpdateRoleAsync(Role role, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف الدور
    /// Delete role
    /// </summary>
    Task<bool> DeleteRoleAsync(Guid roleId, CancellationToken cancellationToken = default);

        /// <summary>
    /// تخصيص دور للمستخدم
    /// Assign role to user
    /// </summary>
    Task<bool> AssignRoleToUserAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default);

    /// <summary>
    /// إزالة دور من المستخدم
    /// Remove role from user
    /// </summary>
    Task<bool> RemoveRoleFromUserAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من صلاحية المستخدم
    /// Check user permission
    /// </summary>
    Task<bool> HasPermissionAsync(Guid userId, string permission, CancellationToken cancellationToken = default);
}
