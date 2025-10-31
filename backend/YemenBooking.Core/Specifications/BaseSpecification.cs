using System.Linq.Expressions;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Core.Specifications;

/// <summary>
/// فئة المواصفات الأساسية
/// Base specification class
/// </summary>
/// <typeparam name="T">نوع الكيان</typeparam>
public abstract class BaseSpecification<T> : ISpecification<T> where T : class
{
    protected BaseSpecification()
    {
        Includes = new List<Expression<Func<T, object>>>();
        IncludeStrings = new List<string>();
    }

    protected BaseSpecification(Expression<Func<T, bool>> criteria) : this()
    {
        Criteria = criteria;
    }

    /// <summary>
    /// المعايير
    /// Criteria
    /// </summary>
    public Expression<Func<T, bool>>? Criteria { get; private set; }

    /// <summary>
    /// التضمينات
    /// Includes
    /// </summary>
    public List<Expression<Func<T, object>>> Includes { get; private set; }

    /// <summary>
    /// التضمينات النصية
    /// String includes
    /// </summary>
    public List<string> IncludeStrings { get; private set; }

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
    public int Skip { get; private set; }

    /// <summary>
    /// عدد العناصر للأخذ
    /// Take count
    /// </summary>
    public int Take { get; private set; }

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
    /// إضافة تضمين
    /// Add include
    /// </summary>
    /// <param name="includeExpression">تعبير التضمين</param>
    public virtual void AddInclude(Expression<Func<T, object>> includeExpression)
    {
        Includes.Add(includeExpression);
    }

    /// <summary>
    /// إضافة تضمين نصي
    /// Add string include
    /// </summary>
    /// <param name="includeString">نص التضمين</param>
    public virtual void AddInclude(string includeString)
    {
        IncludeStrings.Add(includeString);
    }

    /// <summary>
    /// إضافة ترتيب تصاعدي
    /// Add ascending order
    /// </summary>
    /// <param name="orderByExpression">تعبير الترتيب</param>
    public virtual void ApplyOrderBy(Expression<Func<T, object>> orderByExpression)
    {
        OrderBy = orderByExpression;
    }

    /// <summary>
    /// إضافة ترتيب تنازلي
    /// Add descending order
    /// </summary>
    /// <param name="orderByDescendingExpression">تعبير الترتيب التنازلي</param>
    public virtual void ApplyOrderByDescending(Expression<Func<T, object>> orderByDescendingExpression)
    {
        OrderByDescending = orderByDescendingExpression;
    }

    /// <summary>
    /// إضافة تجميع
    /// Add grouping
    /// </summary>
    /// <param name="groupByExpression">تعبير التجميع</param>
    public virtual void ApplyGroupBy(Expression<Func<T, object>> groupByExpression)
    {
        GroupBy = groupByExpression;
    }

    /// <summary>
    /// تطبيق التصفح
    /// Apply paging
    /// </summary>
    /// <param name="page">رقم الصفحة</param>
    /// <param name="pageSize">حجم الصفحة</param>
    public virtual void ApplyPaging(int page, int pageSize)
    {
        Page = page;
        PageSize = pageSize;
        IsPagingEnabled = true;
        Skip = (page - 1) * pageSize;
        Take = pageSize;
    }

    /// <summary>
    /// تطبيق عدم التتبع
    /// Apply no tracking
    /// </summary>
    public virtual void ApplyNoTracking()
    {
        IsAsNoTracking = true;
    }

    /// <summary>
    /// تطبيق التقسيم
    /// Apply split query
    /// </summary>
    public virtual void ApplySplitQuery()
    {
        IsSplitQuery = true;
    }

    /// <summary>
    /// إضافة معايير إضافية
    /// Add additional criteria
    /// </summary>
    /// <param name="criteria">المعايير</param>
    protected virtual void AddCriteria(Expression<Func<T, bool>> criteria)
    {
        if (Criteria == null)
        {
            Criteria = criteria;
        }
        else
        {
            // دمج المعايير باستخدام AND
            // Combine criteria using AND
            var parameter = Expression.Parameter(typeof(T));
            var left = ReplaceParameter(Criteria, parameter);
            var right = ReplaceParameter(criteria, parameter);
            var combined = Expression.AndAlso(left, right);
            Criteria = Expression.Lambda<Func<T, bool>>(combined, parameter);
        }
    }

    /// <summary>
    /// إضافة معايير باستخدام OR
    /// Add criteria using OR
    /// </summary>
    /// <param name="criteria">المعايير</param>
    protected virtual void AddOrCriteria(Expression<Func<T, bool>> criteria)
    {
        if (Criteria == null)
        {
            Criteria = criteria;
        }
        else
        {
            // دمج المعايير باستخدام OR
            // Combine criteria using OR
            var parameter = Expression.Parameter(typeof(T));
            var left = ReplaceParameter(Criteria, parameter);
            var right = ReplaceParameter(criteria, parameter);
            var combined = Expression.OrElse(left, right);
            Criteria = Expression.Lambda<Func<T, bool>>(combined, parameter);
        }
    }

    /// <summary>
    /// استبدال المعامل في التعبير
    /// Replace parameter in expression
    /// </summary>
    private Expression ReplaceParameter(Expression<Func<T, bool>> expression, ParameterExpression parameter)
    {
        return new ParameterReplacer(expression.Parameters[0], parameter).Visit(expression.Body);
    }

    /// <summary>
    /// مستبدل المعامل
    /// Parameter replacer
    /// </summary>
    private class ParameterReplacer : ExpressionVisitor
    {
        private readonly ParameterExpression _oldParameter;
        private readonly ParameterExpression _newParameter;

        public ParameterReplacer(ParameterExpression oldParameter, ParameterExpression newParameter)
        {
            _oldParameter = oldParameter;
            _newParameter = newParameter;
        }

        protected override Expression VisitParameter(ParameterExpression node)
        {
            return node == _oldParameter ? _newParameter : base.VisitParameter(node);
        }
    }
}
