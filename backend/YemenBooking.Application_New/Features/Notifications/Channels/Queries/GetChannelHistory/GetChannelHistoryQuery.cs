using MediatR;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.GetChannelHistory;

public class GetChannelHistoryQuery : IRequest<IEnumerable<NotificationChannelHistory>>
{
    public Guid ChannelId { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
