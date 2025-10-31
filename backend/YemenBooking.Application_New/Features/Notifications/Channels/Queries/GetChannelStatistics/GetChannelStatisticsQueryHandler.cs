using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Notifications.Services;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetChannelStatistics;

public class GetChannelStatisticsQueryHandler : IRequestHandler<GetChannelStatisticsQuery, Dictionary<string, object>>
{
    private readonly INotificationChannelService _channelService;
    private readonly ILogger<GetChannelStatisticsQueryHandler> _logger;

    public GetChannelStatisticsQueryHandler(INotificationChannelService channelService, ILogger<GetChannelStatisticsQueryHandler> logger)
    {
        _channelService = channelService;
        _logger = logger;
    }

    public async Task<Dictionary<string, object>> Handle(GetChannelStatisticsQuery request, CancellationToken cancellationToken)
    {
        _logger.LogInformation("GetChannelStatisticsQuery: {ChannelId}", request.ChannelId);
        return await _channelService.GetChannelStatisticsAsync(request.ChannelId, cancellationToken);
    }
}
