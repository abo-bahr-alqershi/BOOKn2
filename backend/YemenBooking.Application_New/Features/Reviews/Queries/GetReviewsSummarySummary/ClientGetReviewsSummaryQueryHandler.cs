using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Reviews;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using System.Text.RegularExpressions;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Reviews.DTOs;
using YemenBooking.Application.Features;
using YemenBooking.Application.Features.Reviews.Queries.GetPropertyReviews;

namespace YemenBooking.Application.Features.Reviews.Queries.GetReviewsSummarySummary;

/// <summary>
/// معالج استعلام الحصول على ملخص المراجعات للعميل
/// Handler for client get reviews summary query
/// </summary>
public class ClientGetReviewsSummaryQueryHandler : IRequestHandler<ClientGetReviewsSummaryQuery, ResultDto<ClientReviewsSummaryDto>>
{
    private readonly IReviewRepository _reviewRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<ClientGetReviewsSummaryQueryHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج استعلام ملخص المراجعات للعميل
    /// Constructor for client get reviews summary query handler
    /// </summary>
    /// <param name="reviewRepository">مستودع المراجعات</param>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="logger">مسجل الأحداث</param>
    public ClientGetReviewsSummaryQueryHandler(
        IReviewRepository reviewRepository,
        IPropertyRepository propertyRepository,
        IUserRepository userRepository,
        ILogger<ClientGetReviewsSummaryQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _reviewRepository = reviewRepository;
        _propertyRepository = propertyRepository;
        _userRepository = userRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة استعلام الحصول على ملخص المراجعات للعميل
    /// Handle client get reviews summary query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>ملخص المراجعات للعميل</returns>
    public async Task<ResultDto<ClientReviewsSummaryDto>> Handle(ClientGetReviewsSummaryQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام ملخص المراجعات للعميل. معرف العقار: {PropertyId}", request.PropertyId);

            // التحقق من وجود العقار
            var property = await _propertyRepository.GetByIdAsync(request.PropertyId, cancellationToken);
            if (property == null)
            {
                _logger.LogWarning("العقار غير موجود. معرف العقار: {PropertyId}", request.PropertyId);
                return ResultDto<ClientReviewsSummaryDto>.Failed("العقار غير موجود", "PROPERTY_NOT_FOUND");
            }

            // جلب جميع مراجعات العقار
            var reviews = await _reviewRepository.GetByPropertyIdAsync(request.PropertyId, cancellationToken);
            
            if (reviews == null || !reviews.Any())
            {
                _logger.LogInformation("لا توجد مراجعات للعقار: {PropertyId}", request.PropertyId);
                return ResultDto<ClientReviewsSummaryDto>.Ok(GetEmptyReviewsSummary(), "لا توجد مراجعات لهذا العقار");
            }

            var reviewsList = reviews.ToList();
            var summary = new ClientReviewsSummaryDto();

            // حساب الإحصائيات الأساسية
            await CalculateBasicStatistics(summary, reviewsList, cancellationToken);

            // حساب توزيع التقييمات
            CalculateRatingDistribution(summary, reviewsList);

            // جلب أحدث المراجعات وأفضلها
            await PopulateLatestAndTopReviews(summary, reviewsList, cancellationToken);

            // استخراج الكلمات المفتاحية الشائعة
            ExtractCommonKeywords(summary, reviewsList);

            // حساب معدل الاستجابة من الإدارة
            CalculateManagementResponseRate(summary, reviewsList);

            _logger.LogInformation("تم جلب ملخص المراجعات بنجاح. إجمالي المراجعات: {TotalReviews}, متوسط التقييم: {AverageRating}", 
                summary.TotalReviews, summary.AverageRating);

            return ResultDto<ClientReviewsSummaryDto>.Ok(summary, "تم جلب ملخص المراجعات بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب ملخص المراجعات للعقار: {PropertyId}", request.PropertyId);
            return ResultDto<ClientReviewsSummaryDto>.Failed(
                $"حدث خطأ أثناء جلب ملخص المراجعات: {ex.Message}", 
                "GET_REVIEWS_SUMMARY_ERROR"
            );
        }
    }

