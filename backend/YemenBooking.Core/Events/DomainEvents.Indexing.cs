using System;
using System.Collections.Generic;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Entities;

namespace YemenBooking.Core.Events
{
    /// <summary>
    /// Base helper for domain events providing common metadata defaults.
    /// </summary>
    public abstract class DomainEventBase : IDomainEvent
    {
        public Guid EventId { get; } = Guid.NewGuid();
        public DateTime OccurredOn { get; } = DateTime.UtcNow;
        public string EventType => GetType().Name;
        public int Version { get; init; } = 1;
        public Guid? UserId { get; init; }
        public string? CorrelationId { get; init; }
    }

    // Property events
    public sealed class PropertyCreatedEvent : DomainEventBase
    {
        public Guid PropertyId { get; init; }
    }

    public sealed class PropertyUpdatedEvent : DomainEventBase
    {
        public Guid PropertyId { get; init; }
    }

    public sealed class PropertyDeletedEvent : DomainEventBase
    {
        public Guid PropertyId { get; init; }
    }

    // Unit events
    public sealed class UnitCreatedEvent : DomainEventBase
    {
        public Guid UnitId { get; init; }
        public Guid PropertyId { get; init; }
    }

    public sealed class UnitUpdatedEvent : DomainEventBase
    {
        public Guid UnitId { get; init; }
        public Guid PropertyId { get; init; }
    }

    public sealed class UnitDeletedEvent : DomainEventBase
    {
        public Guid UnitId { get; init; }
        public Guid PropertyId { get; init; }
    }

    // Availability and pricing events
    public sealed class AvailabilityChangedEvent : DomainEventBase
    {
        public Guid UnitId { get; init; }
        public Guid PropertyId { get; init; }
        public List<(DateTime Start, DateTime End)> AvailableRanges { get; init; } = new();
    }

    public sealed class PricingRuleChangedEvent : DomainEventBase
    {
        public Guid UnitId { get; init; }
        public Guid PropertyId { get; init; }
        public List<PricingRule> PricingRules { get; init; } = new();
    }

    // Dynamic field events
    public sealed class DynamicFieldChangedEvent : DomainEventBase
    {
        public Guid PropertyId { get; init; }
        public string FieldName { get; init; } = string.Empty;
        public string FieldValue { get; init; } = string.Empty;
        public bool IsAdd { get; init; }
    }
}
