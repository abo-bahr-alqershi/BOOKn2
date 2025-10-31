using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع المفضلات
/// Favorite repository interface
/// </summary>
public interface IFavoriteRepository
{
    /// <summary>
    /// الحصول على مفضلات المستخدم
    /// Get all favorites for a user
    /// </summary>
    Task<IEnumerable<Favorite>> GetByUserIdAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مفضلات المستخدم مع التصفح
    /// Get user favorites with pagination
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="pageNumber">رقم الصفحة</param>
    /// <param name="pageSize">حجم الصفحة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة المفضلات</returns>
    Task<(IEnumerable<Favorite> Items, int TotalCount)> GetUserFavoritesAsync(
        Guid userId, 
        int pageNumber = 1, 
        int pageSize = 10, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مفضلة حسب المعرف
    /// Get favorite by ID
    /// </summary>
    /// <param name="id">معرف المفضلة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>المفضلة</returns>
    Task<Favorite?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود مفضلة للمستخدم والعقار
    /// Check if favorite exists for user and property
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>true إذا كانت المفضلة موجودة</returns>
    Task<bool> ExistsAsync(Guid userId, Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// إضافة مفضلة جديدة
    /// Add new favorite
    /// </summary>
    /// <param name="favorite">المفضلة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>المفضلة المضافة</returns>
    Task<Favorite> AddAsync(Favorite favorite, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف مفضلة
    /// Delete favorite
    /// </summary>
    /// <param name="id">معرف المفضلة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة الحذف</returns>
    Task<bool> DeleteAsync(Guid id, CancellationToken cancellationToken = default);

    /// <summary>
    /// حذف مفضلة حسب المستخدم والعقار
    /// Delete favorite by user and property
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="propertyId">معرف العقار</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>نتيجة الحذف</returns>
    Task<bool> DeleteByUserAndPropertyAsync(Guid userId, Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// عدد مفضلات المستخدم
    /// Count user favorites
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>عدد المفضلات</returns>
    Task<int> CountUserFavoritesAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على أكثر العقارات إضافة للمفضلات
    /// Get most favorited properties
    /// </summary>
    /// <param name="limit">عدد العقارات</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة العقارات الأكثر إضافة للمفضلات</returns>
    Task<IEnumerable<(Guid PropertyId, int FavoriteCount)>> GetMostFavoritedPropertiesAsync(
        int limit = 10, 
        CancellationToken cancellationToken = default);
}
