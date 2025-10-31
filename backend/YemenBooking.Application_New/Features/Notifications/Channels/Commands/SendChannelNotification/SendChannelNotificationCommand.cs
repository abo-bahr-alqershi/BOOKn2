using MediatR;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.SendChannelNotification;

public class SendChannelNotificationCommand : IRequest<NotificationChannelHistory>
{
    public Guid ChannelId { get; set; }
    public string Title { get; set; } = null!;
    public string Content { get; set; } = null!;
    public string? Type { get; set; }
    public Guid? SenderId { get; set; }
    public Dictionary<string, string>? Data { get; set; }
}
