using MediatR;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Features;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.Units.Events {
    /// <summary>
    /// معالج أحداث الإتاحة
    /// </summary>
    public class AvailabilityEventHandler : INotificationHandler<AvailabilityChangedEvent>
    {
        private readonly IIndexingService _indexService;

        public AvailabilityEventHandler(IIndexingService indexService)
        {
            _indexService = indexService;
        }

        public async Task Handle(AvailabilityChangedEvent notification, CancellationToken cancellationToken)
        {
            await _indexService.OnAvailabilityChangedAsync(
                notification.UnitId,
                notification.PropertyId,
                notification.AvailableRanges,
                cancellationToken);
        }
    }
}