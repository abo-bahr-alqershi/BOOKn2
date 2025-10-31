using System;
using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Notifications.Commands.MarkAllNotificationsAsRead;
using YemenBooking.Application.Features.Notifications.Commands.ManageNotifications;
using YemenBooking.Application.Features.Notifications.Queries.GetUserNotifications;

namespace YemenBooking.Api.Controllers.Common
{
    /// <summary>
    /// متحكم بإشعارات النظام المشتركة
    /// Controller for common system notifications operations
    /// </summary>
    public class NotificationsController : BaseCommonController
    {
        public NotificationsController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// وضع علامة مقروء على جميع الإشعارات
        /// Mark all notifications as read
        /// </summary>
        [HttpPost("mark-all-read")]
        public async Task<IActionResult> MarkAllNotificationsRead()
        {
            var command = new MarkAllNotificationsReadCommand();
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// وضع علامة مقروء على إشعار محدد
        /// Mark a single notification as read
        /// </summary>
        [HttpPost("{notificationId}/read")]
        public async Task<IActionResult> MarkNotificationAsRead(Guid notificationId)
        {
            var command = new MarkNotificationAsReadCommand { NotificationId = notificationId };
            var result = await _mediator.Send(command);
            return Ok(result);
        }
    }
} 