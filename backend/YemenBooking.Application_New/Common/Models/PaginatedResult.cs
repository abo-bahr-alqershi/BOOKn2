namespace YemenBooking.Application.Common.Models;

/// <summary>
/// نتيجة مرقمة
/// Paginated result
/// </summary>
/// <typeparam name="T">نوع البيانات</typeparam>
public class PaginatedResult<T>
{
    /// <summary>
    /// البيانات
    /// Data items
    /// </summary>
    public IEnumerable<T> Items { get; set; } = new List<T>();
    
    /// <summary>
    /// رقم الصفحة الحالية
    /// Current page number
    /// </summary>
    public int PageNumber { get; set; }
    
    /// <summary>
    /// حجم الصفحة
    /// Page size
    /// </summary>
    public int PageSize { get; set; }
    
    /// <summary>
    /// إجمالي عدد العناصر
    /// Total count
    /// </summary>
    public int TotalCount { get; set; }
    
    /// <summary>
    /// إجمالي عدد الصفحات
    /// Total pages
    /// </summary>
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
    
    /// <summary>
    /// هل يوجد صفحة سابقة
    /// Has previous page
    /// </summary>
    public bool HasPreviousPage => PageNumber > 1;
    
    /// <summary>
    /// هل يوجد صفحة تالية
    /// Has next page
    /// </summary>
    public bool HasNextPage => PageNumber < TotalPages;
    
    /// <summary>
    /// رقم الصفحة السابقة
    /// Previous page number
    /// </summary>
    public int? PreviousPageNumber => HasPreviousPage ? PageNumber - 1 : null;
    
    /// <summary>
    /// رقم الصفحة التالية
    /// Next page number
    /// </summary>
    public int? NextPageNumber => HasNextPage ? PageNumber + 1 : null;
    
    /// <summary>
    /// مؤشر البداية
    /// Start index
    /// </summary>
    public int StartIndex => (PageNumber - 1) * PageSize + 1;
    
    /// <summary>
    /// مؤشر النهاية
    /// End index
    /// </summary>
    public int EndIndex => Math.Min(StartIndex + PageSize - 1, TotalCount);
    
    /// <summary>
    /// معلومات إضافية
    /// Additional information
    /// </summary>
    public object? Metadata { get; set; }
    
    public PaginatedResult()
    {
    }
    
    public PaginatedResult(IEnumerable<T> items, int pageNumber, int pageSize, int totalCount)
    {
        Items = items;
        PageNumber = pageNumber;
        PageSize = pageSize;
        TotalCount = totalCount;
    }
    
    /// <summary>
    /// إنشاء نتيجة مرقمة
    /// Create paginated result
    /// </summary>
    public static PaginatedResult<T> Create(IEnumerable<T> items, int pageNumber, int pageSize, int totalCount)
    {
        return new PaginatedResult<T>(items, pageNumber, pageSize, totalCount);
    }
    
    /// <summary>
    /// إنشاء نتيجة فارغة
    /// Create empty result
    /// </summary>
    public static PaginatedResult<T> Empty(int pageNumber = 1, int pageSize = 10)
    {
        return new PaginatedResult<T>(new List<T>(), pageNumber, pageSize, 0);
    }
}