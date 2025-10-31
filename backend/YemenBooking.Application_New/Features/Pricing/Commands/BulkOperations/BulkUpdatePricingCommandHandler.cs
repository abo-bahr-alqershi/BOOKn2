using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Pricing;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Pricing.Commands.BulkOperations;

public class BulkUpdatePricingCommandHandler : IRequestHandler<BulkUpdatePricingCommand, ResultDto>
{
    private readonly IPricingRuleRepository _pricingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ILogger<BulkUpdatePricingCommandHandler> _logger;
    private readonly ICurrentUserService _currentUserService;

    public BulkUpdatePricingCommandHandler(
        IPricingRuleRepository pricingRepository,
        IUnitRepository unitRepository,
        ILogger<BulkUpdatePricingCommandHandler> logger,
        ICurrentUserService currentUserService)
    {
        _pricingRepository = pricingRepository;
        _unitRepository = unitRepository;
        _logger = logger;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto> Handle(BulkUpdatePricingCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // التحقق من وجود الوحدة
            var unit = await _unitRepository.GetByIdAsync(request.UnitId);
            if (unit == null)
                return ResultDto.Failure("الوحدة غير موجودة");

            // التحقق من صحة الفترات
            var hasInvalidPeriods = request.Periods.Any(p => 
                p.StartDate > p.EndDate || 
                p.Price < 0 ||
                (p.MinPrice.HasValue && p.MaxPrice.HasValue && p.MinPrice > p.MaxPrice));

            if (hasInvalidPeriods)
                return ResultDto.Failure("توجد فترات غير صالحة في البيانات المدخلة");

            var pricingRules = new List<PricingRule>();

            foreach (var period in request.Periods)
            {
                // Normalize to local-day safe bounds
                var localStart = new DateTime(period.StartDate.Year, period.StartDate.Month, period.StartDate.Day, 12, 0, 0);
                var localEnd = new DateTime(period.EndDate.Year, period.EndDate.Month, period.EndDate.Day, 23, 59, 59, 999);
                var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localStart);
                var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localEnd);

                // Normalize and validate inputs
                var priceType = string.IsNullOrWhiteSpace(period.PriceType) ? "Custom" : period.PriceType.Trim();
                var tier = string.IsNullOrWhiteSpace(period.Tier) ? "1" : period.Tier.Trim();
                var currencyCode = string.IsNullOrWhiteSpace(period.Currency)
                    ? (unit.BasePrice?.Currency ?? "YER")
                    : period.Currency.Trim();
                currencyCode = currencyCode.ToUpperInvariant();

                // حذف القواعد الموجودة إذا طُلب ذلك
                if (period.OverwriteExisting || request.OverwriteExisting)
                {
                    await _pricingRepository.DeleteRangeAsync(
                        request.UnitId, 
                        startUtc, 
                        endUtc);
                }

                // حساب السعر النهائي
                decimal finalPrice = period.Price;
                
                // إذا كان هناك نسبة تغيير، احسب السعر بناءً على السعر الأساسي
                if (period.PercentageChange.HasValue && period.PercentageChange.Value != 0)
                {
                    finalPrice = unit.BasePrice.Amount * (1 + period.PercentageChange.Value / 100);
                }

                // تطبيق الحد الأدنى والأقصى
                if (period.MinPrice.HasValue && finalPrice < period.MinPrice.Value)
                    finalPrice = period.MinPrice.Value;
                    
                if (period.MaxPrice.HasValue && finalPrice > period.MaxPrice.Value)
                    finalPrice = period.MaxPrice.Value;

                var rule = new PricingRule
                {
                    Id = Guid.NewGuid(),
                    UnitId = request.UnitId,
                    PriceType = priceType,
                    StartDate = startUtc,
                    EndDate = endUtc,
                    StartTime = period.StartTime,
                    EndTime = period.EndTime,
                    PriceAmount = finalPrice,
                    Currency = currencyCode,
                    PricingTier = tier, // تعيين قيمة افتراضية إذا كانت فارغة
                    PercentageChange = period.PercentageChange,
                    MinPrice = period.MinPrice,
                    MaxPrice = period.MaxPrice,
                    Description = period.Description,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = null, // تركها null بدلاً من Guid.Empty
                    UpdatedAt = DateTime.UtcNow,
                    UpdatedBy = null
                };

                pricingRules.Add(rule);
            }

            // حفظ جميع القواعد دفعة واحدة
            await _pricingRepository.BulkCreateAsync(pricingRules);

            _logger.LogInformation($"تم تحديث {pricingRules.Count} قاعدة تسعير للوحدة {request.UnitId}");

            return ResultDto.Ok();
        }
        catch (Exception ex)
        {
            var inner = ex.InnerException?.Message;
            var message = ex.Message + (inner != null ? $" | Inner: {inner}" : string.Empty);
            _logger.LogError(ex, $"خطأ في تحديث التسعير المجمع للوحدة {request.UnitId} :: {message}");
            return ResultDto.Failure($"حدث خطأ: {message}");
        }
    }
}