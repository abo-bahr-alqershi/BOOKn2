using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Notifications.Channels.Commands.UpdateUserSubscriptions;

public class UpdateUserSubscriptionsCommandHandler : IRequestHandler<UpdateUserSubscriptionsCommand, bool>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<UpdateUserSubscriptionsCommandHandler> _logger;

    public UpdateUserSubscriptionsCommandHandler(INotificationChannelService channelService, ILogger<UpdateUserSubscriptionsCommandHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<bool> Handle(UpdateUserSubscriptionsCommand request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("UpdateUserSubscriptionsCommand: User {UserId}", request.UserId);

        foreach (var channelId in request.ChannelsToAdd ?? new List<Guid>())
            await _channelService.SubscribeUserAsync(request.UserId, channelId, cancellationToken);

        foreach (var channelId in request.ChannelsToRemove ?? new List<Guid>())
            await _channelService.UnsubscribeUserAsync(request.UserId, channelId, cancellationToken);

        return true;
    }
}
