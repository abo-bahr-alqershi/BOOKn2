using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetUserNotifications;

/// <summary>
/// استعلام جلب إشعارات المستخدم للعميل
/// Query to get user notifications for client
/// </summary>
public class ClientGetUserNotificationsQuery : IRequest<ResultDto<PaginatedResult<ClientNotificationDto>>>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }

    /// <summary>
    /// رقم الصفحة
    /// Page number
    /// </summary>
    public int PageNumber { get; set; } = 1;

    /// <summary>
    /// حجم الصفحة
    /// Page size
    /// </summary>
    public int PageSize { get; set; } = 20;

    /// <summary>
    /// فلتر حسب الحالة (قراءة، غير مقروء)
    /// Filter by status (read, unread)
    /// </summary>
    public string? Status { get; set; }

    /// <summary>
    /// فلتر حسب النوع
    /// Filter by type
    /// </summary>
    public string? Type { get; set; }

    /// <summary>
    /// فقط الإشعارات غير المقروءة
    /// Only unread notifications
    /// </summary>
    public bool? UnreadOnly { get; set; }

    /// <summary>
    /// تاريخ البداية للفلترة
    /// Start date for filtering
    /// </summary>
    public DateTime? FromDate { get; set; }

    /// <summary>
    /// تاريخ النهاية للفلترة
    /// End date for filtering
    /// </summary>
    public DateTime? ToDate { get; set; }
}
