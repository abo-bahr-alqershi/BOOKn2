using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Notifications.Queries.GetNotificationsSummary;

/// <summary>
/// استعلام جلب ملخص الإشعارات للعميل
/// Query to get notifications summary for client
/// </summary>
public class ClientGetNotificationsSummaryQuery : IRequest<ResultDto<ClientNotificationsSummaryDto>>
{
    /// <summary>
    /// معرف المستخدم
    /// User ID
    /// </summary>
    public Guid UserId { get; set; }
}

/// <summary>
/// ملخص الإشعارات للعميل
/// Client notifications summary
/// </summary>
public class ClientNotificationsSummaryDto
{
    /// <summary>
    /// إجمالي عدد الإشعارات
    /// Total notifications count
    /// </summary>
    public int TotalCount { get; set; }

    /// <summary>
    /// عدد الإشعارات غير المقروءة
    /// Unread notifications count
    /// </summary>
    public int UnreadCount { get; set; }

    /// <summary>
    /// عدد الإشعارات المقروءة
    /// Read notifications count
    /// </summary>
    public int ReadCount { get; set; }

    /// <summary>
    /// عدد الإشعارات حسب النوع
    /// Notifications count by type
    /// </summary>
    public Dictionary<string, int> CountByType { get; set; } = new();

    /// <summary>
    /// عدد الإشعارات حسب الأولوية
    /// Notifications count by priority
    /// </summary>
    public Dictionary<string, int> CountByPriority { get; set; } = new();

    /// <summary>
    /// آخر إشعار تم استلامه
    /// Last received notification
    /// </summary>
    public ClientNotificationDto? LastNotification { get; set; }

    /// <summary>
    /// الإشعارات عالية الأولوية غير المقروءة
    /// Unread high priority notifications
    /// </summary>
    public List<ClientNotificationDto> HighPriorityUnread { get; set; } = new();
}