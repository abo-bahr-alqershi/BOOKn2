using System;
using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Notifications.Commands.ManageNotifications;

/// <summary>
/// أمر لوضع علامة قراءة على جميع الإشعارات لمستخدم معين
/// Command to mark all notifications as read for a recipient
/// </summary>
public class MarkAllNotificationsReadCommand : IRequest<ResultDto<bool>>
{
    /// <summary>
    /// معرف المستلم
    /// Recipient identifier
    /// </summary>
    public Guid RecipientId { get; set; }
} 