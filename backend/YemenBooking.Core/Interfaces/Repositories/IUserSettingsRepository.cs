using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع إعدادات المستخدم
/// User settings repository interface
/// </summary>
public interface IUserSettingsRepository
{
    /// <summary>
    /// الحصول على إعدادات المستخدم حسب معرف المستخدم
    /// Get user settings by user ID
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>إعدادات المستخدم</returns>
    Task<UserSettings?> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على إعدادات المستخدم حسب المعرف
    /// Get user settings by ID
    /// </summary>
    /// <param name="id">معرف الإعدادات</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>إعدادات المستخدم</returns>
    Task<UserSettings?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// إنشاء إعدادات مستخدم جديدة
    /// Create new user settings
    /// </summary>
    /// <param name="userSettings">إعدادات المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>إعدادات المستخدم المنشأة</returns>
    Task<UserSettings> CreateAsync(UserSettings userSettings, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث إعدادات المستخدم
    /// Update user settings
    /// </summary>
    /// <param name="userSettings">إعدادات المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>إعدادات المستخدم المحدثة</returns>
    Task<UserSettings> UpdateAsync(UserSettings userSettings, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف إعدادات المستخدم
    /// Delete user settings
    /// </summary>
    /// <param name="id">معرف الإعدادات</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة الحذف</returns>
    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف إعدادات المستخدم حسب معرف المستخدم
    /// Delete user settings by user ID
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة الحذف</returns>
    Task<bool> DeleteByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود إعدادات للمستخدم
    /// Check if user settings exist
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا كانت الإعدادات موجودة</returns>
    Task<bool> ExistsAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// إنشاء أو تحديث إعدادات المستخدم
    /// Create or update user settings
    /// </summary>
    /// <param name="userSettings">إعدادات المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>إعدادات المستخدم</returns>
    Task<UserSettings> CreateOrUpdateAsync(UserSettings userSettings, CancellationToken cancellationToken = default);
}
