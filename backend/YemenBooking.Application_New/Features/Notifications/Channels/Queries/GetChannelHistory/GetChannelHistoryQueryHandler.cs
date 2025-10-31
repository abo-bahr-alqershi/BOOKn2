using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetChannelHistory;

public class GetChannelHistoryQueryHandler : IRequestHandler<GetChannelHistoryQuery, IEnumerable<NotificationChannelHistory>>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<GetChannelHistoryQueryHandler> _logger;

    public GetChannelHistoryQueryHandler(INotificationChannelService channelService, ILogger<GetChannelHistoryQueryHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<IEnumerable<NotificationChannelHistory>> Handle(GetChannelHistoryQuery request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("GetChannelHistoryQuery: {ChannelId} page={Page}", request.ChannelId, request.Page);
        return await _channelService.GetChannelHistoryAsync(request.ChannelId, request.Page, request.PageSize, cancellationToken);
    }
}
