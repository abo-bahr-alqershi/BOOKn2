using Microsoft.Extensions.DependencyInjection;
using YemenBooking.Core.Events;
using YemenBooking.Core.Interfaces;
using YemenBooking.Infrastructure.Events;
using YemenBooking.Infrastructure.Services;

namespace YemenBooking.Infrastructure.Configuration
{
    /// <summary>
    /// DI registration helpers for domain eventing and indexing-related handlers.
    /// </summary>
    public static class DomainEventsConfiguration
    {
        public static IServiceCollection AddDomainEventsForIndexing(this IServiceCollection services)
        {
            // Dispatcher
            services.AddSingleton<IDomainEventDispatcher, DomainEventDispatcher>();

            // Handlers wiring
            services.AddTransient<IDomainEventHandler<PropertyCreatedEvent>, PropertyCreatedEventHandler>();
            services.AddTransient<IDomainEventHandler<PropertyUpdatedEvent>, PropertyUpdatedEventHandler>();
            services.AddTransient<IDomainEventHandler<PropertyDeletedEvent>, PropertyDeletedEventHandler>();

            services.AddTransient<IDomainEventHandler<UnitCreatedEvent>, UnitCreatedEventHandler>();
            services.AddTransient<IDomainEventHandler<UnitUpdatedEvent>, UnitUpdatedEventHandler>();
            services.AddTransient<IDomainEventHandler<UnitDeletedEvent>, UnitDeletedEventHandler>();

            services.AddTransient<IDomainEventHandler<AvailabilityChangedEvent>, AvailabilityChangedEventHandler>();
            services.AddTransient<IDomainEventHandler<PricingRuleChangedEvent>, PricingRuleChangedEventHandler>();
            services.AddTransient<IDomainEventHandler<DynamicFieldChangedEvent>, DynamicFieldChangedEventHandler>();

            return services;
        }
    }
}
