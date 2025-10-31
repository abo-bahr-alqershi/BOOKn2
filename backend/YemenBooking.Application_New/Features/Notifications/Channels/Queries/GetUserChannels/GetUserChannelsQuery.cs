using MediatR;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetUserChannels;

public class GetUserChannelsQuery : IRequest<IEnumerable<NotificationChannel>>
{
    public Guid UserId { get; set; }
    public bool ActiveOnly { get; set; } = true;
}
