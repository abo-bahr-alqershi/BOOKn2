using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.AddSubscribers;

public class AddSubscribersCommandHandler : IRequestHandler<AddSubscribersCommand, int>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<AddSubscribersCommandHandler> _logger;

    public AddSubscribersCommandHandler(INotificationChannelService channelService, ILogger<AddSubscribersCommandHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<int> Handle(AddSubscribersCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("AddSubscribersCommand: Channel {ChannelId} - Count {Count}", request.ChannelId, request.UserIds?.Count ?? 0);
        return await _channelService.BulkSubscribeUsersAsync(request.ChannelId, request.UserIds, cancellationToken);
    }
}
