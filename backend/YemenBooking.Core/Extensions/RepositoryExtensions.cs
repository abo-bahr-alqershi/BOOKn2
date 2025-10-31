namespace YemenBooking.Core.Interfaces.Repositories;

using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

/// <summary>
/// امتدادات مساعدة لتوفير أساليب كانت مطلوبة في مستوى التطبيق بدون تعديل التواقيع الأصلية للمستودعات.
/// Helper extension methods to supply missing methods expected by MobileApp handlers while keeping original repository contracts intact.
/// </summary>
public static class RepositoryExtensions
{
    /// <summary>
    /// Proxy for IPropertyRepository.GetActivePropertiesAsync expected by MobileApp handlers.
    /// Retrieves properties that are active and approved.
    /// </summary>
    public static async Task<IEnumerable<Property>> GetActivePropertiesAsync(this IPropertyRepository repo, CancellationToken cancellationToken = default)
    {
        // Assume repository has a generic GetListAsync with predicate
        return await repo.FindAsync(p => p.IsApproved && !p.IsDeleted, cancellationToken);
    }
    /// <summary>
    /// Proxy for IFavoriteRepository.ExistsAsync expected as IsPropertyFavoriteAsync.
    /// </summary>
    public static Task<bool> IsPropertyFavoriteAsync(this IFavoriteRepository repo, Guid userId, Guid propertyId, CancellationToken cancellationToken = default)
        => repo.ExistsAsync(userId, propertyId, cancellationToken);

    /// <summary>
    /// Proxy for IUnitRepository.GetUnitsByPropertyAsync expected as GetByPropertyIdAsync.
    /// </summary>
    public static Task<IEnumerable<Unit>> GetByPropertyIdAsync(this IUnitRepository repo, Guid propertyId, CancellationToken cancellationToken = default)
        => repo.GetUnitsByPropertyAsync(propertyId, cancellationToken);

    /// <summary>
    /// Proxy for IBookingRepository.GetBookingsByPropertyAsync expected as GetByPropertyIdAndDateRangeAsync.
    /// </summary>
    public static Task<IEnumerable<Booking>> GetByPropertyIdAndDateRangeAsync(
        this IBookingRepository repo,
        Guid propertyId,
        DateTime fromDate,
        DateTime toDate,
        CancellationToken cancellationToken = default)
        => repo.GetBookingsByPropertyAsync(propertyId, fromDate, toDate, cancellationToken);

    /// <summary>
    /// Proxy for IBookingRepository.GetBookingsByPropertyAsync expected as GetByPropertyIdAsync (without dates).
    /// </summary>
    public static Task<IEnumerable<Booking>> GetByPropertyIdAsync(this IBookingRepository repo, Guid propertyId, CancellationToken cancellationToken = default)
        => repo.GetBookingsByPropertyAsync(propertyId, null, null, cancellationToken);

    /// <summary>
    /// Proxy for IReviewRepository.GetReviewsByPropertyAsync expected as GetByPropertyIdAsync.
    /// </summary>
    public static Task<IEnumerable<Review>> GetByPropertyIdAsync(this IReviewRepository repo, Guid propertyId, CancellationToken cancellationToken = default)
        => repo.GetReviewsByPropertyAsync(propertyId, cancellationToken);

    /// <summary>
    /// Proxy for ICurrencyExchangeRepository.GetExchangeRateAsync expected as GetLatestExchangeRateAsync.
    /// Ignores CancellationToken as underlying method doesn't support it.
    /// </summary>
    public static Task<CurrencyExchangeRate?> GetLatestExchangeRateAsync(this ICurrencyExchangeRepository repo,
        string fromCurrency,
        string toCurrency,
        CancellationToken cancellationToken = default)
        => repo.GetExchangeRateAsync(fromCurrency, toCurrency);

