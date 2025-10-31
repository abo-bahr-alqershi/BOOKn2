using MediatR;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.DeleteChannel;

public class DeleteChannelCommand : IRequest<bool>
{
    public Guid ChannelId { get; set; }
}
