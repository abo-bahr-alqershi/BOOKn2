using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Users;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Features.Users.DTOs;
using YemenBooking.Core.Entities;

namespace YemenBooking.Application.Features.Users.Queries.GetUserStatisticsStatistics;

/// <summary>
/// معالج استعلام الحصول على إحصائيات المستخدم
/// Handler for get user statistics query
/// </summary>
public class GetUserStatisticsQueryHandler : IRequestHandler<GetUserStatisticsQuery, ResultDto<UserStatisticsDto>>
{
    private readonly IUserRepository _userRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IReviewRepository _reviewRepository;
    private readonly IFavoriteRepository _favoriteRepository;
    private readonly IPaymentRepository _paymentRepository;
    private readonly ILogger<GetUserStatisticsQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام إحصائيات المستخدم
    /// Constructor for get user statistics query handler
    /// </summary>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="reviewRepository">مستودع المراجعات</param>
    /// <param name="favoriteRepository">مستودع المفضلات</param>
    /// <param name="paymentRepository">مستودع المدفوعات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetUserStatisticsQueryHandler(
        IUserRepository userRepository,
        IBookingRepository bookingRepository,
        IReviewRepository reviewRepository,
        IFavoriteRepository favoriteRepository,
        IPaymentRepository paymentRepository,
        ILogger<GetUserStatisticsQueryHandler> logger)
    {
        _userRepository = userRepository;
        _bookingRepository = bookingRepository;
        _reviewRepository = reviewRepository;
        _favoriteRepository = favoriteRepository;
        _paymentRepository = paymentRepository;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام الحصول على إحصائيات المستخدم
    /// Handle get user statistics query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>إحصائيات المستخدم</returns>
    public async Task<ResultDto<UserStatisticsDto>> Handle(GetUserStatisticsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام إحصائيات المستخدم. معرف المستخدم: {UserId}", request.UserId);

            // التحقق من وجود المستخدم
            var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
            if (user == null)
            {
                _logger.LogWarning("المستخدم غير موجود. معرف المستخدم: {UserId}", request.UserId);
                return ResultDto<UserStatisticsDto>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            var statistics = new UserStatisticsDto
            {
                MemberSince = user.CreatedAt
            };

            // جلب إحصائيات الحجوزات
            await PopulateBookingStatistics(statistics, request.UserId, cancellationToken);

            // جلب إحصائيات المراجعات
            await PopulateReviewStatistics(statistics, request.UserId, cancellationToken);

            // جلب إحصائيات المفضلات
            await PopulateFavoriteStatistics(statistics, request.UserId, cancellationToken);

            // جلب إحصائيات المدفوعات
            await PopulatePaymentStatistics(statistics, request.UserId, cancellationToken);

            // حساب فئة الولاء ونقاط الولاء
            CalculateLoyaltyInfo(statistics);

            _logger.LogInformation("تم جلب إحصائيات المستخدم بنجاح. إجمالي الحجوزات: {TotalBookings}, المراجعات: {ReviewsWritten}, المفضلات: {FavoritePropertiesCount}", 
                statistics.TotalBookings, statistics.ReviewsWritten, statistics.FavoritePropertiesCount);

            return ResultDto<UserStatisticsDto>.Ok(statistics, "تم جلب إحصائيات المستخدم بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب إحصائيات المستخدم. معرف المستخدم: {UserId}", request.UserId);
            return ResultDto<UserStatisticsDto>.Failed(
                $"حدث خطأ أثناء جلب إحصائيات المستخدم: {ex.Message}", 
                "GET_USER_STATISTICS_ERROR"
            );
        }
    }

    /// <summary>
    /// جلب إحصائيات الحجوزات
    /// Populate booking statistics
    /// </summary>
    /// <param name="statistics">بيانات الإحصائيات</param>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    private async Task PopulateBookingStatistics(UserStatisticsDto statistics, Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var userBookings = await _bookingRepository.GetByUserIdAsync(userId, cancellationToken);
            
            if (userBookings != null && userBookings.Any())
            {
                statistics.TotalBookings = userBookings.Count();
                statistics.CompletedBookings = userBookings.Count(b => b.Status == BookingStatus.Completed);
                statistics.ActiveBookings = userBookings.Count(b => 
                    b.Status == BookingStatus.Confirmed || 
                    b.Status == BookingStatus.CheckedIn);
                statistics.CancelledBookings = userBookings.Count(b => b.Status == BookingStatus.Cancelled);

                // حساب المدن التي تمت زيارتها
                var visitedCities = userBookings
                    .Where(b => b.Status == BookingStatus.Completed && 
                               b.Unit?.Property != null && 
                               !string.IsNullOrWhiteSpace(b.Unit.Property.City))
                    .Select(b => b.Unit!.Property!.City!)
                    .Distinct()
                    .Count();

                statistics.CitiesVisited = visitedCities;
            }

            _logger.LogDebug("تم جلب إحصائيات الحجوزات. إجمالي: {Total}, مكتملة: {Completed}, نشطة: {Active}, ملغية: {Cancelled}", 
                statistics.TotalBookings, statistics.CompletedBookings, statistics.ActiveBookings, statistics.CancelledBookings);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب إحصائيات الحجوزات للمستخدم: {UserId}", userId);
        }
    }

    /// <summary>
    /// جلب إحصائيات المراجعات
    /// Populate review statistics
    /// </summary>
    /// <param name="statistics">بيانات الإحصائيات</param>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    private async Task PopulateReviewStatistics(UserStatisticsDto statistics, Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var userReviews = await _reviewRepository.GetByUserIdAsync(userId, cancellationToken);
            
            if (userReviews != null)
            {
                statistics.ReviewsWritten = userReviews.Count();
            }

            _logger.LogDebug("تم جلب إحصائيات المراجعات. عدد المراجعات: {ReviewsCount}", statistics.ReviewsWritten);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب إحصائيات المراجعات للمستخدم: {UserId}", userId);
        }
    }

    /// <summary>
    /// جلب إحصائيات المفضلات
    /// Populate favorite statistics
    /// </summary>
    /// <param name="statistics">بيانات الإحصائيات</param>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    private async Task PopulateFavoriteStatistics(UserStatisticsDto statistics, Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var userFavorites = await _favoriteRepository.GetByUserIdAsync(userId, cancellationToken);
            
            if (userFavorites != null)
            {
                statistics.FavoritePropertiesCount = userFavorites.Count();
            }

            _logger.LogDebug("تم جلب إحصائيات المفضلات. عدد المفضلات: {FavoritesCount}", statistics.FavoritePropertiesCount);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب إحصائيات المفضلات للمستخدم: {UserId}", userId);
        }
    }

    /// <summary>
    /// جلب إحصائيات المدفوعات
    /// Populate payment statistics
    /// </summary>
    /// <param name="statistics">بيانات الإحصائيات</param>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    private async Task PopulatePaymentStatistics(UserStatisticsDto statistics, Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var allPayments = await _paymentRepository.GetAllAsync(cancellationToken);
            var userPayments = allPayments.Where(p => p.Booking != null && p.Booking.UserId == userId);
            
            if (userPayments != null && userPayments.Any())
            {
                // حساب إجمالي المبلغ المنفق (المدفوعات المكتملة فقط)
                var completedPayments = userPayments.Where(p => p.Status == Core.Enums.PaymentStatus.Successful);
                
                statistics.TotalSpent = completedPayments.Sum(p => p.Amount.Amount);
                statistics.Currency = completedPayments.FirstOrDefault()?.Amount.Currency ?? "YER";

                // حساب المبلغ الموفر من الخصومات (تنفيذ مبسط)
                statistics.TotalSaved = 0; // سيتم تنفيذه لاحقاً عند توفر خاصية الخصم
            }

            _logger.LogDebug("تم جلب إحصائيات المدفوعات. إجمالي المنفق: {TotalSpent} {Currency}, الموفر: {TotalSaved}", 
                statistics.TotalSpent, statistics.Currency, statistics.TotalSaved);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء جلب إحصائيات المدفوعات للمستخدم: {UserId}", userId);
            statistics.Currency = "YER";
        }
    }

    /// <summary>
    /// حساب معلومات الولاء
    /// Calculate loyalty information
    /// </summary>
    /// <param name="statistics">بيانات الإحصائيات</param>
    private void CalculateLoyaltyInfo(UserStatisticsDto statistics)
    {
        try
        {
            // حساب نقاط الولاء بناءً على النشاط
            var loyaltyPoints = 0;

            // نقاط للحجوزات المكتملة (10 نقاط لكل حجز)
            loyaltyPoints += statistics.CompletedBookings * 10;

            // نقاط للمراجعات (5 نقاط لكل مراجعة)
            loyaltyPoints += statistics.ReviewsWritten * 5;

            // نقاط للمبلغ المنفق (نقطة واحدة لكل 1000 وحدة عملة)
            loyaltyPoints += (int)(statistics.TotalSpent / 1000);

            statistics.LoyaltyPoints = loyaltyPoints;

            // تحديد فئة الولاء (يمكن إضافة هذه الخاصية لاحقاً إلى UserStatisticsDto)
            var loyaltyTier = loyaltyPoints switch
            {
                >= 1000 => "بلاتيني",
                >= 500 => "ذهبي",
                >= 200 => "فضي",
                >= 50 => "برونزي",
                _ => "عادي"
            };

            _logger.LogDebug("تم حساب معلومات الولاء. النقاط: {LoyaltyPoints}, الفئة: {LoyaltyTier}", 
                statistics.LoyaltyPoints, loyaltyTier);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حساب معلومات الولاء");
            statistics.LoyaltyPoints = 0;
            // statistics.LoyaltyTier = "عادي"; // خاصية غير موجودة
        }
    }
}
