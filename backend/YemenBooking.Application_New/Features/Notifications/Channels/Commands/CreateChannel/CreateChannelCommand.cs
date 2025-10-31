using MediatR;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.CreateChannel;

public class CreateChannelCommand : IRequest<NotificationChannel>
{
    public string Name { get; set; } = null!;
    public string Identifier { get; set; } = null!;
    public string? Description { get; set; }
    public string? Type { get; set; }
    public string? Icon { get; set; }
    public string? Color { get; set; }
    public Guid? CreatedBy { get; set; }
}
