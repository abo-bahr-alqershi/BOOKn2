using System.Linq.Expressions;

namespace YemenBooking.Core.Interfaces;

/// <summary>
/// واجهة المواصفات
/// Specification interface
/// </summary>
/// <typeparam name="T">نوع الكيان</typeparam>
public interface ISpecification<T> where T : class
{
    /// <summary>
    /// المعايير
    /// Criteria
    /// </summary>
    Expression<Func<T, bool>>? Criteria { get; }
    
    /// <summary>
    /// التضمينات
    /// Includes
    /// </summary>
    List<Expression<Func<T, object>>> Includes { get; }
    
    /// <summary>
    /// التضمينات النصية
    /// String includes
    /// </summary>
    List<string> IncludeStrings { get; }
    
    /// <summary>
    /// الترتيب حسب
    /// Order by
    /// </summary>
    Expression<Func<T, object>>? OrderBy { get; }
    
    /// <summary>
    /// الترتيب حسب تنازلي
    /// Order by descending
    /// </summary>
    Expression<Func<T, object>>? OrderByDescending { get; }
    
    /// <summary>
    /// المجموعة حسب
    /// Group by
    /// </summary>
    Expression<Func<T, object>>? GroupBy { get; }
    
    /// <summary>
    /// تطبيق الصفحات
    /// Apply paging
    /// </summary>
    bool IsPagingEnabled { get; }
    
    /// <summary>
    /// رقم الصفحة
    /// Page number
    /// </summary>
    int Page { get; }
    
    /// <summary>
    /// حجم الصفحة
    /// Page size
    /// </summary>
    int PageSize { get; }
    
    /// <summary>
    /// عدد العناصر للتخطي
    /// Skip count
    /// </summary>
    int Skip { get; }
    
    /// <summary>
    /// عدد العناصر للأخذ
    /// Take count
    /// </summary>
    int Take { get; }
    
    /// <summary>
    /// تطبيق التتبع
    /// Apply tracking
    /// </summary>
    bool IsAsNoTracking { get; }
    
    /// <summary>
    /// تطبيق التقسيم
    /// Apply splitting
    /// </summary>
    bool IsSplitQuery { get; }
    
    /// <summary>
    /// إضافة تضمين
    /// Add include
    /// </summary>
    /// <param name="includeExpression">تعبير التضمين</param>
    void AddInclude(Expression<Func<T, object>> includeExpression);
    
    /// <summary>
    /// إضافة تضمين نصي
    /// Add string include
    /// </summary>
    /// <param name="includeString">نص التضمين</param>
    void AddInclude(string includeString);
    
    /// <summary>
    /// تطبيق الترتيب
    /// Apply ordering
    /// </summary>
    /// <param name="orderByExpression">تعبير الترتيب</param>
    void ApplyOrderBy(Expression<Func<T, object>> orderByExpression);
    
    /// <summary>
    /// تطبيق الترتيب التنازلي
    /// Apply descending ordering
    /// </summary>
    /// <param name="orderByDescendingExpression">تعبير الترتيب التنازلي</param>
    void ApplyOrderByDescending(Expression<Func<T, object>> orderByDescendingExpression);
    
    /// <summary>
    /// تطبيق التجميع
    /// Apply grouping
    /// </summary>
    /// <param name="groupByExpression">تعبير التجميع</param>
    void ApplyGroupBy(Expression<Func<T, object>> groupByExpression);
    
    /// <summary>
    /// تطبيق الصفحات
    /// Apply paging
    /// </summary>
    /// <param name="page">رقم الصفحة</param>
    /// <param name="pageSize">حجم الصفحة</param>
    void ApplyPaging(int page, int pageSize);
    
    /// <summary>
    /// تطبيق عدم التتبع
    /// Apply no tracking
    /// </summary>
    void ApplyNoTracking();
    
    /// <summary>
    /// تطبيق التقسيم
    /// Apply split query
    /// </summary>
    void ApplySplitQuery();
}

/// <summary>
/// فئة المواصفات الأساسية
/// Base specification class
/// </summary>
/// <typeparam name="T">نوع الكيان</typeparam>
public abstract class BaseSpecification<T> : ISpecification<T> where T : class
{
    /// <summary>
    /// المعايير
    /// Criteria
    /// </summary>
    public Expression<Func<T, bool>>? Criteria { get; private set; }
    
    /// <summary>
    /// التضمينات
    /// Includes
    /// </summary>
    public List<Expression<Func<T, object>>> Includes { get; } = new();
    
