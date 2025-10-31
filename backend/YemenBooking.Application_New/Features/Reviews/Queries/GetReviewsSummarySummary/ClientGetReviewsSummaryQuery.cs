using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;
using YemenBooking.Application.Features.Reviews.Queries.GetPropertyReviews;

namespace YemenBooking.Application.Features.Reviews.Queries.GetReviewsSummarySummary;

/// <summary>
/// استعلام جلب ملخص المراجعات للعميل
/// Query to get reviews summary for client
/// </summary>
public class ClientGetReviewsSummaryQuery : IRequest<ResultDto<ClientReviewsSummaryDto>>
{
    /// <summary>
    /// معرف العقار
    /// Property ID
    /// </summary>
    public Guid PropertyId { get; set; }
}

/// <summary>
/// ملخص المراجعات للعميل
/// Client reviews summary
/// </summary>
public class ClientReviewsSummaryDto
{
    /// <summary>
    /// إجمالي عدد المراجعات
    /// Total reviews count
    /// </summary>
    public int TotalReviews { get; set; }

    /// <summary>
    /// متوسط التقييم
    /// Average rating
    /// </summary>
    public decimal AverageRating { get; set; }

    /// <summary>
    /// توزيع التقييمات (1-5 نجوم)
    /// Rating distribution (1-5 stars)
    /// </summary>
    public Dictionary<int, int> RatingDistribution { get; set; } = new();

    /// <summary>
    /// نسبة التقييمات حسب النجوم
    /// Rating percentages by stars
    /// </summary>
    public Dictionary<int, decimal> RatingPercentages { get; set; } = new();

    /// <summary>
    /// عدد المراجعات مع الصور
    /// Reviews with images count
    /// </summary>
    public int ReviewsWithImagesCount { get; set; }

    /// <summary>
    /// عدد المراجعات الموصى بها
    /// Recommended reviews count
    /// </summary>
    public int RecommendedCount { get; set; }

    /// <summary>
    /// أحدث 3 مراجعات
    /// Latest 3 reviews
    /// </summary>
    public List<ClientReviewDto> LatestReviews { get; set; } = new();

    /// <summary>
    /// أفضل 3 مراجعات (الأعلى تقييماً)
    /// Top 3 reviews (highest rated)
    /// </summary>
    public List<ClientReviewDto> TopReviews { get; set; } = new();

    /// <summary>
    /// الكلمات المفتاحية الشائعة في المراجعات
    /// Common keywords in reviews
    /// </summary>
    public List<ClientReviewKeywordDto> CommonKeywords { get; set; } = new();

    /// <summary>
    /// معدل الاستجابة من الإدارة
    /// Management response rate
    /// </summary>
    public decimal ManagementResponseRate { get; set; }
}

/// <summary>
/// بيانات الكلمات المفتاحية في المراجعات
/// Review keywords data
/// </summary>
public class ClientReviewKeywordDto
{
    /// <summary>
    /// الكلمة المفتاحية
    /// Keyword
    /// </summary>
    public string Keyword { get; set; } = string.Empty;

    /// <summary>
    /// عدد مرات التكرار
    /// Frequency count
    /// </summary>
    public int Count { get; set; }

    /// <summary>
    /// النسبة المئوية
    /// Percentage
    /// </summary>
    public decimal Percentage { get; set; }

    /// <summary>
    /// نوع المشاعر (إيجابي، سلبي، محايد)
    /// Sentiment type (positive, negative, neutral)
    /// </summary>
    public string Sentiment { get; set; } = "Neutral";
}