    /// <summary>
    /// حساب الإحصائيات الأساسية
    /// Calculate basic statistics
    /// </summary>
    /// <param name="summary">ملخص المراجعات</param>
    /// <param name="reviews">قائمة المراجعات</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    private async Task CalculateBasicStatistics(ClientReviewsSummaryDto summary, List<Core.Entities.Review> reviews, CancellationToken cancellationToken)
    {
        try
        {
            summary.TotalReviews = reviews.Count;
            summary.AverageRating = reviews.Any() ? Math.Round(reviews.Average(r => r.AverageRating), 1) : 0;

            // عدد المراجعات مع الصور
            summary.ReviewsWithImagesCount = reviews.Count(r => r.Images != null && r.Images.Any());

            // عدد المراجعات الموصى بها (التقييم 4 أو أكثر)
            summary.RecommendedCount = reviews.Count(r => r.AverageRating >= 4);

            _logger.LogDebug("تم حساب الإحصائيات الأساسية. إجمالي: {Total}, متوسط: {Average}, مع صور: {WithImages}, موصى بها: {Recommended}", 
                summary.TotalReviews, summary.AverageRating, summary.ReviewsWithImagesCount, summary.RecommendedCount);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حساب الإحصائيات الأساسية");
        }
    }

    /// <summary>
    /// حساب توزيع التقييمات
    /// Calculate rating distribution
    /// </summary>
    /// <param name="summary">ملخص المراجعات</param>
    /// <param name="reviews">قائمة المراجعات</param>
    private void CalculateRatingDistribution(ClientReviewsSummaryDto summary, List<Core.Entities.Review> reviews)
    {
        try
        {
            // تهيئة التوزيع بالقيم الافتراضية
            for (int i = 1; i <= 5; i++)
            {
                summary.RatingDistribution[i] = 0;
                summary.RatingPercentages[i] = 0;
            }

            if (!reviews.Any()) return;

            // حساب التوزيع
            var ratingGroups = reviews
                .GroupBy(r => Math.Round(r.AverageRating))
                .ToDictionary(g => (int)g.Key, g => g.Count());

            foreach (var group in ratingGroups)
            {
                if (group.Key >= 1 && group.Key <= 5)
                {
                    summary.RatingDistribution[group.Key] = group.Value;
                    summary.RatingPercentages[group.Key] = Math.Round((decimal)group.Value / reviews.Count * 100, 1);
                }
            }

            _logger.LogDebug("تم حساب توزيع التقييمات بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حساب توزيع التقييمات");
        }
    }

