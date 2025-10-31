using MediatR;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Features;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.Pricing.Events {

    /// <summary>
    /// معالج أحداث التسعير
    /// </summary>
    public class PricingEventHandler : INotificationHandler<PricingRuleChangedEvent>
    {
        private readonly IIndexingService _indexService;

        public PricingEventHandler(IIndexingService indexService)
        {
            _indexService = indexService;
        }

        public async Task Handle(PricingRuleChangedEvent notification, CancellationToken cancellationToken)
        {
            await _indexService.OnPricingRuleChangedAsync(
                notification.UnitId,
                notification.PropertyId,
                notification.PricingRules,
                cancellationToken);
        }
    }

}