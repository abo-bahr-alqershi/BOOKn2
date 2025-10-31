using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.CreateChannel;

public class CreateChannelCommandHandler : IRequestHandler<CreateChannelCommand, NotificationChannel>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<CreateChannelCommandHandler> _logger;

    public CreateChannelCommandHandler(INotificationChannelService channelService, ILogger<CreateChannelCommandHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<NotificationChannel> Handle(CreateChannelCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("CreateChannelCommand: {Name} ({Identifier})", request.Name, request.Identifier);
        var channel = await _channelService.CreateChannelAsync(
            request.Name,
            request.Identifier,
            request.Description,
            request.Type ?? "CUSTOM",
            request.CreatedBy,
            request.Icon,
            request.Color,
            cancellationToken);
        return channel;
    }
}
