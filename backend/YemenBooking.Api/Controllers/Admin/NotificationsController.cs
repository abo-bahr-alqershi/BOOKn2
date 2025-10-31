using System.Threading.Tasks;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Notifications.Commands.ManageNotifications;
using YemenBooking.Application.Features.Notifications.Commands.BroadcastNotifications;
using YemenBooking.Application.Features.Notifications.Queries.GetUserNotifications;
using YemenBooking.Application.Features.Notifications.Queries.GetNotificationsStats;
using YemenBooking.Application.Features.Notifications.Queries.GetSystemNotifications;
using YemenBooking.Application.Features.Notifications.DTOs;
using System;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Api.Controllers.Admin
{
    /// <summary>
    /// متحكم بإشعارات النظام للمدراء
    /// Controller for system notifications by admins
    /// </summary>
    public class NotificationsController : BaseAdminController
    {
        public NotificationsController(IMediator mediator) : base(mediator) { }

        /// <summary>
        /// إنشاء إشعار جديد
        /// Create a new notification
        /// </summary>
        [HttpPost]
        public async Task<IActionResult> CreateNotification([FromBody] CreateNotificationCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// بث إشعار لمجموعة مستخدمين
        /// Broadcast a notification to users
        /// </summary>
        [HttpPost("broadcast")]
        public async Task<ActionResult<ResultDto<int>>> Broadcast([FromBody] BroadcastNotificationCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// جلب إشعارات النظام
        /// Get system notifications
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> GetSystemNotifications([FromQuery] GetSystemNotificationsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// جلب إشعارات المستخدم
        /// Get user notifications
        /// </summary>
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetUserNotifications(Guid userId, [FromQuery] GetUserNotificationsQuery query)
        {
            query.UserId = userId;
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// حذف إشعار
        /// </summary>
        [HttpDelete("{notificationId}")]
        public async Task<ActionResult<ResultDto<bool>>> Delete(Guid notificationId)
        {
            var result = await _mediator.Send(new DeleteNotificationCommand { NotificationId = notificationId });
            return Ok(result);
        }

        /// <summary>
        /// إعادة إرسال إشعار فاشل
        /// </summary>
        [HttpPost("{notificationId}/resend")]
        public async Task<ActionResult<ResultDto<bool>>> Resend(Guid notificationId)
        {
            var result = await _mediator.Send(new ResendNotificationCommand { NotificationId = notificationId });
            return Ok(result);
        }

        /// <summary>
        /// الحصول على إحصائيات الإشعارات
        /// </summary>
        [HttpGet("stats")]
        public async Task<ActionResult<NotificationsStatsDto>> GetStats([FromQuery] GetNotificationsStatsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
} 