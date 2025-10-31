namespace YemenBooking.Application.Common.Models;

/// <summary>
/// DTO للنتائج المقسمة على صفحات
/// DTO for paged results
/// </summary>
/// <typeparam name="T">نوع البيانات</typeparam>
public class PagedResultDto<T>
{
    /// <summary>
    /// قائمة البيانات
    /// Data items
    /// </summary>
    public IEnumerable<T> Items { get; set; } = new List<T>();
    
    /// <summary>
    /// العدد الإجمالي للعناصر
    /// Total count of items
    /// </summary>
    public int TotalCount { get; set; }
    
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
    /// إجمالي عدد الصفحات
    /// Total number of pages
    /// </summary>
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / PageSize);
    
    /// <summary>
    /// هل توجد صفحة سابقة
    /// Has previous page
    /// </summary>
    public bool HasPreviousPage => PageNumber > 1;
    
    /// <summary>
    /// هل توجد صفحة تالية
    /// Has next page
    /// </summary>
    public bool HasNextPage => PageNumber < TotalPages;
    
    /// <summary>
    /// عدد العناصر في الصفحة الحالية
    /// Number of items in current page
    /// </summary>
    public int ItemCount => Items.Count();
    
    /// <summary>
    /// رقم أول عنصر في الصفحة
    /// First item number in page
    /// </summary>
    public int FirstItemNumber => TotalCount == 0 ? 0 : (PageNumber - 1) * PageSize + 1;
    
    /// <summary>
    /// رقم آخر عنصر في الصفحة
    /// Last item number in page
    /// </summary>
    public int LastItemNumber => Math.Min(PageNumber * PageSize, TotalCount);
}

/// <summary>
/// معايير الترقيم
/// Pagination parameters
/// </summary>
public class PaginationDto
{
    private int _pageNumber = 1;
    private int _pageSize = 10;
    
    /// <summary>
    /// رقم الصفحة (ابتداءً من 1)
    /// Page number (starting from 1)
    /// </summary>
    public int PageNumber
    {
        get => _pageNumber;
        set => _pageNumber = value < 1 ? 1 : value;
    }
    
    /// <summary>
    /// حجم الصفحة (1-100)
    /// Page size (1-100)
    /// </summary>
    public int PageSize
    {
        get => _pageSize;
        set => _pageSize = value switch
        {
            < 1 => 1,
            > 100 => 100,
            _ => value
        };
    }
    
    /// <summary>
    /// حقل الترتيب
    /// Sort field
    /// </summary>
    public string? SortBy { get; set; }
    
    /// <summary>
    /// اتجاه الترتيب
    /// Sort direction
    /// </summary>
    public bool Ascending { get; set; } = true;
    
    /// <summary>
    /// عدد العناصر المراد تخطيها
    /// Number of items to skip
    /// </summary>
    public int Skip => (PageNumber - 1) * PageSize;
}