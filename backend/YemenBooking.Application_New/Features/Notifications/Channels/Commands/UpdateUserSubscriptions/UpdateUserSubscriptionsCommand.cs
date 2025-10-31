using MediatR;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.UpdateUserSubscriptions;

public class UpdateUserSubscriptionsCommand : IRequest<bool>
{
    public Guid UserId { get; set; }
    public List<Guid>? ChannelsToAdd { get; set; }
    public List<Guid>? ChannelsToRemove { get; set; }
}