    /// <summary>
    /// جلب أحدث المراجعات وأفضلها
    /// Populate latest and top reviews
    /// </summary>
    /// <param name="summary">ملخص المراجعات</param>
    /// <param name="reviews">قائمة المراجعات</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    private async Task PopulateLatestAndTopReviews(ClientReviewsSummaryDto summary, List<Core.Entities.Review> reviews, CancellationToken cancellationToken)
    {
        try
        {
            // أحدث 3 مراجعات
            var latestReviews = reviews
                .OrderByDescending(r => r.CreatedAt)
                .Take(3)
                .ToList();

            summary.LatestReviews = await ConvertToClientReviewDtos(latestReviews, cancellationToken);

            // أفضل 3 مراجعات (الأعلى تقييماً)
            var topReviews = reviews
                .OrderByDescending(r => r.AverageRating)
                .ThenByDescending(r => r.CreatedAt)
                .Take(3)
                .ToList();

            summary.TopReviews = await ConvertToClientReviewDtos(topReviews, cancellationToken);

            _logger.LogDebug("تم جلب أحدث {LatestCount} مراجعة وأفضل {TopCount} مراجعة", 
                summary.LatestReviews.Count, summary.TopReviews.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب أحدث المراجعات وأفضلها");
            summary.LatestReviews = new List<ClientReviewDto>();
            summary.TopReviews = new List<ClientReviewDto>();
        }
    }

    /// <summary>
    /// تحويل المراجعات إلى DTOs للعميل
    /// Convert reviews to client DTOs
    /// </summary>
    /// <param name="reviews">قائمة المراجعات</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة DTOs للعميل</returns>
    private async Task<List<ClientReviewDto>> ConvertToClientReviewDtos(List<Core.Entities.Review> reviews, CancellationToken cancellationToken)
    {
        var clientReviews = new List<ClientReviewDto>();

        foreach (var review in reviews)
        {
            try
            {
                // جلب بيانات المستخدم
                var user = review.Booking?.User;
                var userName = user?.Name ?? "مستخدم مجهول";
                var userAvatar = user?.ProfileImageUrl;

                var clientReview = new ClientReviewDto
                {
                    Id = review.Id,
                    UserId = review.Booking?.UserId ?? Guid.Empty,
                    UserName = userName,
                    UserAvatar = userAvatar,
                    Rating = (int)Math.Round(review.AverageRating),
                    // Title removed: entity lacks Title property
                    //Title = review.Title ?? string.Empty,
                    Comment = review.Comment ?? string.Empty,
                    CreatedAt = review.CreatedAt,
                    Images = review.Images?.Select(img => new ClientReviewImageDto
                    {
                        Id = img.Id,
                        Url = img.Url ?? string.Empty,
                        ThumbnailUrl = img.Url ?? string.Empty,
                        Caption = img.Caption,
                        DisplayOrder = img.DisplayOrder
                    }).OrderBy(img => img.DisplayOrder).ToList() ?? new List<ClientReviewImageDto>(),
                    IsUserReview = false, // يمكن تحديدها لاحقاً حسب المستخدم الحالي
                    LikesCount = 0, // يمكن إضافتها لاحقاً
                    IsLikedByUser = false,
                    ManagementReply = !string.IsNullOrEmpty(review.ResponseText) ? new ClientReviewReplyDto
                    {
                        Id = Guid.NewGuid(),
                        Content = review.ResponseText,
                        CreatedAt = review.ResponseDate ?? DateTime.UtcNow,
                        ReplierName = "إدارة العقار",
                        ReplierPosition = "ممثل خدمة العملاء"
                    } : null,
                    BookingType = "Standard",
                    IsRecommended = review.AverageRating >= 4
                };

                // Localize times
                clientReview.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(clientReview.CreatedAt);
                if (clientReview.ManagementReply != null)
                {
                    clientReview.ManagementReply.CreatedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(clientReview.ManagementReply.CreatedAt);
                }

                clientReviews.Add(clientReview);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "خطأ أثناء تحويل المراجعة: {ReviewId}", review.Id);
            }
        }

        return clientReviews;
    }

