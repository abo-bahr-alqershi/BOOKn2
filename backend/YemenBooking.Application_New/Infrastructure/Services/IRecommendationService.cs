using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Infrastructure.Services;

/// <summary>
/// واجهة خدمة التوصيات
/// Recommendation service interface
/// </summary>
public interface IRecommendationService
{
    /// <summary>
    /// الحصول على الكيانات المقترحة
    /// Get recommended properties
    /// </summary>
    Task<IEnumerable<Property>> GetRecommendedPropertiesAsync(
        Guid userId,
        int count = 10,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تحليل تفضيلات المستخدم
    /// Analyze user preferences
    /// </summary>
    Task<object> AnalyzeUserPreferencesAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// تحديث نموذج التوصيات
    /// Update recommendation model
    /// </summary>
    Task<bool> UpdateRecommendationModelAsync(
        Guid userId,
        Dictionary<string, object> userActivity,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على كيانات مشابهة
    /// Get similar properties
    /// </summary>
    Task<IEnumerable<Property>> GetSimilarPropertiesAsync(
        Guid propertyId,
        int count = 5,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على توصيات بناءً على الموقع
    /// Get location-based recommendations
    /// </summary>
    Task<IEnumerable<Property>> GetLocationBasedRecommendationsAsync(
        double latitude,
        double longitude,
        int count = 10,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// الحصول على توصيات بناءً على التاريخ
    /// Get history-based recommendations
    /// </summary>
    Task<IEnumerable<Property>> GetHistoryBasedRecommendationsAsync(
        Guid userId,
        int count = 10,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// حساب درجة التوافق
    /// Calculate compatibility score
    /// </summary>
    Task<decimal> CalculateCompatibilityScoreAsync(
        Guid userId,
        Guid propertyId,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// تدريب نموذج التوصيات
    /// Train recommendation model
    /// </summary>
    Task<bool> TrainRecommendationModelAsync(CancellationToken cancellationToken = default);
}
