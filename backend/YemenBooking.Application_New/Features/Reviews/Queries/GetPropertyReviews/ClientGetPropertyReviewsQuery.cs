using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Reviews.Queries.GetPropertyReviews;

/// <summary>
/// استعلام جلب مراجعات العقار للعميل
/// Query to get property reviews for client
/// </summary>
public class ClientGetPropertyReviewsQuery : IRequest<ResultDto<PaginatedResult<ClientReviewDto>>>
{
    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }

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
    /// فلتر حسب التقييم
    /// Filter by rating
    /// </summary>
    public int? Rating { get; set; }

    /// <summary>
    /// ترتيب النتائج
    /// Sort order
    /// </summary>
    public string SortBy { get; set; } = "CreatedAt";

    /// <summary>
    /// اتجاه الترتيب
    /// Sort direction
    /// </summary>
    public string SortDirection { get; set; } = "Desc";

    /// <summary>
    /// فلتر حسب الصور فقط
    /// Filter by reviews with images only
    /// </summary>
    public bool WithImagesOnly { get; set; } = false;

    /// <summary>
    /// معرف المستخدم لمعرفة مراجعاته
    /// User ID to identify user's reviews
    /// </summary>
    public Guid? UserId { get; set; }
}

/// <summary>
/// بيانات المراجعة للعميل
/// Client review data
/// </summary>
public class ClientReviewDto
{
    /// <summary>
    /// معرف المراجعة
    /// Review ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// اسم المستخدم
    /// User name
    /// </summary>
    public string UserName { get; set; } = string.Empty;

    /// <summary>
    /// صورة المستخدم
    /// User avatar
    /// </summary>
    public string? UserAvatar { get; set; }

    /// <summary>
    /// التقييم (من 1 إلى 5)
    /// Rating (1 to 5)
    /// </summary>
    public int Rating { get; set; }

    /// <summary>
    /// العنوان
    /// Title
    /// </summary>
    public string Title { get; set; } = string.Empty;

    /// <summary>
    /// التعليق
    /// Comment
    /// </summary>
    public string Comment { get; set; } = string.Empty;

    /// <summary>
    /// تاريخ المراجعة
    /// Review date
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// صور المراجعة
    /// Review images
    /// </summary>
    public List<ClientReviewImageDto> Images { get; set; } = new();

    /// <summary>
    /// هل هذه مراجعة المستخدم الحالي
    /// Is this the current user's review
    /// </summary>
    public bool IsUserReview { get; set; }

    /// <summary>
    /// عدد الإعجابات
    /// Likes count
    /// </summary>
    public int LikesCount { get; set; }

    /// <summary>
    /// هل أعجب المستخدم الحالي بالمراجعة
    /// Did current user like this review
    /// </summary>
    public bool IsLikedByUser { get; set; }

    /// <summary>
    /// الرد من إدارة العقار
    /// Reply from property management
    /// </summary>
    public ClientReviewReplyDto? ManagementReply { get; set; }

    /// <summary>
    /// نوع الحجز المرتبط بالمراجعة
    /// BookingDto type associated with review
    /// </summary>
    public string? BookingType { get; set; }

    /// <summary>
    /// هل موصى بها
    /// Is recommended
    /// </summary>
    public bool IsRecommended { get; set; }
}

/// <summary>
/// بيانات صورة المراجعة
/// Review image data
/// </summary>
public class ClientReviewImageDto
{
    /// <summary>
    /// معرف الصورة
    /// Image ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// رابط الصورة
    /// Image URL
    /// </summary>
    public string Url { get; set; } = string.Empty;

    /// <summary>
    /// رابط الصورة المصغرة
    /// Thumbnail URL
    /// </summary>
    public string ThumbnailUrl { get; set; } = string.Empty;

    /// <summary>
    /// التسمية التوضيحية
    /// Caption
    /// </summary>
    public string? Caption { get; set; }

    /// <summary>
    /// ترتيب العرض
    /// Display order
    /// </summary>
    public int DisplayOrder { get; set; }
}

/// <summary>
/// بيانات رد إدارة العقار
/// Property management reply data
/// </summary>
public class ClientReviewReplyDto
{
    /// <summary>
    /// معرف الرد
    /// Reply ID
    /// </summary>
    public Guid Id { get; set; }

    /// <summary>
    /// محتوى الرد
    /// Reply content
    /// </summary>
    public string Content { get; set; } = string.Empty;

    /// <summary>
    /// تاريخ الرد
    /// Reply date
    /// </summary>
    public DateTime CreatedAt { get; set; }

    /// <summary>
    /// اسم المرد
    /// Replier name
    /// </summary>
    public string ReplierName { get; set; } = string.Empty;

    /// <summary>
    /// منصب المرد
    /// Replier position
    /// </summary>
    public string ReplierPosition { get; set; } = string.Empty;
}