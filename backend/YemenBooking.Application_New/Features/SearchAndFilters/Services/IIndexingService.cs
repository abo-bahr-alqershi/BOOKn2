using YemenBooking.Core.Entities;
using YemenBooking.Core.Indexing.Models;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.SearchAndFilters.Services {
    public interface IIndexingService
    {
        // العقارات
        Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default);
        Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default);
        Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default);

        // الوحدات
        Task OnUnitCreatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);
        Task OnUnitUpdatedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);
        Task OnUnitDeletedAsync(Guid unitId, Guid propertyId, CancellationToken cancellationToken = default);

        // الإتاحة
        Task OnAvailabilityChangedAsync(Guid unitId, Guid propertyId, List<(DateTime Start, DateTime End)> availableRanges, CancellationToken cancellationToken = default);

        // التسعير
        Task OnPricingRuleChangedAsync(Guid unitId, Guid propertyId, List<PricingRule> pricingRules, CancellationToken cancellationToken = default);

        // الحقول الديناميكية
        Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName, string fieldValue, bool isAdd, CancellationToken cancellationToken = default);

        // البحث
        Task<PropertySearchResult> SearchAsync(PropertySearchRequest request, CancellationToken cancellationToken = default);

        // الصيانة
        Task OptimizeDatabaseAsync();
        Task RebuildIndexAsync(CancellationToken cancellationToken = default);
    }
}