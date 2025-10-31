using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Users.Queries.GetAllUsers;

/// <summary>
/// استعلام للحصول على جميع المستخدمين
/// Query to get all users
/// </summary>
public class GetAllUsersQuery : IRequest<PaginatedResult<object>>
{
    /// <summary>
    /// رقم الصفحة
    /// Page number
    /// </summary>
    public int PageNumber { get; set; } = 1;

    /// <summary>
    /// حجم الصفحة
    /// Page size
    /// </summary>
    public int PageSize { get; set; } = 10;

    /// <summary>
    /// مصطلح البحث (اختياري)
    /// Search term (optional)
    /// </summary>
    public string? SearchTerm { get; set; }

    /// <summary>
    /// نوع الترتيب (اختياري)
    /// Sort type (optional)
    /// </summary>
    public string? SortBy { get; set; }

    /// <summary>
    /// ترتيب تصاعدي أو تنازلي (افتراضي: تصاعدي)
    /// Ascending or descending order (default: ascending)
    /// </summary>
    public bool IsAscending { get; set; } = true;

    /// <summary>
    /// فلترة بالدور (اختياري)
    /// Role filter (optional)
    /// </summary>
    public Guid? RoleId { get; set; }

    /// <summary>
    /// فلترة باسم الدور المنطقي (Admin, Owner, Staff, Customer) - اختياري
    /// Logical role name filter (Admin, Owner, Staff, Customer) - optional
    /// </summary>
    public string? RoleName { get; set; }

    /// <summary>
    /// فلترة بالحالة النشطة (اختياري)
    /// Active status filter (optional)
    /// </summary>
    public bool? IsActive { get; set; }

    /// <summary>
    /// فلترة بتاريخ التسجيل بعد (اختياري)
    /// Filter by registration date after (optional)
    /// </summary>
    public DateTime? CreatedAfter { get; set; }

    /// <summary>
    /// فلترة بتاريخ التسجيل قبل (اختياري)
    /// Filter by registration date before (optional)
    /// </summary>
    public DateTime? CreatedBefore { get; set; }

    /// <summary>
    /// فلترة بالنشاط الأخير بعد (اختياري)
    /// Filter by last login after (optional)
    /// </summary>
    public DateTime? LastLoginAfter { get; set; }

    /// <summary>
    /// فلترة بفئة الولاء (اختياري)
    /// Loyalty tier filter (optional)
    /// </summary>
    public string? LoyaltyTier { get; set; }

    /// <summary>
    /// فلترة بالإنفاق الأدنى (اختياري)
    /// Filter by minimum total spent (optional)
    /// </summary>
    public decimal? MinTotalSpent { get; set; }
}