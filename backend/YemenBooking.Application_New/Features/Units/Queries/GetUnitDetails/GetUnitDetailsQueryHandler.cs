using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Core.Interfaces.Repositories;
using System.Text.Json;
using YemenBooking.Core.Enums;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.DynamicFields.DTOs;
using YemenBooking.Application.Features.Properties.DTOs;
using YemenBooking.Application.Features.Units.DTOs;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.GetUnitDetails;

/// <summary>
/// معالج استعلام الحصول على تفاصيل الوحدة
/// Handler for get unit details query
/// </summary>
public class GetUnitDetailsQueryHandler : IRequestHandler<GetUnitDetailsQuery, ResultDto<UnitDetailsDto>>
{
    private readonly IUnitRepository _unitRepository;
    private readonly IPropertyRepository _propertyRepository;
    private readonly IUnitTypeRepository _unitTypeRepository;
    private readonly IBookingRepository _bookingRepository;
    private readonly IPropertyImageRepository _propertyImageRepository;
    private readonly IUnitFieldValueRepository _unitFieldValueRepository;
    private readonly IPricingRuleRepository _pricingRuleRepository;
    private readonly ILogger<GetUnitDetailsQueryHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    /// <summary>
    /// منشئ معالج استعلام تفاصيل الوحدة
    /// Constructor for get unit details query handler
    /// </summary>
    /// <param name="unitRepository">مستودع الوحدات</param>
    /// <param name="propertyRepository">مستودع العقارات</param>
    /// <param name="unitTypeRepository">مستودع أنواع الوحدات</param>
    /// <param name="bookingRepository">مستودع الحجوزات</param>
    /// <param name="propertyImageRepository">مستودع صور العقارات والوحدات</param>
    /// <param name="unitFieldValueRepository">مستودع قيم حقول الوحدات</param>
    /// <param name="pricingRuleRepository">مستودع قواعد التسعير</param>
    /// <param name="logger">مسجل الأحداث</param>
    /// <param name="currentUserService">خدمة المستخدم الحالي</param>
    public GetUnitDetailsQueryHandler(
        IUnitRepository unitRepository,
        IPropertyRepository propertyRepository,
        IUnitTypeRepository unitTypeRepository,
        IBookingRepository bookingRepository,
        IPropertyImageRepository propertyImageRepository,
        IUnitFieldValueRepository unitFieldValueRepository,
        IPricingRuleRepository pricingRuleRepository,
        ILogger<GetUnitDetailsQueryHandler> logger,
        ICurrentUserService currentUserService)
    {
        _unitRepository = unitRepository;
        _propertyRepository = propertyRepository;
        _unitTypeRepository = unitTypeRepository;
        _bookingRepository = bookingRepository;
        _propertyImageRepository = propertyImageRepository;
        _unitFieldValueRepository = unitFieldValueRepository;
        _pricingRuleRepository = pricingRuleRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    /// <summary>
    /// معالجة استعلام الحصول على تفاصيل الوحدة
    /// Handle get unit details query
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>تفاصيل الوحدة</returns>
    public async Task<ResultDto<UnitDetailsDto>> Handle(GetUnitDetailsQuery request, CancellationToken cancellationToken)
    {
        try
        {
            _logger.LogInformation("بدء استعلام تفاصيل الوحدة. معرف الوحدة: {UnitId}, تاريخ الوصول: {CheckIn}, تاريخ المغادرة: {CheckOut}", 
                request.UnitId, request.CheckIn, request.CheckOut);

            // التحقق من صحة البيانات المدخلة
            var validationResult = ValidateRequest(request);
            if (!validationResult.IsSuccess)
            {
                return validationResult;
            }

            // الحصول على الوحدة
            var unit = await _unitRepository.GetByIdAsync(request.UnitId, cancellationToken);
            if (unit == null)
            {
                _logger.LogWarning("لم يتم العثور على الوحدة: {UnitId}", request.UnitId);
                return ResultDto<UnitDetailsDto>.Failed("الوحدة غير موجودة", "UNIT_NOT_FOUND");
            }

            // التحقق من أن الوحدة نشطة
            if (!unit.IsActive)
            {
                _logger.LogWarning("الوحدة غير نشطة: {UnitId}", request.UnitId);
                return ResultDto<UnitDetailsDto>.Failed("الوحدة غير متاحة حالياً", "UNIT_INACTIVE");
            }

            // الحصول على تفاصيل العقار
            var property = await _propertyRepository.GetByIdAsync(unit.PropertyId, cancellationToken);
            if (property == null)
            {
                _logger.LogWarning("لم يتم العثور على العقار للوحدة: {UnitId}", request.UnitId);
                return ResultDto<UnitDetailsDto>.Failed("بيانات العقار غير متاحة", "PROPERTY_NOT_FOUND");
            }

            // الحصول على نوع الوحدة
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
            var fieldValueDtos = fieldValues?.Select(fv => new UnitFieldValueDto
            {
                FieldName = fv.UnitTypeField?.FieldName ?? string.Empty,
                DisplayName = fv.UnitTypeField?.DisplayName ?? string.Empty,
                Value = fv.FieldValue ?? string.Empty,
                FieldType = fv.UnitTypeField?.FieldTypeId ?? string.Empty
            }).ToList() ?? new List<UnitFieldValueDto>();

            // الحصول على قواعد التسعير
            var allPricingRules = await _pricingRuleRepository.GetAllAsync(cancellationToken);
            var pricingRules = allPricingRules?.Where(pr => pr.UnitId == unit.Id);
            var pricingRuleDtos = pricingRules?.Select(pr => new YemenBooking.Application.Features.Units.DTOs.PricingRuleDto
            {
                PriceType = pr.PriceType ?? string.Empty,
                StartDate = pr.StartDate,
                EndDate = pr.EndDate,
                PriceAmount = pr.PriceAmount,
                Description = pr.Description
            }).ToList() ?? new List<YemenBooking.Application.Features.Units.DTOs.PricingRuleDto>();

            // التحقق من التوفر
            bool isAvailable = true;
            if (request.CheckIn.HasValue && request.CheckOut.HasValue)
            {
                isAvailable = await IsUnitAvailable(unit.Id, request.CheckIn.Value, request.CheckOut.Value, cancellationToken);
            }

            // حساب السعر إذا تم تحديد التواريخ
            CalculatedPriceDto? calculatedPrice = null;
            if (request.CheckIn.HasValue && request.CheckOut.HasValue && isAvailable)
            {
                calculatedPrice = await CalculatePrice(unit, pricingRules, request.CheckIn.Value, request.CheckOut.Value, cancellationToken);
            }

            // تحويل DateTime fields في PricingRules إلى التوقيت المحلي للمستخدم
            for (int i = 0; i < pricingRuleDtos.Count; i++)
            {
                pricingRuleDtos[i].StartDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(pricingRuleDtos[i].StartDate);
                pricingRuleDtos[i].EndDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(pricingRuleDtos[i].EndDate);
            }

            // تحويل DateTime fields في CalculatedPrice Breakdown إلى التوقيت المحلي للمستخدم
            if (calculatedPrice?.Breakdown != null)
            {
                for (int i = 0; i < calculatedPrice.Breakdown.Count; i++)
                {
                    calculatedPrice.Breakdown[i].Date = await _currentUserService.ConvertFromUtcToUserLocalAsync(calculatedPrice.Breakdown[i].Date);
                }
            }

            // إنشاء DTO للاستجابة
            var unitDetailsDto = new UnitDetailsDto
            {
                Id = unit.Id,
                PropertyId = unit.PropertyId,
                PropertyName = property.Name ?? string.Empty,
                Name = unit.Name ?? string.Empty,
                UnitType = unitTypeDto,
                BasePrice = new MoneyDto { Amount = unit.BasePrice, Currency = "YER" },
                MaxCapacity = unit.MaxCapacity,
                PricingMethod = unit.PricingMethod.ToString(),
                IsAvailable = isAvailable,
                Images = imageDtos,
                CustomFeatures = unit.CustomFeatures ?? string.Empty,
                FieldValues = fieldValueDtos,
                PricingRules = pricingRuleDtos,
                CalculatedPrice = calculatedPrice
            };

            _logger.LogInformation("تم الحصول على تفاصيل الوحدة بنجاح. معرف الوحدة: {UnitId}, متاحة: {IsAvailable}", 
                request.UnitId, isAvailable);

            return ResultDto<UnitDetailsDto>.Ok(
                unitDetailsDto, 
                "تم الحصول على تفاصيل الوحدة بنجاح"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "خطأ أثناء الحصول على تفاصيل الوحدة. معرف الوحدة: {UnitId}", request.UnitId);
            return ResultDto<UnitDetailsDto>.Failed(
                $"حدث خطأ أثناء الحصول على تفاصيل الوحدة: {ex.Message}", 
                "GET_UNIT_DETAILS_ERROR"
            );
        }
    }

    /// <summary>
    /// التحقق من صحة البيانات المدخلة
    /// Validate request data
    /// </summary>
    /// <param name="request">طلب الاستعلام</param>
    /// <returns>نتيجة التحقق</returns>
    private ResultDto<UnitDetailsDto> ValidateRequest(GetUnitDetailsQuery request)
    {
        if (request.UnitId == Guid.Empty)
        {
            _logger.LogWarning("معرف الوحدة مطلوب");
            return ResultDto<UnitDetailsDto>.Failed("معرف الوحدة مطلوب", "UNIT_ID_REQUIRED");
        }

        // التحقق من التواريخ إذا تم تحديدها
        if (request.CheckIn.HasValue && request.CheckOut.HasValue)
        {
            if (request.CheckIn >= request.CheckOut)
            {
                _logger.LogWarning("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة");
                return ResultDto<UnitDetailsDto>.Failed("تاريخ الوصول يجب أن يكون قبل تاريخ المغادرة", "INVALID_DATE_RANGE");
            }

            if (request.CheckIn.Value.Date < DateTime.Today)
            {
                _logger.LogWarning("تاريخ الوصول لا يمكن أن يكون في الماضي");
                return ResultDto<UnitDetailsDto>.Failed("تاريخ الوصول لا يمكن أن يكون في الماضي", "INVALID_CHECKIN_DATE");
            }
        }

        return ResultDto<UnitDetailsDto>.Ok(null, "البيانات صحيحة");
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
        var conflictingBookings = await _bookingRepository.GetConflictingBookingsAsync(
            unitId, checkIn, checkOut, cancellationToken);

        return conflictingBookings == null || !conflictingBookings.Any();
    }

    /// <summary>
    /// حساب السعر للفترة المحددة
    /// Calculate price for the specified period
    /// </summary>
    /// <param name="unit">الوحدة</param>
    /// <param name="pricingRules">قواعد التسعير</param>
    /// <param name="checkIn">تاريخ الوصول</param>
    /// <param name="checkOut">تاريخ المغادرة</param>
    /// <param name="cancellationToken">رمز الإلغاء</param>
    /// <returns>السعر المحسوب</returns>
    private async Task<CalculatedPriceDto> CalculatePrice(
        Core.Entities.Unit unit, 
        IEnumerable<Core.Entities.PricingRule>? pricingRules, 
        DateTime checkIn, 
        DateTime checkOut, 
        CancellationToken cancellationToken)
    {
        var nights = (checkOut - checkIn).Days;
        var breakdown = new List<PriceBreakdownDto>();
        decimal baseAmount = 0;

        // حساب السعر لكل يوم
        for (var date = checkIn.Date; date < checkOut.Date; date = date.AddDays(1))
        {
            var dailyPrice = GetDailyPrice(unit, pricingRules, date);
            baseAmount += dailyPrice;

            breakdown.Add(new PriceBreakdownDto
            {
                Date = date,
                Amount = dailyPrice,
                Reason = GetPriceReason(date, pricingRules)
            });
        }

        // حساب الخصومات
        var discounts = CalculateDiscounts(unit, baseAmount, nights);

        // حساب الرسوم الإضافية
        var fees = CalculateFees(unit, baseAmount);

        // حساب الضرائب
        var taxes = CalculateTaxes(unit, baseAmount + fees - discounts);

        var totalAmount = baseAmount + fees + taxes - discounts;

        return new CalculatedPriceDto
        {
            BaseAmount = baseAmount,
            Discounts = discounts,
            Fees = fees,
            Taxes = taxes,
            TotalAmount = totalAmount,
            NumberOfNights = nights,
            Breakdown = breakdown
        };
    }

    /// <summary>
    /// الحصول على السعر اليومي
    /// Get daily price
    /// </summary>
    /// <param name="unit">الوحدة</param>
    /// <param name="pricingRules">قواعد التسعير</param>
    /// <param name="date">التاريخ</param>
    /// <returns>السعر اليومي</returns>
    private decimal GetDailyPrice(Core.Entities.Unit unit, IEnumerable<Core.Entities.PricingRule>? pricingRules, DateTime date)
    {
        // البحث عن قاعدة تسعير مطبقة لهذا التاريخ
        var applicableRule = pricingRules?
            .Where(pr => date >= pr.StartDate.Date && date <= pr.EndDate.Date)
            .OrderByDescending(pr => pr.PriceAmount) // أعطي الأولوية للسعر الأعلى
            .FirstOrDefault();

        return applicableRule?.PriceAmount ?? unit.BasePrice;
    }

    /// <summary>
    /// الحصول على سبب السعر
    /// Get price reason
    /// </summary>
    /// <param name="date">التاريخ</param>
    /// <param name="pricingRules">قواعد التسعير</param>
    /// <returns>سبب السعر</returns>
    private string GetPriceReason(DateTime date, IEnumerable<Core.Entities.PricingRule>? pricingRules)
    {
        var applicableRule = pricingRules?
            .Where(pr => date >= pr.StartDate.Date && date <= pr.EndDate.Date)
            .FirstOrDefault();

        if (applicableRule != null)
        {
            return applicableRule.Description ?? applicableRule.PriceType ?? "سعر خاص";
        }

        // تحديد نوع اليوم
        return date.DayOfWeek switch
        {
            DayOfWeek.Friday or DayOfWeek.Saturday => "نهاية أسبوع",
            _ => "سعر عادي"
        };
    }

    /// <summary>
    /// حساب الخصومات
    /// Calculate discounts
    /// </summary>
    /// <param name="unit">الوحدة</param>
    /// <param name="baseAmount">المبلغ الأساسي</param>
    /// <param name="nights">عدد الليالي</param>
    /// <returns>مبلغ الخصم</returns>
    private decimal CalculateDiscounts(Core.Entities.Unit unit, decimal baseAmount, int nights)
    {
        decimal discount = 0;

        // خصم الإقامة الطويلة
        if (nights >= 7)
        {
            discount += baseAmount * 0.1m; // خصم 10% للإقامة أسبوع أو أكثر
        }
        else if (nights >= 3)
        {
            discount += baseAmount * 0.05m; // خصم 5% للإقامة 3 أيام أو أكثر
        }

        // خصم الوحدة إذا كان محدد
        if (unit.DiscountPercentage > 0)
        {
            discount += baseAmount * (unit.DiscountPercentage / 100);
        }

        return discount;
    }

    /// <summary>
    /// حساب الرسوم الإضافية
    /// Calculate additional fees
    /// </summary>
    /// <param name="unit">الوحدة</param>
    /// <param name="baseAmount">المبلغ الأساسي</param>
    /// <returns>مبلغ الرسوم</returns>
    private decimal CalculateFees(Core.Entities.Unit unit, decimal baseAmount)
    {
        decimal fees = 0;

        // رسوم الخدمة (2% من المبلغ الأساسي)
        fees += baseAmount * 0.02m;

        // رسوم التنظيف (إذا كانت محددة في ميزات الوحدة المخصصة بصيغة JSON)
        if (!string.IsNullOrWhiteSpace(unit.CustomFeatures))
        {
            try
            {
                var features = JsonSerializer.Deserialize<Dictionary<string, object>>(unit.CustomFeatures);
                if (features != null && features.TryGetValue("cleaning_fee", out var feeObj))
                {
                    if (decimal.TryParse(feeObj?.ToString(), out var cleaningFee))
                    {
                        fees += cleaningFee;
                    }
                }
            }
            catch (JsonException)
            {
                // تجاهل إذا كانت JSON غير صالح
            }
        }

        return fees;
    }

    /// <summary>
    /// حساب الضرائب
    /// Calculate taxes
    /// </summary>
    /// <param name="unit">الوحدة</param>
    /// <param name="taxableAmount">المبلغ الخاضع للضريبة</param>
    /// <returns>مبلغ الضريبة</returns>
    private decimal CalculateTaxes(Core.Entities.Unit unit, decimal taxableAmount)
    {
        // ضريبة القيمة المضافة (5% في اليمن)
        return taxableAmount * 0.05m;
    }
}
