using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetChannelsStatistics;

public class GetChannelsStatisticsQueryHandler : IRequestHandler<GetChannelsStatisticsQuery, Dictionary<string, object>>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<GetChannelsStatisticsQueryHandler> _logger;

    public GetChannelsStatisticsQueryHandler(INotificationChannelService channelService, ILogger<GetChannelsStatisticsQueryHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<Dictionary<string, object>> Handle(GetChannelsStatisticsQuery request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("GetChannelsStatisticsQuery");
        return await _channelService.GetChannelsStatisticsAsync(cancellationToken);
    }
}
