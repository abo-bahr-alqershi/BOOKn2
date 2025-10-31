using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetChannelById;

public class GetChannelByIdQueryHandler : IRequestHandler<GetChannelByIdQuery, NotificationChannel?>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<GetChannelByIdQueryHandler> _logger;

    public GetChannelByIdQueryHandler(INotificationChannelService channelService, ILogger<GetChannelByIdQueryHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<NotificationChannel?> Handle(GetChannelByIdQuery request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("GetChannelByIdQuery: {ChannelId}", request.ChannelId);
        return await _channelService.GetChannelAsync(request.ChannelId, cancellationToken);
    }
}
