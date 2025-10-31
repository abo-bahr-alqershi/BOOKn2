using MediatR;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.AddSubscribers;

public class AddSubscribersCommand : IRequest<int>
{
    public Guid ChannelId { get; set; }
    public List<Guid> UserIds { get; set; } = new();
}
