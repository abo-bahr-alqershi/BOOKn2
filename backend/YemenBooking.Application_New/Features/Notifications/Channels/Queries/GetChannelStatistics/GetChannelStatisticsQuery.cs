using MediatR;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetChannelStatistics;

public class GetChannelStatisticsQuery : IRequest<Dictionary<string, object>>
{
    public Guid ChannelId { get; set; }
}
