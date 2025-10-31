using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Application.Features.SearchAndFilters.Services
{
    public interface IPropertyIndexingService
    {
        Task OnPropertyCreatedAsync(Guid propertyId, CancellationToken cancellationToken = default);
        Task OnPropertyUpdatedAsync(Guid propertyId, CancellationToken cancellationToken = default);
        Task OnPropertyDeletedAsync(Guid propertyId, CancellationToken cancellationToken = default);
        Task OnDynamicFieldChangedAsync(Guid propertyId, string fieldName, string fieldValue, bool isAdd, CancellationToken cancellationToken = default);
    }
}
