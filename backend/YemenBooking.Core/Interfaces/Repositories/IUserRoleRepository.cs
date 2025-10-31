using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع أدوار المستخدمين
/// User role repository interface
/// </summary>
public interface IUserRoleRepository : IRepository<UserRole>
{
    /// <summary>
    /// تخصيص دور للمستخدم
    /// Assign role to user
    /// </summary>
    Task<UserRole> AssignRoleToUserAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default);

    /// <summary>
    /// إزالة دور من المستخدم
    /// Remove role from user
    /// </summary>
    Task<bool> RemoveRoleFromUserAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على أدوار المستخدم
    /// Get user roles
    /// </summary>
    Task<IEnumerable<UserRole>> GetUserRolesAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود دور للمستخدم
    /// Check if user has role
    /// </summary>
    Task<bool> UserHasRoleAsync(Guid userId, Guid roleId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على المستخدمين في دور معين
    /// Get users in role
    /// </summary>
    Task<IEnumerable<UserRole>> GetUsersInRoleAsync(Guid roleId, CancellationToken cancellationToken = default);
}
