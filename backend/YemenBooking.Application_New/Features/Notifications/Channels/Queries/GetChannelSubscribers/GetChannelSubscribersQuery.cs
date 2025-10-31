using MediatR;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetChannelSubscribers;

public class GetChannelSubscribersQuery : IRequest<IEnumerable<UserChannel>>
{
    public Guid ChannelId { get; set; }
    public bool ActiveOnly { get; set; } = true;
}
