using MediatR;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Notifications.Channels.Queries.SearchChannels;

public class SearchChannelsQuery : IRequest<IEnumerable<NotificationChannel>>
{
    public string? Search { get; set; }
    public string? Type { get; set; }
    public bool? IsActive { get; set; }
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
}
