using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.SearchChannels;

public class SearchChannelsQueryHandler : IRequestHandler<SearchChannelsQuery, IEnumerable<NotificationChannel>>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<SearchChannelsQueryHandler> _logger;

    public SearchChannelsQueryHandler(INotificationChannelService channelService, ILogger<SearchChannelsQueryHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<IEnumerable<NotificationChannel>> Handle(SearchChannelsQuery request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("SearchChannelsQuery: search={Search}, type={Type}, active={IsActive}, page={Page}", request.Search, request.Type, request.IsActive, request.Page);
        return await _channelService.SearchChannelsAsync(request.Search, request.Type, request.IsActive, request.Page, request.PageSize, cancellationToken);
    }
}
