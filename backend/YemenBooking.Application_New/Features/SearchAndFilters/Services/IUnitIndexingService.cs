using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.SearchAndFilters.Services
{
    public interface IUnitIndexingService
    {
        Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);
        Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);
        Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);
        Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId, List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default);
        Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId, List<PricingRule> pricingRules, CancellationToken cancellationToken = default);
    }
}
