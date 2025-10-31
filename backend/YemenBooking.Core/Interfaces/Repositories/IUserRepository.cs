using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// واجهة مستودع المستخدمين
/// User repository interface
/// </summary>
public interface IUserRepository : IRepository<User>
{
    /// <summary>
    /// إنشاء مستخدم جديد
    /// Create new user
    /// </summary>
    Task<User> CreateUserAsync(User user, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مستخدم بواسطة المعرف
    /// Get user by id
    /// </summary>
    Task<User?> GetUserByIdAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مستخدم بواسطة البريد الإلكتروني
    /// Get user by email
    /// </summary>
    Task<User?> GetUserByEmailAsync(string email, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على مستخدم بواسطة الهاتف
    /// Get user by phone number
    /// </summary>
    Task<User?> GetByPhoneAsync(string phone, CancellationToken cancellationToken = default);

    /// <summary>
    /// التحقق من وجود البريد الإلكتروني
    /// Check if email exists
    /// </summary>
    Task<bool> CheckEmailExistsAsync(string email, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث المستخدم
    /// Update user
    /// </summary>
    Task<User> UpdateUserAsync(User user, CancellationToken cancellationToken = default);

    /// <summary>
    /// إلغاء تفعيل المستخدم
    /// Deactivate user
    /// </summary>
    Task<bool> DeactivateUserAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تفعيل المستخدم
    /// Activate user
    /// </summary>
    Task<bool> ActivateUserAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على جميع المستخدمين
    /// Get all users
    /// </summary>
    Task<IEnumerable<User>> GetAllUsersAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على المستخدمين مع الصفحات
    /// Get users with pagination
    /// </summary>
    Task<(IEnumerable<User> Users, int TotalCount)> GetUsersWithPaginationAsync(
        int page,
        int pageSize,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// البحث عن المستخدمين
    /// Search users
    /// </summary>
    Task<IEnumerable<User>> SearchUsersAsync(
        string searchTerm,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على المالك بواسطة المعرف
    /// Get owner by id
    /// </summary>
    Task<User?> GetOwnerByIdAsync(Guid ownerId, CancellationToken cancellationToken = default);
    
        /// <summary>
    /// الحصول على أدوار المستخدم
    /// Get user roles
    /// </summary>
    Task<IEnumerable<UserRole>> GetUserRolesAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحليل تفضيلات المستخدم
    /// Analyze user preferences
    /// </summary>
    Task<object> AnalyzeUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// حساب معدل الاحتفاظ بالعملاء
    /// Calculate customer retention
    /// </summary>
    Task<decimal> CalculateCustomerRetentionAsync(
        DateTime fromDate, 
        DateTime toDate, 
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على المستخدمين حسب شهر التسجيل
    /// Get users by registration month
    /// </summary>
    Task<IEnumerable<User>> GetUsersByRegistrationMonthAsync(int year, int month, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث إعدادات المستخدم
    /// Update user settings JSON
    /// </summary>
    Task<bool> UpdateUserSettingsAsync(Guid userId, string settingsJson, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث قائمة المفضلة للمستخدم
    /// Update user favorites JSON
    /// </summary>
    Task<bool> UpdateUserFavoritesAsync(Guid userId, string favoritesJson, CancellationToken cancellationToken = default);
}
