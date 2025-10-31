using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.UpdateChannel;

public class UpdateChannelCommandHandler : IRequestHandler<UpdateChannelCommand, NotificationChannel>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<UpdateChannelCommandHandler> _logger;

    public UpdateChannelCommandHandler(INotificationChannelService channelService, ILogger<UpdateChannelCommandHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<NotificationChannel> Handle(UpdateChannelCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("UpdateChannelCommand: {ChannelId}", request.ChannelId);
        var channel = await _channelService.UpdateChannelAsync(
            request.ChannelId,
            request.Name,
            request.Description,
            request.IsActive,
            request.Icon,
            request.Color,
            cancellationToken);
        return channel;
    }
}
