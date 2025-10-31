using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Enums;
using Microsoft.EntityFrameworkCore;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;
using YemenBooking.Application.Features.Bookings.DTOs;

namespace YemenBooking.Application.Features.Bookings.Queries.GetUserBookings;

/// <summary>
/// معالج استعلام الحصول على حجوزات المستخدم
/// Handler for get user bookings query
/// </summary>
public class GetUserBookingsQueryHandler : IRequestHandler<GetUserBookingsQuery, ResultDto<PaginatedResult<BookingDto>>>
{
    private readonly IBookingRepository _bookingRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IUserRepository _userRepository;
    private readonly ILogger<GetUserBookingsQueryHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج استعلام حجوزات المستخدم
    /// Constructor for get user bookings query handler
    /// </summary>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="unitRepository">مستودع الوحدات</param>
    /// <param name="userRepository">مستودع المستخدمين</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetUserBookingsQueryHandler(
        IBookingRepository bookingRepository,
        IPropertyRepository propertyRepository,
        IUnitRepository unitRepository,
        IUserRepository userRepository,
        ILogger<GetUserBookingsQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _bookingRepository = bookingRepository;
        _propertyRepository = propertyRepository;
        _unitRepository = unitRepository;
        _userRepository = userRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة استعلام الحصول على حجوزات المستخدم
    /// Handle get user bookings query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة حجوزات المستخدم</returns>
    public async Task<ResultDto<PaginatedResult<BookingDto>>> Handle(GetUserBookingsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام حجوزات المستخدم. معرف المستخدم: {UserId}, الحالة: {Status}, الصفحة: {PageNumber}", 
                request.UserId, request.Status?.ToString() ?? "جميع الحالات", request.PageNumber);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return ResultDto<PaginatedResult<BookingDto>>.Failed(validationResult.Message ?? "", validationResult.ErrorCode);
            }

            // التحقق من وجود المستخدم
            var user = await _userRepository.GetByIdAsync(request.UserId, cancellationToken);
            if (user == null)
            {
                _logger.LogWarning("لم يتم العثور على المستخدم: {UserId}", request.UserId);
                return ResultDto<PaginatedResult<BookingDto>>.Failed("المستخدم غير موجود", "USER_NOT_FOUND");
            }

            // بناء الاستعلام على مستوى قاعدة البيانات لتجنب التوازي على نفس DbContext
            var pageNumber = request.PageNumber < 1 ? 1 : request.PageNumber;
            var pageSize = request.PageSize < 1 ? 10 : request.PageSize;

            var query = _bookingRepository.GetQueryable()
                .AsNoTracking()
                .AsSplitQuery()
                .Where(b => b.UserId == request.UserId);
            
            if (request.Status.HasValue)
            {
                query = query.Where(b => b.Status == request.Status.Value);
            }
            
            var totalCount = await query.CountAsync(cancellationToken);

            var pageItems = await query
                .Include(b => b.Unit)
                    .ThenInclude(u => u.Property)
                        .ThenInclude(p => p.Images)
                .OrderByDescending(b => b.BookedAt)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            if (pageItems.Count == 0)
            {
                _logger.LogInformation("لم يتم العثور على حجوزات للمستخدم: {UserId}", request.UserId);
                return ResultDto<PaginatedResult<BookingDto>>.Ok(
                    new PaginatedResult<BookingDto>
                    {
                        Items = new List<BookingDto>(),
                        TotalCount = 0,
                        PageNumber = pageNumber,
                        PageSize = pageSize
                    }, 
                    "لا توجد حجوزات متاحة"
                );
            }

            // تحويل إلى DTO بدون تشغيل عمليات قاعدة بيانات متوازية
            var bookingDtos = pageItems.Select(booking =>
            {
                var unit = booking.Unit;
                var property = unit?.Property;
                var propertyImageUrl = property?.Images?.FirstOrDefault()?.Url ?? string.Empty;
                return new BookingDto
                {
                    Id = booking.Id,
                    BookingNumber = $"BK-{booking.Id.ToString().Substring(0, 8)}",
                    PropertyName = property?.Name ?? "غير متاح",
                    UnitName = unit?.Name ?? "غير متاح",
                    CheckIn = booking.CheckIn,
                    CheckOut = booking.CheckOut,
                    GuestsCount = booking.GuestsCount,
                    TotalPrice = booking.TotalPrice,
                    Currency = booking.TotalPrice.Currency ?? "YER",
                    Status = booking.Status,
                    BookedAt = booking.BookedAt,
                    PropertyImageUrl = propertyImageUrl,
                    CanCancel = CanCancelBooking(booking),
                    CanReview = CanReviewBooking(booking)
                };
            })
                .ToList();

            // Convert all datetime fields from UTC to user's local time
            for (int i = 0; i < bookingDtos.Count; i++)
            {
                bookingDtos[i].BookedAt = await _currentUserService.ConvertFromUtcToUserLocalAsync(bookingDtos[i].BookedAt);
                bookingDtos[i].CheckIn = await _currentUserService.ConvertFromUtcToUserLocalAsync(bookingDtos[i].CheckIn);
                bookingDtos[i].CheckOut = await _currentUserService.ConvertFromUtcToUserLocalAsync(bookingDtos[i].CheckOut);
            }

            // حساب إجمالي عدد الصفحات
            var totalPages = (int)Math.Ceiling((double)totalCount / request.PageSize);

            var response = new PaginatedResult<BookingDto>
            {
                Items = bookingDtos,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };

            _logger.LogInformation("تم الحصول على {Count} حجز للمستخدم {UserId} بنجاح", bookingDtos.Count, request.UserId);

            return ResultDto<PaginatedResult<BookingDto>>.Ok(
                response,
                $"تم الحصول على {bookingDtos.Count} حجز من أصل {totalCount}"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على حجوزات المستخدم. معرف المستخدم: {UserId}", request.UserId);
            return ResultDto<PaginatedResult<BookingDto>>.Failed(
                $"حدث خطأ أثناء الحصول على الحجوزات: {ex.Message}", 
                "GET_USER_BOOKINGS_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<PaginatedResult<BookingDto>> ValidateRequest(GetUserBookingsQuery request)
    {
        if (request.UserId == Guid.Empty)
        {
            _logger.LogWarning("معرف المستخدم مطلوب");
            return ResultDto<PaginatedResult<BookingDto>>.Failed("معرف المستخدم مطلوب", "USER_ID_REQUIRED");
        }

        if (request.PageNumber < 1)
        {
            _logger.LogWarning("رقم الصفحة يجب أن يكون أكبر من صفر");
            return ResultDto<PaginatedResult<BookingDto>>.Failed("رقم الصفحة يجب أن يكون أكبر من صفر", "INVALID_PAGE_NUMBER");
        }

        if (request.PageSize < 1 || request.PageSize > 100)
        {
            _logger.LogWarning("حجم الصفحة يجب أن يكون بين 1 و 100");
            return ResultDto<PaginatedResult<BookingDto>>.Failed("حجم الصفحة يجب أن يكون بين 1 و 100", "INVALID_PAGE_SIZE");
        }

        return ResultDto<PaginatedResult<BookingDto>>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// تحديد إمكانية إلغاء الحجز
    /// Determine if booking can be cancelled
    /// </summary>
    /// <param name="booking">الحجز</param>
    /// <returns>هل يمكن الإلغاء</returns>
    private bool CanCancelBooking(Core.Entities.Booking booking)
    {
        // يمكن إلغاء الحجز إذا كان في حالة مؤكد أو معلق وقبل تاريخ الوصول بـ 24 ساعة على الأقل
        return (booking.Status == BookingStatus.Confirmed || booking.Status == BookingStatus.Pending) &&
               booking.CheckIn > DateTime.UtcNow.AddHours(24);
    }

    /// <summary>
    /// تحديد إمكانية تقييم الحجز
    /// Determine if booking can be reviewed
    /// </summary>
    /// <param name="booking">الحجز</param>
    /// <returns>هل يمكن التقييم</returns>
    private bool CanReviewBooking(Core.Entities.Booking booking)
    {
        // يمكن تقييم الحجز إذا كان مكتمل وبعد تاريخ المغادرة
        return booking.Status == BookingStatus.Completed && 
               booking.CheckOut <= DateTime.UtcNow &&
               booking.CustomerRating == null; // لم يتم التقييم بعد
    }
}
