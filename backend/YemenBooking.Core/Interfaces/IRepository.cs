using System.Linq.Expressions;
using System.Linq;

namespace YemenBooking.Core.Interfaces;

/// <summary>
/// الواجهة الأساسية للمستودعات
/// Base repository interface
/// </summary>
/// <typeparam name="T">نوع الكيان</typeparam>
public interface IRepository<T> where T : class//, IBaseEntity
{
    /// <summary>
    /// الحصول على كيان بالمعرف
    /// Get entity by ID
    /// </summary>
    Task<T?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    
    
    /// <summary>
    /// الحصول على جميع الكيانات
    /// Get all entities
    /// </summary>
    Task<IEnumerable<T>> GetAllAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// البحث بشرط
    /// Find with condition
    /// </summary>
    Task<IEnumerable<T>> FindAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على أول كيان يحقق الشرط
    /// Get first entity matching condition
    /// </summary>
    Task<T?> FirstOrDefaultAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على عدد الكيانات
    /// Get count of entities
    /// </summary>
    Task<int> CountAsync(CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على عدد الكيانات بشرط
    /// Get count of entities with condition
    /// </summary>
    Task<int> CountAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من وجود كيان
    /// Check if entity exists
    /// </summary>
    Task<bool> ExistsAsync(Guid id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// التحقق من وجود كيان بشرط
    /// Check if entity exists with condition
    /// </summary>
    Task<bool> ExistsAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إضافة كيان جديد
    /// Add new entity
    /// </summary>
    Task<T> AddAsync(T entity, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// إضافة عدة كيانات
    /// Add multiple entities
    /// </summary>
    Task AddRangeAsync(IEnumerable<T> entities, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تحديث كيان
    /// Update entity
    /// </summary>
    Task UpdateAsync(T entity, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// تحديث عدة كيانات
    /// Update multiple entities
    /// </summary>
    Task UpdateRangeAsync(IEnumerable<T> entities, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// حذف كيان
    /// Delete entity
    /// </summary>
    Task DeleteAsync(T entity, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// حذف كيان بالمعرف
    /// Delete entity by ID
    /// </summary>
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// حذف عدة كيانات
    /// Delete multiple entities
    /// </summary>
    Task DeleteRangeAsync(IEnumerable<T> entities, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// حذف كيانات بشرط
    /// Delete entities with condition
    /// </summary>
    Task DeleteRangeAsync(Expression<Func<T, bool>> predicate, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على البيانات مع الترقيم
    /// Get paged data
    /// </summary>
    Task<(IEnumerable<T> Items, int TotalCount)> GetPagedAsync(
        int page, 
        int pageSize, 
        Expression<Func<T, bool>>? predicate = null,
        Expression<Func<T, object>>? orderBy = null,
        bool ascending = true,
        CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على البيانات باستخدام المواصفات
    /// Get data using specifications
    /// </summary>
    Task<IEnumerable<T>> GetWithSpecificationAsync(ISpecification<T> specification, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// الحصول على البيانات مع الترقيم باستخدام المواصفات
    /// Get paged data using specifications
    /// </summary>
    Task<(IEnumerable<T> Items, int TotalCount)> GetPagedWithSpecificationAsync(ISpecification<T> specification, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// عد البيانات باستخدام المواصفات
    /// Count data using specifications
    /// </summary>
    Task<int> CountWithSpecificationAsync(ISpecification<T> specification, CancellationToken cancellationToken = default);
    
    /// <summary>
    /// حفظ التغييرات
    /// Save changes
    /// </summary>
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على كائن استعلامي (IQueryable) للكيان
    /// Get queryable collection for advanced querying
    /// </summary>
    IQueryable<T> GetQueryable();
}