using MediatR;
using YemenBooking.Core.Entities;
using Microsoft.Extensions.Logging;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Features.Pricing.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Pricing;

namespace YemenBooking.Application.Features.Pricing.Commands.SeasonalPricing;

public class ApplySeasonalPricingCommandHandler : IRequestHandler<ApplySeasonalPricingCommand, ResultDto>
{
    private readonly IPricingRuleRepository _pricingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly IPricingService _pricingService;
    private readonly ILogger<ApplySeasonalPricingCommandHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    public ApplySeasonalPricingCommandHandler(
        IPricingRuleRepository pricingRepository,
        IUnitRepository unitRepository,
        IPricingService pricingService,
        ILogger<ApplySeasonalPricingCommandHandler> logger,
        ICurrentUserService currentUserService)
    {
        _pricingRepository = pricingRepository;
        _unitRepository = unitRepository;
        _pricingService = pricingService;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto> Handle(ApplySeasonalPricingCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // تحميل نوع الوحدة للتحقق من الخصائص
            var unit = await _unitRepository.GetByIdWithIncludesAsync(request.UnitId, u => u.UnitType);            
            if (unit == null)
                return ResultDto.Failure("الوحدة غير موجودة");

            
            // التحقق من صحة المواسم
            var validationResult = ValidateSeasons(request.Seasons, unit);
            if (!validationResult.IsSuccess)
                return validationResult;

            var pricingRules = new List<PricingRule>();
            // Align current date reference to user's local timezone
            var userNow = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow);
            var currentYear = userNow.Year;
            var yearsToApply = request.ApplyRecurringly ? new[] { currentYear, currentYear + 1, currentYear + 2 } : new[] { currentYear };

            foreach (var year in yearsToApply)
            {
                foreach (var season in request.Seasons.OrderBy(s => s.Priority))
                {
                    // تعديل التواريخ للسنة المطبقة إذا كان التكرار سنوي
                    var seasonStartDate = season.StartDate;
                    var seasonEndDate = season.EndDate;

                    if (season.IsRecurringYearly || request.ApplyRecurringly)
                    {
                        // تحويل التواريخ للسنة المستهدفة
                        seasonStartDate = new DateTime(year, season.StartDate.Month, season.StartDate.Day,
                            season.StartDate.Hour, season.StartDate.Minute, season.StartDate.Second);
                        seasonEndDate = new DateTime(
                            year + (season.EndDate.Year - season.StartDate.Year), // معالجة المواسم التي تمتد لسنتين
                            season.EndDate.Month, 
                            season.EndDate.Day,
                            season.EndDate.Hour, 
                            season.EndDate.Minute, 
                            season.EndDate.Second);
                    }

                    // تخطي المواسم التي انتهت بالفعل
                    if (seasonEndDate < userNow && !season.IsRecurringYearly)
                        continue;

                    // حذف القواعد الموجودة إذا طُلب ذلك
                    if (request.OverwriteExisting)
                    {
                        var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(seasonStartDate);
                        var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(seasonEndDate);
                        await _pricingRepository.DeleteRangeAsync(
                            request.UnitId,
                            startUtc,
                            endUtc);
                    }

                    // إنشاء قواعد التسعير للموسم
                    var seasonRules = await CreateSeasonalPricingRules(
                        request.UnitId,
                        season,
                        seasonStartDate,
                        seasonEndDate,
                        unit,
                        request.Currency);

                    pricingRules.AddRange(seasonRules);
                }
            }

            // التحقق من التداخلات في القواعد
            var overlappingRules = CheckForOverlappingRules(pricingRules);
            if (overlappingRules.Any() && !request.OverwriteExisting)
            {
                var overlappingDates = string.Join(", ", overlappingRules.Select(r => 
                    $"{r.StartDate:yyyy-MM-dd} - {r.EndDate:yyyy-MM-dd}"));
                return ResultDto.Failure($"توجد تداخلات في التواريخ: {overlappingDates}. استخدم خيار استبدال القواعد الموجودة");
            }

            // حفظ جميع القواعد
            await _pricingRepository.BulkCreateAsync(pricingRules);

            // تحديث إحصائيات الوحدة
            await UpdateUnitPricingStatistics(request.UnitId);

            var totalRules = pricingRules.Count;
            var totalDays = pricingRules.Sum(r => (r.EndDate - r.StartDate).Days + 1);
            
            _logger.LogInformation($"تم تطبيق التسعير الموسمي للوحدة {request.UnitId}: {totalRules} قاعدة، {totalDays} يوم");

            return ResultDto.Ok($"تم تطبيق التسعير الموسمي بنجاح ({request.Seasons.Count} موسم، {totalRules} قاعدة تسعير)");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"خطأ في تطبيق التسعير الموسمي للوحدة {request.UnitId}");
            return ResultDto.Failure($"حدث خطأ: {ex.Message}");
        }
    }

    private ResultDto ValidateSeasons(List<SeasonDto> seasons, Core.Entities.Unit unit)
    {
        if (seasons == null || !seasons.Any())
            return ResultDto.Failure("يجب تحديد موسم واحد على الأقل");

        foreach (var season in seasons)
        {
            // التحقق من الحقول المطلوبة
            if (string.IsNullOrWhiteSpace(season.Name))
                return ResultDto.Failure("اسم الموسم مطلوب");

            if (season.StartDate >= season.EndDate)
                return ResultDto.Failure($"تاريخ نهاية الموسم '{season.Name}' يجب أن يكون بعد تاريخ البداية");

            // التحقق من السعر
            if (season.Price < 0 && !season.PercentageChange.HasValue)
                return ResultDto.Failure($"يجب تحديد سعر صحيح أو نسبة تغيير للموسم '{season.Name}'");

            // التحقق من الحد الأدنى والأقصى
            if (season.MinPrice.HasValue && season.MaxPrice.HasValue && season.MinPrice > season.MaxPrice)
                return ResultDto.Failure($"الحد الأدنى للسعر يجب أن يكون أقل من الحد الأقصى في الموسم '{season.Name}'");

            // التحقق من التوقيت للوحدات التي تتطلب تحديد الساعة
            if (unit.UnitType?.IsRequiredToDetermineTheHour == true)
            {
                if (!season.StartTime.HasValue || !season.EndTime.HasValue)
                    return ResultDto.Failure($"يجب تحديد وقت البداية والنهاية للموسم '{season.Name}' لأن نوع الوحدة يتطلب ذلك");

                if (season.StartTime >= season.EndTime)
                    return ResultDto.Failure($"وقت النهاية يجب أن يكون بعد وقت البداية في الموسم '{season.Name}'");
            }

            // التحقق من أيام الأسبوع
            if (season.ApplicableDaysOfWeek?.Any() == true)
            {
                if (season.ApplicableDaysOfWeek.Any(d => d < 0 || d > 6))
                    return ResultDto.Failure($"أيام الأسبوع يجب أن تكون بين 0 (الأحد) و 6 (السبت) في الموسم '{season.Name}'");
            }
        }

        return ResultDto.Ok();
    }

    private async Task<List<PricingRule>> CreateSeasonalPricingRules(
        Guid unitId,
        SeasonDto season,
        DateTime seasonStartDate,
        DateTime seasonEndDate,
        Core.Entities.Unit unit,
        string currency)
    {
        var rules = new List<PricingRule>();
        var basePrice = unit.BasePrice.Amount;
        var currentDate = seasonStartDate.Date;

        while (currentDate <= seasonEndDate.Date)
        {
            // التحقق من أيام الأسبوع المطبقة
            if (season.ApplicableDaysOfWeek?.Any() == true)
            {
                var dayOfWeek = (int)currentDate.DayOfWeek;
                if (!season.ApplicableDaysOfWeek.Contains(dayOfWeek))
                {
                    currentDate = currentDate.AddDays(1);
                    continue;
                }
            }

            // حساب السعر النهائي
            decimal finalPrice = season.Price;

            // تطبيق النسبة المئوية إذا كانت محددة
            if (season.PercentageChange.HasValue)
            {
                finalPrice = basePrice + (basePrice * season.PercentageChange.Value / 100);
            }
            else if (season.Price == 0 && season.PercentageChange.HasValue)
            {
                // إذا كان السعر صفر ولكن هناك نسبة تغيير، احسب من السعر الأساسي
                finalPrice = basePrice * (1 + season.PercentageChange.Value / 100);
            }

            // تطبيق الحد الأدنى والأقصى
            if (season.MinPrice.HasValue && finalPrice < season.MinPrice.Value)
                finalPrice = season.MinPrice.Value;

            if (season.MaxPrice.HasValue && finalPrice > season.MaxPrice.Value)
                finalPrice = season.MaxPrice.Value;

            // إنشاء قاعدة التسعير لليوم
            var rule = new PricingRule
            {
                Id = Guid.NewGuid(),
                UnitId = unitId,
                PriceType = MapSeasonTypeToPriceType(season.Type),
                // Persist in UTC
                StartDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(currentDate),
                EndDate = await _currentUserService.ConvertFromUserLocalToUtcAsync(currentDate.AddDays(1).AddSeconds(-1)), // نهاية اليوم
                StartTime = season.StartTime,
                EndTime = season.EndTime,
                PriceAmount = finalPrice,
                Currency = currency ?? unit.BasePrice.Currency,
                PricingTier = season.Priority.ToString(),
                PercentageChange = season.PercentageChange,
                MinPrice = season.MinPrice,
                MaxPrice = season.MaxPrice,
                Description = $"{season.Name} - {season.Description ?? season.Type}",
                CreatedAt = DateTime.UtcNow,
                CreatedBy = Guid.Empty, // يجب تعيينه من السياق
                IsActive = true
            };

            rules.Add(rule);
            currentDate = currentDate.AddDays(1);
        }

        return rules;
    }

    private string MapSeasonTypeToPriceType(string seasonType)
    {
        return seasonType?.ToLower() switch
        {
            "peak" => "Peak",
            "off-peak" => "OffPeak",
            "offpeak" => "OffPeak",
            "holiday" => "Holiday",
            "special" => "Special",
            "weekend" => "Weekend",
            "event" => "Event",
            "lastminute" => "LastMinute",
            "earlybird" => "EarlyBird",
            _ => "Seasonal"
        };
    }

    private List<PricingRule> CheckForOverlappingRules(List<PricingRule> rules)
    {
        var overlapping = new List<PricingRule>();

        for (int i = 0; i < rules.Count - 1; i++)
        {
            for (int j = i + 1; j < rules.Count; j++)
            {
                if (rules[i].StartDate <= rules[j].EndDate && rules[i].EndDate >= rules[j].StartDate)
                {
                    // التحقق من نفس الأولوية
                    if (rules[i].PricingTier == rules[j].PricingTier)
                    {
                        overlapping.Add(rules[i]);
                        overlapping.Add(rules[j]);
                    }
                }
            }
        }

        return overlapping.Distinct().ToList();
    }

    private async Task UpdateUnitPricingStatistics(Guid unitId)
    {
        try
        {
            // يمكن إضافة منطق لتحديث إحصائيات التسعير للوحدة
            // مثل متوسط السعر، أعلى وأقل سعر، إلخ
            var nowLocal = await _currentUserService.ConvertFromUtcToUserLocalAsync(DateTime.UtcNow);
            var currentMonth = nowLocal.Month;
            var currentYear = nowLocal.Year;
            
            var monthlyPricing = await _pricingRepository.GetByDateRangeAsync(
                unitId,
                new DateTime(currentYear, currentMonth, 1),
                new DateTime(currentYear, currentMonth, DateTime.DaysInMonth(currentYear, currentMonth)));

            if (monthlyPricing.Any())
            {
                var avgPrice = monthlyPricing.Average(p => p.PriceAmount);
                var maxPrice = monthlyPricing.Max(p => p.PriceAmount);
                var minPrice = monthlyPricing.Min(p => p.PriceAmount);

                _logger.LogInformation($"إحصائيات التسعير للوحدة {unitId} - المتوسط: {avgPrice}, الأعلى: {maxPrice}, الأدنى: {minPrice}");
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, $"فشل تحديث إحصائيات التسعير للوحدة {unitId}");
            // لا نريد فشل العملية الأساسية بسبب فشل تحديث الإحصائيات
        }
    }
}

// DTOs للاستجابة
public class SeasonalPricingDto
{
    public string Currency { get; set; }
    public List<SeasonDto> Seasons { get; set; }
}

public class ApplySeasonalPricingResult
{
    public bool Success { get; set; }
    public int TotalRulesCreated { get; set; }
    public int TotalDaysAffected { get; set; }
    public List<string> AppliedSeasons { get; set; }
    public List<string> SkippedSeasons { get; set; }
    public Dictionary<string, decimal> PriceRangeBySeason { get; set; }
}