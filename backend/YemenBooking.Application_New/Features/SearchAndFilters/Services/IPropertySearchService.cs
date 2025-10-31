using YemenBooking.Core.Indexing.Models;

namespace YemenBooking.Application.Features.SearchAndFilters.Services
{
    public interface IPropertySearchService
    {
        Task<PropertySearchResult> SearchAsync(PropertySearchRequest request, CancellationToken cancellationToken = default);
    }
}
