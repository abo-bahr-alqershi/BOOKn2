using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.DeleteChannel;

public class DeleteChannelCommandHandler : IRequestHandler<DeleteChannelCommand, bool>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<DeleteChannelCommandHandler> _logger;

    public DeleteChannelCommandHandler(INotificationChannelService channelService, ILogger<DeleteChannelCommandHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<bool> Handle(DeleteChannelCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("DeleteChannelCommand: {ChannelId}", request.ChannelId);
        return await _channelService.DeleteChannelAsync(request.ChannelId, cancellationToken);
    }
}
