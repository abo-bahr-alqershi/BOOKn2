using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetUserChannels;

public class GetUserChannelsQueryHandler : IRequestHandler<GetUserChannelsQuery, IEnumerable<NotificationChannel>>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<GetUserChannelsQueryHandler> _logger;

    public GetUserChannelsQueryHandler(INotificationChannelService channelService, ILogger<GetUserChannelsQueryHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<IEnumerable<NotificationChannel>> Handle(GetUserChannelsQuery request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("GetUserChannelsQuery: User {UserId} activeOnly={ActiveOnly}", request.UserId, request.ActiveOnly);
        return await _channelService.GetUserChannelsAsync(request.UserId, request.ActiveOnly, cancellationToken);
    }
}
