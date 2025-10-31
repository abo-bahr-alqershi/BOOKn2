using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using System.Text.Json;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.GetAvailableUnits;

/// <summary>
/// معالج استعلام الحصول على الوحدات المتاحة
/// Handler for get available units query
/// </summary>
public class GetAvailableUnitsQueryHandler : IRequestHandler<GetAvailableUnitsQuery, ResultDto<AvailableUnitsResponse>>
{
    private readonly IUnitRepository _unitRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IUnitTypeRepository _unitTypeRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IPropertyImageRepository _propertyImageRepository;
    private readonly IUnitFieldValueRepository _unitFieldValueRepository;
    private readonly ILogger<GetAvailableUnitsQueryHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج استعلام الوحدات المتاحة
    /// Constructor for get available units query handler
    /// </summary>
    /// <param name="unitRepository">مستودع الوحدات</param>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="unitTypeRepository">مستودع أنواع الوحدات</param>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="propertyImageRepository">مستودع صور العقارات والوحدات</param>
    /// <param name="unitFieldValueRepository">مستودع قيم حقول الوحدات</param>
    /// <param name="logger">مسجل الأحداث</param>
    public GetAvailableUnitsQueryHandler(
        IUnitRepository unitRepository,
        IPropertyRepository propertyRepository,
        IUnitTypeRepository unitTypeRepository,
        IBookingRepository bookingRepository,
        IPropertyImageRepository propertyImageRepository,
        IUnitFieldValueRepository unitFieldValueRepository,
        ILogger<GetAvailableUnitsQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _unitRepository = unitRepository;
        _propertyRepository = propertyRepository;
        _unitTypeRepository = unitTypeRepository;
        _bookingRepository = bookingRepository;
        _propertyImageRepository = propertyImageRepository;
        _unitFieldValueRepository = unitFieldValueRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة استعلام الحصول على الوحدات المتاحة
    /// Handle get available units query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>قائمة الوحدات المتاحة</returns>
    public async Task<ResultDto<AvailableUnitsResponse>> Handle(GetAvailableUnitsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام الوحدات المتاحة. معرف العقار: {PropertyId}, تاريخ الوصول: {CheckIn}, تاريخ المغادرة: {CheckOut}, عدد الضيوف: {GuestsCount}", 
                request.PropertyId, request.CheckIn.GetValueOrDefault(), request.CheckOut.GetValueOrDefault(), request.GuestsCount);

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
                return ResultDto<AvailableUnitsResponse>.Failed("العقار غير موجود", "PROPERTY_NOT_FOUND");
            }

            // التحقق من أن العقار نشط
            if (!property.IsActive)
            {
                _logger.LogWarning("العقار غير نشط: {PropertyId}", request.PropertyId);
                return ResultDto<AvailableUnitsResponse>.Failed("العقار غير متاح حالياً", "PROPERTY_INACTIVE");
            }

            // الحصول على جميع الوحدات في العقار
            var allUnits = await _unitRepository.GetByPropertyIdAsync(request.PropertyId, cancellationToken);
            if (allUnits == null || !allUnits.Any())
            {
                _logger.LogInformation("لا توجد وحدات في العقار: {PropertyId}", request.PropertyId);
                
                return ResultDto<AvailableUnitsResponse>.Ok(
                    new AvailableUnitsResponse
                    {
                        Units = new List<AvailableUnitDto>(),
                        TotalAvailable = 0
                    }, 
                    "لا توجد وحدات متاحة في هذا العقار"
                );
            }

            // فلترة الوحدات النشطة والتي تتسع للعدد المطلوب من الضيوف
            var eligibleUnits = allUnits
                .Where(u => u.IsActive && u.MaxCapacity >= request.GuestsCount)
                .ToList();

            if (!eligibleUnits.Any())
            {
                _logger.LogInformation("لا توجد وحدات تتسع لـ {GuestsCount} ضيف في العقار: {PropertyId}", 
                    request.GuestsCount, request.PropertyId);
                
                return ResultDto<AvailableUnitsResponse>.Ok(
                    new AvailableUnitsResponse
                    {
                        Units = new List<AvailableUnitDto>(),
                        TotalAvailable = 0
                    }, 
                    $"لا توجد وحدات تتسع لـ {request.GuestsCount} ضيف"
                );
            }

