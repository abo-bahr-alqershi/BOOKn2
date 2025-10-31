using MediatR;
using Microsoft.AspNetCore.Mvc;
using YemenBooking.Application.Features.Notifications.Commands.NotificationSettings;
using YemenBooking.Application.Features.Notifications.Commands.MarkAllNotificationsAsRead;
using YemenBooking.Application.Features.Notifications.Commands.ManageNotifications;
using YemenBooking.Application.Features.Notifications.Commands.DismissNotification;
using YemenBooking.Application.Features.Notifications.Queries.GetUserNotifications;
using YemenBooking.Application.Features.Notifications.Queries.GetNotificationsSummary;
using YemenBooking.Application.Features.Notifications.DTOs;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Api.Controllers.Client
{
    /// <summary>
    /// كونترولر إدارة الإشعارات للعملاء
    /// Client Notifications Management Controller
    /// </summary>
    public class NotificationsController : BaseClientController
    {
        public NotificationsController(IMediator mediator) : base(mediator)
        {
        }

        /// <summary>
        /// تحديث إعدادات الإشعارات
        /// Update notification settings
        /// </summary>
        /// <param name="command">إعدادات الإشعارات الجديدة</param>
        /// <returns>نتيجة التحديث</returns>
        [HttpPut("settings")]
        public async Task<ActionResult<ResultDto<UpdateNotificationSettingsResponse>>> UpdateNotificationSettings([FromBody] UpdateNotificationSettingsCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تمييز إشعار كمقروء
        /// Mark notification as read
        /// </summary>
        /// <param name="command">بيانات الإشعار</param>
        /// <returns>نتيجة التمييز</returns>
        [HttpPut("mark-as-read")]
        public async Task<ActionResult<ResultDto<MarkNotificationAsReadResponse>>> MarkAsRead([FromBody] MarkNotificationAsReadCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// تمييز جميع الإشعارات كمقروءة
        /// Mark all notifications as read
        /// </summary>
        /// <param name="command">بيانات المستخدم</param>
        /// <returns>نتيجة التمييز</returns>
        [HttpPut("mark-all-as-read")]
        public async Task<ActionResult<ResultDto<MarkAllNotificationsAsReadResponse>>> MarkAllAsRead([FromBody] MarkAllNotificationsAsReadCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// إغلاق إشعار
        /// Dismiss notification
        /// </summary>
        /// <param name="command">بيانات الإشعار</param>
        /// <returns>نتيجة الإغلاق</returns>
        [HttpDelete("dismiss")]
        public async Task<ActionResult<ResultDto<DismissNotificationResponse>>> DismissNotification([FromBody] DismissNotificationCommand command)
        {
            var result = await _mediator.Send(command);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على إشعارات المستخدم
        /// Get user notifications
        /// </summary>
        /// <param name="query">معايير البحث</param>
        /// <returns>قائمة الإشعارات</returns>
        [HttpGet]
        public async Task<ActionResult<ResultDto<PaginatedResult<ClientNotificationDto>>>> GetUserNotifications([FromQuery] ClientGetUserNotificationsQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }

        /// <summary>
        /// الحصول على ملخص إشعارات المستخدم
        /// Get user notifications summary
        /// </summary>
        /// <param name="query">معايير الملخص</param>
        /// <returns>ملخص الإشعارات</returns>
        [HttpGet("summary")]
        public async Task<ActionResult<ResultDto<ClientNotificationsSummaryDto>>> GetNotificationsSummary([FromQuery] ClientGetNotificationsSummaryQuery query)
        {
            var result = await _mediator.Send(query);
            return Ok(result);
        }
    }
}
