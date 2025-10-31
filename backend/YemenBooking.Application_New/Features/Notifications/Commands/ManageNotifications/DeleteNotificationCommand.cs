using MediatR;
using YemenBooking.Application.Common.Models;

namespace YemenBooking.Application.Features.Notifications.Commands.ManageNotifications
{
    /// <summary>
    /// حذف إشعار
    /// Delete notification
    /// </summary>
    public class DeleteNotificationCommand : IRequest<ResultDto<bool>>
    {
        public Guid NotificationId { get; set; }
    }
}

