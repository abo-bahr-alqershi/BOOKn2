using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetChannelSubscribers;

public class GetChannelSubscribersQueryHandler : IRequestHandler<GetChannelSubscribersQuery, IEnumerable<UserChannel>>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<GetChannelSubscribersQueryHandler> _logger;

    public GetChannelSubscribersQueryHandler(INotificationChannelService channelService, ILogger<GetChannelSubscribersQueryHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<IEnumerable<UserChannel>> Handle(GetChannelSubscribersQuery request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("GetChannelSubscribersQuery: {ChannelId}, activeOnly={ActiveOnly}", request.ChannelId, request.ActiveOnly);
        return await _channelService.GetChannelSubscribersAsync(request.ChannelId, request.ActiveOnly, cancellationToken);
    }
}