    /// <summary>
    /// التضمينات النصية
    /// String includes
    /// </summary>
    public List<string> IncludeStrings { get; } = new();
    
    /// <summary>
    /// الترتيب حسب
    /// Order by
    /// </summary>
    public Expression<Func<T, object>>? OrderBy { get; private set; }
    
    /// <summary>
    /// الترتيب حسب تنازلي
    /// Order by descending
    /// </summary>
    public Expression<Func<T, object>>? OrderByDescending { get; private set; }
    
    /// <summary>
    /// المجموعة حسب
    /// Group by
    /// </summary>
    public Expression<Func<T, object>>? GroupBy { get; private set; }
    
    /// <summary>
    /// تطبيق الصفحات
    /// Apply paging
    /// </summary>
    public bool IsPagingEnabled { get; private set; }
    
    /// <summary>
    /// رقم الصفحة
    /// Page number
    /// </summary>
    public int Page { get; private set; }
    
    /// <summary>
    /// حجم الصفحة
    /// Page size
    /// </summary>
    public int PageSize { get; private set; }
    
    /// <summary>
    /// عدد العناصر للتخطي
    /// Skip count
    /// </summary>
    public int Skip => (Page - 1) * PageSize;
    
    /// <summary>
    /// عدد العناصر للأخذ
    /// Take count
    /// </summary>
    public int Take => PageSize;
    
    /// <summary>
    /// تطبيق التتبع
    /// Apply tracking
    /// </summary>
    public bool IsAsNoTracking { get; private set; }
    
    /// <summary>
    /// تطبيق التقسيم
    /// Apply splitting
    /// </summary>
    public bool IsSplitQuery { get; private set; }
    
    /// <summary>
    /// المنشئ
    /// Constructor
    /// </summary>
    protected BaseSpecification()
    {
    }
    
    /// <summary>
    /// المنشئ مع المعايير
    /// Constructor with criteria
    /// </summary>
    /// <param name="criteria">المعايير</param>
    protected BaseSpecification(Expression<Func<T, bool>> criteria)
    {
        Criteria = criteria;
    }
    
    /// <summary>
    /// إضافة تضمين
    /// Add include
    /// </summary>
    /// <param name="includeExpression">تعبير التضمين</param>
    public void AddInclude(Expression<Func<T, object>> includeExpression)
    {
        Includes.Add(includeExpression);
    }
    
    /// <summary>
    /// إضافة تضمين نصي
    /// Add string include
    /// </summary>
    /// <param name="includeString">نص التضمين</param>
    public void AddInclude(string includeString)
    {
        IncludeStrings.Add(includeString);
    }
    
    /// <summary>
    /// تطبيق الترتيب
    /// Apply ordering
    /// </summary>
    /// <param name="orderByExpression">تعبير الترتيب</param>
    public void ApplyOrderBy(Expression<Func<T, object>> orderByExpression)
    {
        OrderBy = orderByExpression;
    }
    
    /// <summary>
    /// تطبيق الترتيب التنازلي
    /// Apply descending ordering
    /// </summary>
    /// <param name="orderByDescendingExpression">تعبير الترتيب التنازلي</param>
    public void ApplyOrderByDescending(Expression<Func<T, object>> orderByDescendingExpression)
    {
        OrderByDescending = orderByDescendingExpression;
    }
    
    /// <summary>
    /// تطبيق التجميع
    /// Apply grouping
    /// </summary>
    /// <param name="groupByExpression">تعبير التجميع</param>
    public void ApplyGroupBy(Expression<Func<T, object>> groupByExpression)
    {
        GroupBy = groupByExpression;
    }
    
    /// <summary>
    /// تطبيق الصفحات
    /// Apply paging
    /// </summary>
    /// <param name="page">رقم الصفحة</param>
    /// <param name="pageSize">حجم الصفحة</param>
    public void ApplyPaging(int page, int pageSize)
    {
        Page = page;
        PageSize = pageSize;
        IsPagingEnabled = true;
    }
    
    /// <summary>
    /// تطبيق عدم التتبع
    /// Apply no tracking
    /// </summary>
    public void ApplyNoTracking()
    {
        IsAsNoTracking = true;
    }
    
    /// <summary>
    /// تطبيق التقسيم
    /// Apply split query
    /// </summary>
    public void ApplySplitQuery()
    {
        IsSplitQuery = true;
    }
}