using MediatR;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Features;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.Properties.Events
{
    /// <summary>
    /// معالج أحداث العقارات
    /// </summary>
    public class PropertyEventHandler :
        INotificationHandler<PropertyCreatedEvent>,
        INotificationHandler<PropertyUpdatedEvent>,
        INotificationHandler<PropertyDeletedEvent>
    {
        private readonly IIndexingService _indexService;
        private readonly ILogger<PropertyEventHandler> _logger;

        public PropertyEventHandler(
            IIndexingService indexService,
            ILogger<PropertyEventHandler> logger)
        {
            _indexService = indexService;
            _logger = logger;
        }

        public async Task Handle(PropertyCreatedEvent notification, CancellationToken cancellationToken)
        {
            await _indexService.OnPropertyCreatedAsync(notification.PropertyId, cancellationToken);
        }

        public async Task Handle(PropertyUpdatedEvent notification, CancellationToken cancellationToken)
        {
            await _indexService.OnPropertyUpdatedAsync(notification.PropertyId, cancellationToken);
        }

        public async Task Handle(PropertyDeletedEvent notification, CancellationToken cancellationToken)
        {
            await _indexService.OnPropertyDeletedAsync(notification.PropertyId, cancellationToken);
        }
    }

}