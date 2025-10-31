using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Bookings.Queries.GetUserBookingSummarySummary;

/// <summary>
/// معالج استعلام الحصول على ملخص حجوزات المستخدم
/// Handler for get user booking summary query
/// </summary>
public class GetUserBookingSummaryQueryHandler : IRequestHandler<GetUserBookingSummaryQuery, ResultDto<UserBookingSummaryDto>>
{
    private readonly IBookingRepository _bookingRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<GetUserBookingSummaryQueryHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج استعلام ملخص حجوزات المستخدم
    /// Constructor for get user booking summary query handler
    /// </summary>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetUserBookingSummaryQueryHandler(
        IBookingRepository bookingRepository,
        IPropertyRepository propertyRepository,
        IUserRepository userRepository,
        ILogger<GetUserBookingSummaryQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _bookingRepository = bookingRepository;
        _propertyRepository = propertyRepository;
        _userRepository = userRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة استعلام الحصول على ملخص حجوزات المستخدم
    /// Handle get user booking summary query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>ملخص حجوزات المستخدم</returns>
    public async Task<ResultDto<UserBookingSummaryDto>> Handle(GetUserBookingSummaryQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام ملخص حجوزات المستخدم. معرف المستخدم: {UserId}, السنة: {Year}", 
                request.UserId, request.Year ?? DateTime.Now.Year);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // التحقق من وجود المستخدم
            var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
            if (user == null)
            {
                _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", request.UserId);
                return ResultDto<UserBookingSummaryDto>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            // تحديد السنة المطلوبة
            var targetYear = request.Year ?? DateTime.Now.Year;

            // جلب ملخص الحجوزات الشهرية، وأكثر العقارات حجزاً، وأكثر المدن زيارة بشكل تسلسلي
            var monthlyBookings = await GetMonthlyBookingSummary(request.UserId, targetYear, cancellationToken);
            var topBookedProperties = await GetTopBookedProperties(request.UserId, 5, cancellationToken);
            var topVisitedCities = await GetTopVisitedCities(request.UserId, 5, cancellationToken);

            // إنشاء DTO للاستجابة
            var summaryDto = new UserBookingSummaryDto
            {
                MonthlyBookings = monthlyBookings,
                TopBookedProperties = topBookedProperties,
                TopVisitedCities = topVisitedCities
            };

            _logger.LogInformation("تم الحصول على ملخص حجوزات المستخدم بنجاح. معرف المستخدم: {UserId}", request.UserId);

            return ResultDto<UserBookingSummaryDto>.Ok(
                summaryDto, 
                "تم الحصول على ملخص حجوزات المستخدم بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على ملخص حجوزات المستخدم. معرف المستخدم: {UserId}", request.UserId);
            return ResultDto<UserBookingSummaryDto>.Failed(
                $"حدث خطأ أثناء الحصول على ملخص الحجوزات: {ex.Message}", 
                "GET_USER_BOOKING_SUMMARY_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<UserBookingSummaryDto> ValidateRequest(GetUserBookingSummaryQuery request)
    {
        if (request.UserId == Guid.Empty)
        {
            _logger.LogWarning("معرف المستخدم مطلوب");
            return ResultDto<UserBookingSummaryDto>.Failed("معرف المستخدم مطلوب", "USER_ID_REQUIRED");
        }

        if (request.Year.HasValue && (request.Year < 2020 || request.Year > DateTime.Now.Year + 1))
        {
            _logger.LogWarning("السنة المحددة غير صالحة: {Year}", request.Year);
            return ResultDto<UserBookingSummaryDto>.Failed("السنة المحددة غير صالحة", "INVALID_YEAR");
        }

        return ResultDto<UserBookingSummaryDto>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// الحصول على ملخص الحجوزات الشهرية
    /// Get monthly booking summary
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="year">السنة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة الحجوزات الشهرية</returns>
    private async Task<List<MonthlyBookingSummaryDto>> GetMonthlyBookingSummary(Guid userId, int year, CancellationToken cancellationToken)
    {
        var monthlyBookings = new List<MonthlyBookingSummaryDto>();

        for (int month = 1; month <= 12; month++)
        {
            // Build local boundary then convert to UTC for querying
            var localStart = new DateTime(year, month, 1, 0, 0, 0);
            var localEnd = localStart.AddMonths(1).AddMilliseconds(-1);
            var startDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(localStart);
            var endDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(localEnd);

            // استخدام دالة محددة للحصول على حجوزات المستخدم في فترة زمنية
            var userBookings = await _bookingRepository.GetBookingsByUserAsync(userId, cancellationToken);
            var bookings = userBookings?.Where(b => 
                b.CheckIn >= startDate && 
                b.CheckOut <= endDate);

            var bookingsCount = bookings?.Count() ?? 0;
            var amountSpent = bookings?.Sum(b => b.TotalPrice.Amount) ?? 0;

            monthlyBookings.Add(new MonthlyBookingSummaryDto
            {
                Month = month,
                Year = year,
                BookingsCount = bookingsCount,
                AmountSpent = amountSpent
            });
        }

        return monthlyBookings;
    }

    /// <summary>
    /// الحصول على أكثر العقارات حجزاً
    /// Get top booked properties
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="limit">الحد الأقصى للنتائج</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة أكثر العقارات حجزاً</returns>
    private async Task<List<PropertyBookingFrequencyDto>> GetTopBookedProperties(Guid userId, int limit, CancellationToken cancellationToken)
    {
        var allBookings = await _bookingRepository.GetAllAsync(cancellationToken);
        var userBookings = allBookings?.Where(b => b.UserId == userId);
        var topProperties = userBookings?
            .GroupBy(b => b.Unit.PropertyId)
            .OrderByDescending(g => g.Count())
            .Take(limit)
            .Select(g => g.First().Unit.Property);
        
        if (topProperties == null || !topProperties.Any())
        {
            return new List<PropertyBookingFrequencyDto>();
        }

        var result = new List<PropertyBookingFrequencyDto>();

        foreach (var property in topProperties)
        {
            result.Add(new PropertyBookingFrequencyDto
            {
                PropertyName = property?.Name ?? "غير متاح",
                City = property?.City ?? "غير متاح",
                BookingsCount = userBookings?.Count(b => b.Unit.PropertyId == property.Id) ?? 0
            });
        }

        return result.OrderByDescending(p => p.BookingsCount).ToList();
    }

    /// <summary>
    /// الحصول على أكثر المدن زيارة
    /// Get top visited cities
    /// </summary>
    /// <param name="userId">معرف المستخدم</param>
    /// <param name="limit">الحد الأقصى للنتائج</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة أكثر المدن زيارة</returns>
    private async Task<List<CityVisitFrequencyDto>> GetTopVisitedCities(Guid userId, int limit, CancellationToken cancellationToken)
    {
        var allBookings = await _bookingRepository.GetAllAsync(cancellationToken);
        var userBookings = allBookings?.Where(b => b.UserId == userId);
        var topCities = userBookings?
            .GroupBy(b => b.Unit.Property.City)
            .OrderByDescending(g => g.Count())
            .Take(limit)
            .Select(g => g.Key);
        
        if (topCities == null || !topCities.Any())
        {
            return new List<CityVisitFrequencyDto>();
        }

        return topCities.Select(city => new CityVisitFrequencyDto
        {
            CityName = city ?? "غير متاح",
            VisitsCount = userBookings?.Count(b => b.Unit.Property.City == city) ?? 0
        }).OrderByDescending(c => c.VisitsCount).ToList();
    }
}