    /// <summary>
    /// استخراج الكلمات المفتاحية الشائعة
    /// Extract common keywords
    /// </summary>
    /// <param name="summary">ملخص المراجعات</param>
    /// <param name="reviews">قائمة المراجعات</param>
    private void ExtractCommonKeywords(ClientReviewsSummaryDto summary, List<Core.Entities.Review> reviews)
    {
        try
        {
            var allComments = reviews
                .Where(r => !string.IsNullOrWhiteSpace(r.Comment))
                .Select(r => r.Comment!)
                .ToList();

            if (!allComments.Any())
            {
                summary.CommonKeywords = new List<ClientReviewKeywordDto>();
                return;
            }

            // كلمات مفتاحية شائعة في المراجعات العربية
            var commonKeywords = new[]
            {
                "ممتاز", "رائع", "جيد", "سيء", "نظيف", "قذر", "مريح", "غير مريح",
                "خدمة", "موقع", "سعر", "جودة", "نظافة", "طعام", "غرفة", "حمام",
                "موظفين", "استقبال", "إفطار", "واي فاي", "مكيف", "سرير"
            };

            var keywordCounts = new Dictionary<string, int>();
            var totalWords = 0;

            foreach (var comment in allComments)
            {
                var words = Regex.Split(comment.ToLower(), @"\W+")
                    .Where(w => !string.IsNullOrWhiteSpace(w) && w.Length > 2)
                    .ToList();

                totalWords += words.Count;

                foreach (var keyword in commonKeywords)
                {
                    var count = words.Count(w => w.Contains(keyword.ToLower()));
                    if (count > 0)
                    {
                        keywordCounts[keyword] = keywordCounts.GetValueOrDefault(keyword, 0) + count;
                    }
                }
            }

            // أخذ أهم 10 كلمات مفتاحية
            summary.CommonKeywords = keywordCounts
                .Where(kv => kv.Value > 0)
                .OrderByDescending(kv => kv.Value)
                .Take(10)
                .Select(kv => new ClientReviewKeywordDto
                {
                    Keyword = kv.Key,
                    Count = kv.Value,
                    Percentage = totalWords > 0 ? Math.Round((decimal)kv.Value / totalWords * 100, 1) : 0,
                    Sentiment = DetermineSentiment(kv.Key)
                })
                .ToList();

            _logger.LogDebug("تم استخراج {Count} كلمة مفتاحية شائعة", summary.CommonKeywords.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء استخراج الكلمات المفتاحية");
            summary.CommonKeywords = new List<ClientReviewKeywordDto>();
        }
    }

    /// <summary>
    /// تحديد نوع المشاعر للكلمة المفتاحية
    /// Determine sentiment for keyword
    /// </summary>
    /// <param name="keyword">الكلمة المفتاحية</param>
    /// <returns>نوع المشاعر</returns>
    private string DetermineSentiment(string keyword)
    {
        var positiveKeywords = new[] { "ممتاز", "رائع", "جيد", "نظيف", "مريح", "جودة" };
        var negativeKeywords = new[] { "سيء", "قذر", "غير مريح" };

        if (positiveKeywords.Contains(keyword))
            return "Positive";
        else if (negativeKeywords.Contains(keyword))
            return "Negative";
        else
            return "Neutral";
    }

    /// <summary>
    /// حساب معدل الاستجابة من الإدارة
    /// Calculate management response rate
    /// </summary>
    /// <param name="summary">ملخص المراجعات</param>
    /// <param name="reviews">قائمة المراجعات</param>
    private void CalculateManagementResponseRate(ClientReviewsSummaryDto summary, List<Core.Entities.Review> reviews)
    {
        try
        {
            if (!reviews.Any())
            {
                summary.ManagementResponseRate = 0;
                return;
            }

            var reviewsWithResponse = reviews.Count(r => !string.IsNullOrWhiteSpace(r.ResponseText));
            summary.ManagementResponseRate = Math.Round((decimal)reviewsWithResponse / reviews.Count * 100, 1);

            _logger.LogDebug("معدل الاستجابة من الإدارة: {ResponseRate}%", summary.ManagementResponseRate);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حساب معدل الاستجابة من الإدارة");
            summary.ManagementResponseRate = 0;
        }
    }

    /// <summary>
    /// الحصول على ملخص فارغ للمراجعات
    /// Get empty reviews summary
    /// </summary>
    /// <returns>ملخص فارغ للمراجعات</returns>
    private ClientReviewsSummaryDto GetEmptyReviewsSummary()
    {
        var summary = new ClientReviewsSummaryDto();
        
        // تهيئة التوزيع بالقيم الافتراضية
        for (int i = 1; i <= 5; i++)
        {
            summary.RatingDistribution[i] = 0;
            summary.RatingPercentages[i] = 0;
        }

        return summary;
    }
}
