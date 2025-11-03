using System;
using System.Threading.Tasks;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Moq;
using Xunit;
using YemenBooking.Application.Features.SearchAndFilters.Services;
using YemenBooking.Core.Events;
using YemenBooking.Core.Interfaces;
using YemenBooking.Infrastructure.Configuration;
using YemenBooking.Infrastructure.Services;

namespace YemenBooking.IndexingTests.Tests.Events
{
    public class DomainEventsIndexingTests
    {
    [Fact]
        public async Task PropertyCreatedEvent_triggers_indexing()
        {
            // Arrange: set up DI container with dispatcher and handler, and a mocked indexing service
            var services = new ServiceCollection();
            services.AddLogging(builder => builder.AddDebug().AddConsole());
            services.AddDomainEventsForIndexing();

            var indexingMock = new Mock<IIndexingService>(MockBehavior.Strict);
            var propertyId = Guid.NewGuid();
            indexingMock
                .Setup(s => s.OnPropertyCreatedAsync(propertyId, It.IsAny<System.Threading.CancellationToken>()))
                .Returns(Task.CompletedTask)
                .Verifiable();

            services.AddSingleton<IIndexingService>(provider => indexingMock.Object);

            var provider = services.BuildServiceProvider();
            var dispatcher = provider.GetRequiredService<IDomainEventDispatcher>();

            // Act
            dispatcher.AddEvent(new PropertyCreatedEvent { PropertyId = propertyId });
            await dispatcher.DispatchAsync();

            // Assert: verify handler routed the call to indexing service
            indexingMock.Verify();
        }
    }
}
