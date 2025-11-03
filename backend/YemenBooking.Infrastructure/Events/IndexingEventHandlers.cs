using System.Threading.Tasks;
using System.Threading;
using Microsoft.Extensions.Logging;
using YemenBooking.Core.Interfaces;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Events;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Infrastructure.Events
{
    // Property handlers
    public sealed class PropertyCreatedEventHandler : IDomainEventHandler<PropertyCreatedEvent>
    {
        private readonly IIndexingService _indexing;
        private readonly ILogger<PropertyCreatedEventHandler> _logger;

        public PropertyCreatedEventHandler(IIndexingService indexing, ILogger<PropertyCreatedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(PropertyCreatedEvent domainEvent)
        {
            _logger.LogDebug("Handling PropertyCreatedEvent {PropertyId}", domainEvent.PropertyId);
            await _indexing.OnPropertyCreatedAsync(domainEvent.PropertyId, CancellationToken.None);
        }
    }

    public sealed class PropertyUpdatedEventHandler : IDomainEventHandler<PropertyUpdatedEvent>
    {
        private readonly IIndexingService _indexing;
        private readonly ILogger<PropertyUpdatedEventHandler> _logger;

        public PropertyUpdatedEventHandler(IIndexingService indexing, ILogger<PropertyUpdatedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(PropertyUpdatedEvent domainEvent)
        {
            _logger.LogDebug("Handling PropertyUpdatedEvent {PropertyId}", domainEvent.PropertyId);
            await _indexing.OnPropertyUpdatedAsync(domainEvent.PropertyId, CancellationToken.None);
        }
    }

    public sealed class PropertyDeletedEventHandler : IDomainEventHandler<PropertyDeletedEvent>
    {
        private readonly IIndexingService _indexing;
        private readonly ILogger<PropertyDeletedEventHandler> _logger;

        public PropertyDeletedEventHandler(IIndexingService indexing, ILogger<PropertyDeletedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(PropertyDeletedEvent domainEvent)
        {
            _logger.LogDebug("Handling PropertyDeletedEvent {PropertyId}", domainEvent.PropertyId);
            await _indexing.OnPropertyDeletedAsync(domainEvent.PropertyId, CancellationToken.None);
        }
    }

    // Unit handlers
    public sealed class UnitCreatedEventHandler : IDomainEventHandler<UnitCreatedEvent>
    {
        private readonly IIndexingService _indexing;
        private readonly ILogger<UnitCreatedEventHandler> _logger;

        public UnitCreatedEventHandler(IIndexingService indexing, ILogger<UnitCreatedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(UnitCreatedEvent domainEvent)
        {
            _logger.LogDebug("Handling UnitCreatedEvent {UnitId}", domainEvent.UnitId);
            await _indexing.OnUnitCreatedAsync(domainEvent.UnitId, domainEvent.PropertyId, CancellationToken.None);
        }
    }

    public sealed class UnitUpdatedEventHandler : IDomainEventHandler<UnitUpdatedEvent>
    {
        private readonly IIndexingService _indexing;
        private readonly ILogger<UnitUpdatedEventHandler> _logger;

        public UnitUpdatedEventHandler(IIndexingService indexing, ILogger<UnitUpdatedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(UnitUpdatedEvent domainEvent)
        {
            _logger.LogDebug("Handling UnitUpdatedEvent {UnitId}", domainEvent.UnitId);
            await _indexing.OnUnitUpdatedAsync(domainEvent.UnitId, domainEvent.PropertyId, CancellationToken.None);
        }
    }

    public sealed class UnitDeletedEventHandler : IDomainEventHandler<UnitDeletedEvent>
    {
        private readonly IIndexingService _indexing;
        private readonly ILogger<UnitDeletedEventHandler> _logger;

        public UnitDeletedEventHandler(IIndexingService indexing, ILogger<UnitDeletedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(UnitDeletedEvent domainEvent)
        {
            _logger.LogDebug("Handling UnitDeletedEvent {UnitId}", domainEvent.UnitId);
            await _indexing.OnUnitDeletedAsync(domainEvent.UnitId, domainEvent.PropertyId, CancellationToken.None);
        }
    }

    // Availability & Pricing handlers
    public sealed class AvailabilityChangedEventHandler : IDomainEventHandler<AvailabilityChangedEvent>
    {
        private readonly IIndexingService _indexing;
        private readonly ILogger<AvailabilityChangedEventHandler> _logger;

        public AvailabilityChangedEventHandler(IIndexingService indexing, ILogger<AvailabilityChangedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(AvailabilityChangedEvent domainEvent)
        {
            _logger.LogDebug("Handling AvailabilityChangedEvent {UnitId}", domainEvent.UnitId);
            await _indexing.OnAvailabilityChangedAsync(domainEvent.UnitId, domainEvent.PropertyId, domainEvent.AvailableRanges, CancellationToken.None);
        }
    }

    public sealed class PricingRuleChangedEventHandler : IDomainEventHandler<PricingRuleChangedEvent>
    {
        private readonly IIndexingService _indexing;
        private readonly ILogger<PricingRuleChangedEventHandler> _logger;

        public PricingRuleChangedEventHandler(IIndexingService indexing, ILogger<PricingRuleChangedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(PricingRuleChangedEvent domainEvent)
        {
            _logger.LogDebug("Handling PricingRuleChangedEvent {UnitId}", domainEvent.UnitId);
            await _indexing.OnPricingRuleChangedAsync(domainEvent.UnitId, domainEvent.PropertyId, domainEvent.PricingRules, CancellationToken.None);
        }
    }

    // Dynamic fields handler
    public sealed class DynamicFieldChangedEventHandler : IDomainEventHandler<DynamicFieldChangedEvent>
    {
        private readonly IIndexingService _indexing;
        private readonly ILogger<DynamicFieldChangedEventHandler> _logger;

        public DynamicFieldChangedEventHandler(IIndexingService indexing, ILogger<DynamicFieldChangedEventHandler> logger)
        {
            _indexing = indexing;
            _logger = logger;
        }

        public async Task Handle(DynamicFieldChangedEvent domainEvent)
        {
            _logger.LogDebug("Handling DynamicFieldChangedEvent {PropertyId} {Field}", domainEvent.PropertyId, domainEvent.FieldName);
            await _indexing.OnDynamicFieldChangedAsync(domainEvent.PropertyId, domainEvent.FieldName, domainEvent.FieldValue, domainEvent.IsAdd, CancellationToken.None);
        }
    }
}
