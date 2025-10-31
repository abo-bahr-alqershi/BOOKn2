using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.SearchAndFilters.Services;

/// <summary>
/// واجهة خدمة البحث
/// Search service interface
/// </summary>
public interface ISearchService
{
    /// <summary>
    /// البحث عن المستخدمين
    /// Search users
    /// </summary>
    Task<IEnumerable<User>> SearchUsersAsync(string searchTerm, CancellationToken cancellationToken = default);

    /// <summary>
    /// البحث عن الكيانات
    /// Search properties
    /// </summary>
    Task<IEnumerable<Property>> SearchPropertiesAsync(
        string searchTerm,
        DateTime? checkIn = null,
        DateTime? checkOut = null,
        int? guestCount = null,
        Guid? propertyTypeId = null,
        decimal? minPrice = null,
        decimal? maxPrice = null,
        string? city = null,
        double? latitude = null,
        double? longitude = null,
        double? radiusKm = null,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على الوجهات الشائعة
    /// Get popular destinations
    /// </summary>
    Task<IEnumerable<object>> GetPopularDestinationsAsync(int count, CancellationToken cancellationToken = default);

    /// <summary>
    /// حساب الشعبية
    /// Calculate popularity
    /// </summary>
    Task<decimal> CalculatePopularityAsync(Guid propertyId, CancellationToken cancellationToken = default);

    /// <summary>
    /// البحث المتقدم في الكيانات
    /// Advanced property search
    /// </summary>
    Task<(IEnumerable<Property> PropertyDto, int TotalCount)> AdvancedSearchAsync(
        Dictionary<string, object> searchCriteria,
        int page = 1,
        int pageSize = 20,
        string? sortBy = null,
        bool sortDescending = false,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// اقتراح البحث التلقائي
    /// Auto-complete search suggestions
    /// </summary>
    Task<IEnumerable<string>> GetSearchSuggestionsAsync(
        string partialTerm,
        string searchType = "property",
        int maxSuggestions = 10,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// فهرسة البيانات للبحث
    /// Index data for search
    /// </summary>
    Task<bool> IndexDataAsync(string entityType, object data, CancellationToken cancellationToken = default);

    /// <summary>
    /// إعادة بناء فهرس البحث
    /// Rebuild search index
    /// </summary>
    Task<bool> RebuildSearchIndexAsync(string? entityType = null, CancellationToken cancellationToken = default);
}
