using MediatR;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.RemoveSubscribers;

public class RemoveSubscribersCommand : IRequest<int>
{
    public Guid ChannelId { get; set; }
    public List<Guid> UserIds { get; set; } = new();
}
