using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.SendChannelNotification;

public class SendChannelNotificationCommandHandler : IRequestHandler<SendChannelNotificationCommand, NotificationChannelHistory>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<SendChannelNotificationCommandHandler> _logger;

    public SendChannelNotificationCommandHandler(INotificationChannelService channelService, ILogger<SendChannelNotificationCommandHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<NotificationChannelHistory> Handle(SendChannelNotificationCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("SendChannelNotificationCommand: {ChannelId} {Title}", request.ChannelId, request.Title);
        return await _channelService.SendChannelNotificationAsync(
            request.ChannelId,
            request.Title,
            request.Content,
            request.Type ?? "INFO",
            request.SenderId,
            request.Data,
            cancellationToken);
    }
}
