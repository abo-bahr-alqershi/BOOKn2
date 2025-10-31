using MediatR;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.UpdateChannel;

public class UpdateChannelCommand : IRequest<NotificationChannel>
{
    public Guid ChannelId { get; set; }
    public string? Name { get; set; }
    public string? Description { get; set; }
    public bool? IsActive { get; set; }
    public string? Icon { get; set; }
    public string? Color { get; set; }
}
