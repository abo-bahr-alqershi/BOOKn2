using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Properties.Queries.GetCheckPropertyAvailability;

/// <summary>
/// معالج استعلام التحقق من توفر العقار
/// Handler for check property availability query
/// </summary>
public class CheckPropertyAvailabilityQueryHandler : IRequestHandler<CheckPropertyAvailabilityQuery, ResultDto<PropertyAvailabilityResponse>>
{
    private readonly IPropertyRepository _propertyRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IUnitTypeRepository _unitTypeRepository;
    private readonly ILogger<CheckPropertyAvailabilityQueryHandler> _logger;

    /// <summary>
    /// منشئ معالج استعلام التحقق من توفر العقار
    /// Constructor for check property availability query handler
    /// </summary>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="unitRepository">مستودع الوحدات</param>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="unitTypeRepository">مستودع أنواع الوحدات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public CheckPropertyAvailabilityQueryHandler(
        IPropertyRepository propertyRepository,
        IUnitRepository unitRepository,
        IBookingRepository bookingRepository,
        IUnitTypeRepository unitTypeRepository,
        ILogger<CheckPropertyAvailabilityQueryHandler> logger)
    {
        _propertyRepository = propertyRepository;
        _unitRepository = unitRepository;
        _bookingRepository = bookingRepository;
        _unitTypeRepository = unitTypeRepository;
        _logger = logger;
    }

    /// <summary>
    /// معالجة استعلام التحقق من توفر العقار
    /// Handle check property availability query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>معلومات توفر العقار</returns>
    public async Task<ResultDto<PropertyAvailabilityResponse>> Handle(CheckPropertyAvailabilityQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء التحقق من توفر العقار. معرف العقار: {PropertyId}, تاريخ الوصول: {CheckIn}, تاريخ المغادرة: {CheckOut}, عدد الضيوف: {GuestsCount}", 
                request.PropertyId, request.CheckInDate, request.CheckOutDate, request.GuestsCount);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // التحقق من وجود العقار
            var property = await _propertyRepository.GetByIdAsync(request.PropertyId, cancellationToken);
            if (property == null)
            {
                _logger.LogWarning("لم يتم العثور على العقار: {PropertyId}", request.PropertyId);
                return ResultDto<PropertyAvailabilityResponse>.Failed("العقار غير موجود", "PROPERTY_NOT_FOUND");
            }

            // التحقق من أن العقار نشط
            if (!property.IsActive)
            {
                _logger.LogWarning("العقار غير نشط: {PropertyId}", request.PropertyId);
                
                var inactiveResponse = new PropertyAvailabilityResponse
                {
                    HasAvailableUnits = false,
                    AvailableUnitsCount = 0,
                    MinAvailablePrice = null,
                    Currency = "YER", // قيمة افتراضية - خاصية Currency غير متوفرة
                    Message = "العقار غير متاح حالياً",
                    AvailableUnitTypes = new List<string>()
                };

                return ResultDto<PropertyAvailabilityResponse>.Ok(inactiveResponse, "العقار غير متاح حالياً");
            }

            // الحصول على جميع الوحدات في العقار
            var allUnits = await _unitRepository.GetByPropertyIdAsync(request.PropertyId, cancellationToken);
            if (allUnits == null || !allUnits.Any())
            {
                _logger.LogInformation("لا توجد وحدات في العقار: {PropertyId}", request.PropertyId);
                
                var noUnitsResponse = new PropertyAvailabilityResponse
                {
                    HasAvailableUnits = false,
                    AvailableUnitsCount = 0,
                    MinAvailablePrice = null,
                    Currency = "YER", // قيمة افتراضية - خاصية Currency غير متوفرة
                    Message = "لا توجد وحدات في هذا العقار",
                    AvailableUnitTypes = new List<string>()
                };

                return ResultDto<PropertyAvailabilityResponse>.Ok(noUnitsResponse, "لا توجد وحدات في هذا العقار");
            }

            // فلترة الوحدات النشطة والتي تتسع للعدد المطلوب من الضيوف
            var eligibleUnits = allUnits
                .Where(u => u.IsActive && u.MaxCapacity >= request.GuestsCount)
                .ToList();

            if (!eligibleUnits.Any())
            {
                _logger.LogInformation("لا توجد وحدات تتسع لـ {GuestsCount} ضيف في العقار: {PropertyId}", 
                    request.GuestsCount, request.PropertyId);
                
                var noCapacityResponse = new PropertyAvailabilityResponse
                {
                    HasAvailableUnits = false,
                    AvailableUnitsCount = 0,
                    MinAvailablePrice = null,
                    Currency = "YER", // قيمة افتراضية - خاصية Currency غير متوفرة
                    Message = $"لا توجد وحدات تتسع لـ {request.GuestsCount} ضيف",
                    AvailableUnitTypes = new List<string>()
                };

                return ResultDto<PropertyAvailabilityResponse>.Ok(noCapacityResponse, $"لا توجد وحدات تتسع لـ {request.GuestsCount} ضيف");
            }

            // فلترة الوحدات المتاحة وحساب الأسعار والأنواع بشكل تسلسلي لتجنب مشاركة DbContext بين المهام
            var filteredResults = new List<AvailabilityResult>();
            foreach (var unit in eligibleUnits)
            {
                var isAvailable = await IsUnitAvailable(unit.Id, request.CheckInDate, request.CheckOutDate, cancellationToken);
                if (!isAvailable) continue;
                var unitType = await _unitTypeRepository.GetByIdAsync(unit.UnitTypeId, cancellationToken);
                var unitPrice = await CalculateUnitPrice(unit, request.CheckInDate, request.CheckOutDate, cancellationToken);
                filteredResults.Add(new AvailabilityResult { Unit = unit, UnitTypeName = unitType?.Name, Price = unitPrice });
            }
            var availableUnits = filteredResults.Select(r => r.Unit).ToList();
            var availableUnitTypes = filteredResults
                .Select(r => r.UnitTypeName)
                .Where(name => !string.IsNullOrEmpty(name))
                .Select(name => name!)
                .ToList();
            var prices = filteredResults.Select(r => r.Price).Where(price => price > 0).ToList();
            // إنشاء الاستجابة
            var response = new PropertyAvailabilityResponse
            {
                HasAvailableUnits = availableUnits.Any(),
                AvailableUnitsCount = availableUnits.Count,
                MinAvailablePrice = prices.Any() ? prices.Min() : null,
                Currency = property.Currency ?? "YER",
                Message = availableUnits.Any() 
                    ? $"يوجد {availableUnits.Count} وحدة متاحة"
                    : "لا توجد وحدات متاحة في الفترة المحددة",
                AvailableUnitTypes = availableUnitTypes.ToList()
            };

            _logger.LogInformation("تم التحقق من توفر العقار {PropertyId}. الوحدات المتاحة: {AvailableCount}, أقل سعر: {MinPrice}", 
                request.PropertyId, response.AvailableUnitsCount, response.MinAvailablePrice);

            return ResultDto<PropertyAvailabilityResponse>.Ok(response, response.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء التحقق من توفر العقار. معرف العقار: {PropertyId}", request.PropertyId);
            return ResultDto<PropertyAvailabilityResponse>.Failed(
                $"حدث خطأ أثناء التحقق من توفر العقار: {ex.Message}", 
                "CHECK_AVAILABILITY_ERROR"
            );
        }
    }

    private sealed class AvailabilityResult
    {
        public Core.Entities.Unit Unit { get; set; } = default!;
        public string? UnitTypeName { get; set; }
        public decimal Price { get; set; }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<PropertyAvailabilityResponse> ValidateRequest(CheckPropertyAvailabilityQuery request)
    {
        if (request.PropertyId == Guid.Empty)
        {
            _logger.LogWarning("معرف العقار مطلوب");
            return ResultDto<PropertyAvailabilityResponse>.Failed("معرف العقار مطلوب", "PROPERTY_ID_REQUIRED");
        }

        if (request.CheckInDate >= request.CheckOutDate)
        {
            _logger.LogWarning("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة");
            return ResultDto<PropertyAvailabilityResponse>.Failed("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة", "INVALID_DATE_RANGE");
        }

        if (request.CheckInDate.Date < DateTime.Today)
        {
            _logger.LogWarning("تاريخ الوصول لا يمكن أن يكون في الماضي");
            return ResultDto<PropertyAvailabilityResponse>.Failed("تاريخ الوصول لا يمكن أن يكون في الماضي", "INVALID_CHECKIN_DATE");
        }

        if (request.GuestsCount < 1 || request.GuestsCount > 50)
        {
            _logger.LogWarning("عدد الضيوف يجب أن يكون بين 1 و 50");
            return ResultDto<PropertyAvailabilityResponse>.Failed("عدد الضيوف يجب أن يكون بين 1 و 50", "INVALID_GUESTS_COUNT");
        }

        // التحقق من أن الفترة لا تتجاوز سنة واحدة
        var daysDifference = (request.CheckOutDate - request.CheckInDate).Days;
        if (daysDifference > 365)
        {
            _logger.LogWarning("فترة الإقامة لا يمكن أن تتجاوز سنة واحدة");
            return ResultDto<PropertyAvailabilityResponse>.Failed("فترة الإقامة لا يمكن أن تتجاوز سنة واحدة", "INVALID_STAY_DURATION");
        }

        if (daysDifference < 1)
        {
            _logger.LogWarning("فترة الإقامة يجب أن تكون ليلة واحدة على الأقل");
            return ResultDto<PropertyAvailabilityResponse>.Failed("فترة الإقامة يجب أن تكون ليلة واحدة على الأقل", "INVALID_STAY_DURATION");
        }

        return ResultDto<PropertyAvailabilityResponse>.Ok(null, "البيانات صحيحة");
    }

    /// <summary>
    /// التحقق من توفر الوحدة في الفترة المحددة
    /// Check if unit is available for the specified period
    /// </summary>
    /// <param name="unitId">معرف الوحدة</param>
    /// <param name="checkIn">تاريخ الوصول</param>
    /// <param name="checkOut">تاريخ المغادرة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>هل الوحدة متاحة</returns>
    private async Task<bool> IsUnitAvailable(Guid unitId, DateTime checkIn, DateTime checkOut, CancellationToken cancellationToken)
    {
        try
        {
            // البحث عن حجوزات متضاربة
            var conflictingBookings = await _bookingRepository.GetConflictingBookingsAsync(
                unitId, checkIn, checkOut, cancellationToken);

            return conflictingBookings == null || !conflictingBookings.Any();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء التحقق من توفر الوحدة: {UnitId}", unitId);
            // في حالة الخطأ، نعتبر الوحدة غير متاحة للأمان
            return false;
        }
    }

    /// <summary>
    /// حساب سعر الوحدة للفترة المحددة
    /// Calculate unit price for the specified period
    /// </summary>
    /// <param name="unit">الوحدة</param>
    /// <param name="checkIn">تاريخ الوصول</param>
    /// <param name="checkOut">تاريخ المغادرة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>السعر الإجمالي</returns>
    private async Task<decimal> CalculateUnitPrice(Core.Entities.Unit unit, DateTime checkIn, DateTime checkOut, CancellationToken cancellationToken)
    {
        try
        {
            var nights = (checkOut - checkIn).Days;
            var basePrice = unit.BasePrice;

            // حساب السعر الأساسي
            var totalPrice = basePrice * nights;

            // تطبيق أي خصومات
            if (unit.DiscountPercentage > 0)
            {
                var discountAmount = totalPrice * (unit.DiscountPercentage / 100);
                totalPrice -= discountAmount;
            }

            // يمكن إضافة منطق أكثر تعقيداً هنا لحساب الأسعار الموسمية أو العروض الخاصة
            // مثل الحصول على أسعار خاصة من جدول منفصل

            return Math.Max(0, totalPrice); // التأكد من أن السعر لا يكون سالباً
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء حساب سعر الوحدة: {UnitId}", unit.Id);
            return unit.BasePrice; // إرجاع السعر الأساسي في حالة الخطأ
        }
    }
}
