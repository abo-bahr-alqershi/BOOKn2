using MediatR;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetChannelById;

public class GetChannelByIdQuery : IRequest<NotificationChannel?>
{
    public Guid ChannelId { get; set; }
}
