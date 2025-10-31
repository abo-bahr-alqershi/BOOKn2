using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.RemoveSubscribers;

public class RemoveSubscribersCommandHandler : IRequestHandler<RemoveSubscribersCommand, int>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<RemoveSubscribersCommandHandler> _logger;

    public RemoveSubscribersCommandHandler(INotificationChannelService channelService, ILogger<RemoveSubscribersCommandHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<int> Handle(RemoveSubscribersCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("RemoveSubscribersCommand: Channel {ChannelId} - Count {Count}", request.ChannelId, request.UserIds?.Count ?? 0);
        return await _channelService.BulkUnsubscribeUsersAsync(request.ChannelId, request.UserIds, cancellationToken);
    }
}