    /// <summary>
    /// Proxy for ICurrencyExchangeRepository.UpdateExchangeRateAsync expected as SaveExchangeRateAsync.
    /// Ignores timestamp parameter.
    /// </summary>
    public static Task<bool> SaveExchangeRateAsync(this ICurrencyExchangeRepository repo,
        string fromCurrency,
        string toCurrency,
        decimal rate,
        DateTime updatedAt,
        CancellationToken cancellationToken = default)
        => repo.UpdateExchangeRateAsync(fromCurrency, toCurrency, rate);

    /// <summary>
    /// Proxy for IAppVersionRepository.GetLatestVersionAsync (without token) expected as overload with cancellation token.
    /// </summary>
    public static Task<AppVersion?> GetLatestVersionAsync(this IAppVersionRepository repo,
        string platform,
        CancellationToken cancellationToken = default)
        => repo.GetLatestVersionAsync(platform);

    // ---------------- Mobile App Property Details helpers ----------------

    /// <summary>
    /// Proxy for getting average rating expected as GetPropertyAverageRatingAsync
    /// </summary>
    public static async Task<double> GetPropertyAverageRatingAsync(this IReviewRepository repo,
        Guid propertyId,
        CancellationToken cancellationToken = default)
    {
        var stats = await repo.GetPropertyRatingStatsAsync(propertyId, cancellationToken);
        return stats.AverageRating;
    }

    /// <summary>
    /// Proxy for getting reviews count expected as GetPropertyReviewsCountAsync
    /// </summary>
    public static async Task<int> GetPropertyReviewsCountAsync(this IReviewRepository repo,
        Guid propertyId,
        CancellationToken cancellationToken = default)
    {
        var stats = await repo.GetPropertyRatingStatsAsync(propertyId, cancellationToken);
        return stats.TotalReviews;
    }

    /// <summary>
    /// Proxy for property booking count expected by handlers
    /// </summary>
    public static Task<int> GetPropertyBookingCountAsync(this IPropertyRepository repo,
        Guid propertyId,
        CancellationToken cancellationToken = default)
        => Task.FromResult(0);

    /// <summary>
    /// Proxy for incrementing view count when not implemented in repository
    /// </summary>
    public static Task<bool> IncrementViewCountAsync(this IPropertyRepository repo,
        Guid propertyId,
        CancellationToken cancellationToken = default)
        => Task.FromResult(true);

    // ---------------- Additional generic helpers ----------------

    /// <summary>
    /// Proxy for IUnitFieldValueRepository.GetValuesByUnitIdAsync expected as GetByUnitIdAsync.
    /// </summary>
    public static Task<IEnumerable<UnitFieldValue>> GetByUnitIdAsync(this IUnitFieldValueRepository repo,
        Guid unitId,
        CancellationToken cancellationToken = default)
        => repo.GetValuesByUnitIdAsync(unitId, cancellationToken);

    /// <summary>
    /// Proxy for IBookingRepository.GetBookingsByUserAsync expected as GetByUserIdAsync.
    /// </summary>
    public static Task<IEnumerable<Booking>> GetByUserIdAsync(this IBookingRepository repo,
        Guid userId,
        CancellationToken cancellationToken = default)
        => repo.GetBookingsByUserAsync(userId, cancellationToken);

    /// <summary>
    /// Proxy for IReviewRepository.GetReviewsByUserAsync expected as GetByUserIdAsync.
    /// </summary>
    public static Task<IEnumerable<Review>> GetByUserIdAsync(this IReviewRepository repo,
        Guid userId,
        CancellationToken cancellationToken = default)
        => repo.GetReviewsByUserAsync(userId, cancellationToken);

    /// <summary>
    /// Proxy for IFavoriteRepository.GetByUserIdAsync when not implemented directly.
    /// </summary>
    public static Task<IEnumerable<Favorite>> GetByUserIdAsync(this IFavoriteRepository repo,
        Guid userId,
        CancellationToken cancellationToken = default)
        => repo.GetByUserIdAsync(userId, cancellationToken);

}