            // Normalize incoming dates from user local to UTC for availability/price checks
            DateTime? checkInUtc = null;
            DateTime? checkOutUtc = null;
            if (request.CheckIn.HasValue)
                checkInUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckIn.Value);
            if (request.CheckOut.HasValue)
                checkOutUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.CheckOut.Value);

            // التحقق من توفر الوحدات في الفترة المطلوبة
            var availableUnits = new List<AvailableUnitDto>();


                foreach (var unit in eligibleUnits)
                {
                    // التحقق من عدم وجود حجوزات متضاربة
                    var isAvailable = !checkInUtc.HasValue || !checkOutUtc.HasValue ? true : await IsUnitAvailable(unit.Id, checkInUtc.Value, checkOutUtc.Value, cancellationToken);

                    if (!isAvailable)
                    {
                        continue;
                    }

                    // الحصول على تفاصيل نوع الوحدة
                    var unitType = await _unitTypeRepository.GetByIdAsync(unit.UnitTypeId, cancellationToken);
                    var unitTypeDto = unitType != null ? new UnitTypeDto
                    {
                        Id = unitType.Id,
                        Name = unitType.Name ?? string.Empty,
                        Description = unitType.Description ?? string.Empty
                    } : new UnitTypeDto();

                    // الحصول على صور الوحدة
                    var allImages = await _propertyImageRepository.GetAllAsync(cancellationToken);
                    var unitImages = allImages?.Where(img => img.PropertyId == unit.PropertyId);
                    var imageDtos = unitImages?.Select(img => new UnitImageDto
                    {
                        Id = img.Id,
                        Url = img.Url ?? string.Empty,
                        Caption = img.Caption ?? string.Empty,
                        IsMain = img.IsMain
                    }).OrderByDescending(img => img.IsMain).ThenBy(img => img.Caption).ToList() ?? new List<UnitImageDto>();

                    // الحصول على قيم الحقول الديناميكية
                    var fieldValues = await _unitFieldValueRepository.GetByUnitIdAsync(unit.Id, cancellationToken);
                    var fieldValueDtos = fieldValues?.Select(fv => new UnitFieldSimpleDto
                    {
                        FieldName = fv.UnitTypeField?.FieldName ?? string.Empty,
                        DisplayName = fv.UnitTypeField?.DisplayName ?? string.Empty,
                        Value = fv.FieldValue ?? string.Empty,
                        FieldType = fv.UnitTypeField?.FieldTypeId ?? string.Empty
                    }).ToList() ?? new List<UnitFieldSimpleDto>();

                    // حساب السعر للفترة المحددة
                    var (totalPrice, pricePerNight) =  !checkInUtc.HasValue || !checkOutUtc.HasValue ? (0, 0) : await CalculateUnitPrice(unit, checkInUtc.Value, checkOutUtc.Value, cancellationToken);

                    var availableUnitDto = new AvailableUnitDto
                    {
                        Id = unit.Id,
                        Name = unit.Name ?? string.Empty,
                        UnitType = unitTypeDto,
                        MaxCapacity = unit.MaxCapacity,
                        TotalPrice = totalPrice,
                        PricePerNight = pricePerNight,
                        Currency = "YER", // العملة الافتراضية
                        PricingMethod = unit.PricingMethod.ToString(),
                        Images = imageDtos,
                        CustomFeatures = ParseCustomFeatures(unit.CustomFeatures),
                        FieldValues = fieldValueDtos
                    };

                    availableUnits.Add(availableUnitDto);
                }

            // ترتيب الوحدات حسب السعر (الأقل أولاً)
            availableUnits = availableUnits.OrderBy(u => u.TotalPrice).ToList();

            var response = new AvailableUnitsResponse
            {
                Units = availableUnits,
                TotalAvailable = availableUnits.Count
            };

            _logger.LogInformation("تم العثور على {Count} وحدة متاحة في العقار {PropertyId}", 
                availableUnits.Count, request.PropertyId);

            return ResultDto<AvailableUnitsResponse>.Ok(
                response, 
                $"تم العثور على {availableUnits.Count} وحدة متاحة"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء البحث عن الوحدات المتاحة. معرف العقار: {PropertyId}", request.PropertyId);
            return ResultDto<AvailableUnitsResponse>.Failed(
                $"حدث خطأ أثناء البحث عن الوحدات المتاحة: {ex.Message}", 
                "GET_AVAILABLE_UNITS_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<AvailableUnitsResponse> ValidateRequest(GetAvailableUnitsQuery request)
    {
        if (request.PropertyId == Guid.Empty)
        {
            _logger.LogWarning("معرف العقار مطلوب");
            return ResultDto<AvailableUnitsResponse>.Failed("معرف العقار مطلوب", "PROPERTY_ID_REQUIRED");
        }

        if (request.CheckIn >= request.CheckOut)
        {
            _logger.LogWarning("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة");
            return ResultDto<AvailableUnitsResponse>.Failed("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة", "INVALID_DATE_RANGE");
        }

        // Use user-local 'today' for validation
        if (request.CheckIn.HasValue)
        {
            var userTodayLocal = _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow).GetAwaiter().GetResult().Date;
            if (request.CheckIn.Value.Date < userTodayLocal)
            {
                _logger.LogWarning("تاريخ الوصول لا يمكن أن يكون في الماضي");
                return ResultDto<AvailableUnitsResponse>.Failed("تاريخ الوصول لا يمكن أن يكون في الماضي", "INVALID_CHECKIN_DATE");
            }
        }

        if (request.GuestsCount < 1 || request.GuestsCount > 50)
        {
            _logger.LogWarning("عدد الضيوف يجب أن يكون بين 1 و 50");
            return ResultDto<AvailableUnitsResponse>.Failed("عدد الضيوف يجب أن يكون بين 1 و 50", "INVALID_GUESTS_COUNT");
        }
        if (request.CheckIn.HasValue && request.CheckOut.HasValue)
        {
            // التحقق من أن الفترة لا تتجاوز سنة واحدة
            var daysDifference = (request.CheckOut.Value - request.CheckIn.Value).Days;
            if (daysDifference > 365)
            {
                _logger.LogWarning("فترة الإقامة لا يمكن أن تتجاوز سنة واحدة");
                return ResultDto<AvailableUnitsResponse>.Failed("فترة الإقامة لا يمكن أن تتجاوز سنة واحدة", "INVALID_STAY_DURATION");
            }

        }

        return ResultDto<AvailableUnitsResponse>.Ok(null, "البيانات صحيحة");
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
        // البحث عن حجوزات متضاربة
        var conflictingBookings = await _bookingRepository.GetConflictingBookingsAsync(
            unitId, checkIn, checkOut, cancellationToken);

        return conflictingBookings == null || !conflictingBookings.Any();
    }

    /// <summary>
    /// حساب سعر الوحدة للفترة المحددة
    /// Calculate unit price for the specified period
    /// </summary>
    /// <param name="unit">الوحدة</param>
    /// <param name="checkIn">تاريخ الوصول</param>
    /// <param name="checkOut">تاريخ المغادرة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>السعر الإجمالي والسعر لليلة الواحدة</returns>
    private async Task<(decimal totalPrice, decimal pricePerNight)> CalculateUnitPrice(
        Core.Entities.Unit unit, DateTime checkIn, DateTime checkOut, CancellationToken cancellationToken)
    {
        var nights = (checkOut - checkIn).Days;
        var basePrice = unit.BasePrice;

        // يمكن إضافة منطق أكثر تعقيداً هنا لحساب الأسعار الموسمية أو العروض الخاصة
        // مثل الحصول على أسعار خاصة من جدول منفصل

        var pricePerNight = basePrice;
        var totalPrice = pricePerNight * nights;

        // تطبيق أي خصومات أو رسوم إضافية
        if (unit.DiscountPercentage > 0)
        {
            var discountAmount = totalPrice * (unit.DiscountPercentage / 100);
            totalPrice -= discountAmount;
        }

        return (totalPrice, pricePerNight);
    }

    // Parser to safely handle invalid/empty/non-object JSON in CustomFeatures
    private static Dictionary<string, object> ParseCustomFeatures(string? json)
    {
        try
        {
            if (string.IsNullOrWhiteSpace(json))
            {
                return new Dictionary<string, object>();
            }

            json = json.Trim();
            if (string.Equals(json, "null", StringComparison.OrdinalIgnoreCase))
            {
                return new Dictionary<string, object>();
            }

            using var doc = JsonDocument.Parse(json);
            if (doc.RootElement.ValueKind == JsonValueKind.Object)
            {
                return JsonSerializer.Deserialize<Dictionary<string, object>>(json) ?? new Dictionary<string, object>();
            }

            // If not an object (array/primitive), ignore and return empty for safety
            return new Dictionary<string, object>();
        }
        catch
        {
            // Any parse error -> return empty dictionary to avoid crashing
            return new Dictionary<string, object>();
        }
    }
}
