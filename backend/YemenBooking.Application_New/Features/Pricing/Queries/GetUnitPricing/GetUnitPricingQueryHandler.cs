using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Pricing;
using YemenBooking.Application.Features.Pricing.DTOs;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Pricing.Queries.GetUnitPricing;


public class GetUnitPricingQueryHandler : IRequestHandler<GetUnitPricingQuery, ResultDto<UnitPricingDto>>
{
    private readonly IPricingRuleRepository _pricingRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetUnitPricingQueryHandler(
        IPricingRuleRepository pricingRepository,
        IUnitRepository unitRepository,
        ICurrentUserService currentUserService)
    {
        _pricingRepository = pricingRepository;
        _unitRepository = unitRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto<UnitPricingDto>> Handle(GetUnitPricingQuery request, CancellationToken cancellationToken)
    {
        var unit = await _unitRepository.GetByIdAsync(request.UnitId);
        if (unit == null)
            return ResultDto<UnitPricingDto>.Failure("الوحدة غير موجودة");

        // Compute month boundaries in user-local then convert to UTC for querying
        var localStartOfMonth = new DateTime(request.Year, request.Month, 1, 0, 0, 0);
        var localEndOfMonth = localStartOfMonth.AddMonths(1).AddMilliseconds(-1);
        var startOfMonth = await _currentUserService.ConvertFromUserLocalToUtcAsync(localStartOfMonth);
        var endOfMonth = await _currentUserService.ConvertFromUserLocalToUtcAsync(localEndOfMonth);

        var rules = await _pricingRepository.GetByDateRangeAsync(
            request.UnitId,
            startOfMonth,
            endOfMonth);

        var basePrice = unit.BasePrice.Amount;

        // Build calendar per user-local day to avoid timezone off-by-one issues
        var rulesList = rules.ToList();
        var calendar = new Dictionary<DateTime, decimal>();

        int GetTierPriority(string? tier)
        {
            if (string.IsNullOrWhiteSpace(tier)) return 5;
            if (int.TryParse(tier, out var n)) return n;
            switch (tier.Trim().ToLowerInvariant())
            {
                case "discount": return 0;
                case "normal": return 1;
                case "high": return 2;
                case "peak": return 3;
                case "seasonal": return 2;
                case "weekend": return 2;
                case "holiday": return 3;
                default: return 5;
            }
        }

        for (var localDay = new DateTime(request.Year, request.Month, 1); localDay.Month == request.Month; localDay = localDay.AddDays(1))
        {
            var localMidday = new DateTime(localDay.Year, localDay.Month, localDay.Day, 12, 0, 0);
            var utcPoint = await _currentUserService.ConvertFromUserLocalToUtcAsync(localMidday);

            var dayRule = rulesList
                .Where(r => r.StartDate <= utcPoint && r.EndDate >= utcPoint)
                .OrderBy(r => GetTierPriority(r.PricingTier))
                .ThenByDescending(r => r.UpdatedAt)
                .FirstOrDefault();

            var price = dayRule?.PriceAmount ?? basePrice;
            calendar[localDay.Date] = price;
        }

        var dto = new UnitPricingDto
        {
            UnitId = unit.Id,
            UnitName = unit.Name,
            BasePrice = basePrice,
            Currency = unit.BasePrice.Currency,
            Calendar = calendar.ToDictionary(
                kvp => kvp.Key,
                kvp => new PricingDayDto
                {
                    Price = kvp.Value,
                    PriceType = GetPriceType(kvp.Value, basePrice),
                    ColorCode = GetPriceColorCode(kvp.Value, basePrice),
                    PercentageChange = CalculatePercentageChange(kvp.Value, basePrice)
                }),
            Rules = rules.Select(r => new YemenBooking.Application.Features.Pricing.DTOs.PricingRuleDto
            {
                PricingId = r.Id,
                StartDate = r.StartDate,
                EndDate = r.EndDate,
                PriceAmount = r.PriceAmount,
                PriceType = r.PriceType,
                Description = r.Description
            }).ToList(),
            Stats = CalculatePricingStats(calendar.Values.ToList(), basePrice)
        };

        return ResultDto<UnitPricingDto>.Ok(dto);
    }

    private string GetPriceType(decimal price, decimal basePrice)
    {
        if (price == basePrice) return "Base";
        if (price > basePrice) return "Peak";
        return "Off-Peak";
    }

    private string GetPriceColorCode(decimal price, decimal basePrice)
    {
        var percentage = ((price - basePrice) / basePrice) * 100;
        
        // Avoid red to prevent confusion with availability "blocked" color
        if (percentage > 20) return "#7C3AED";      // Purple (high)
        if (percentage > 10) return "#F59E0B";      // Orange
        if (percentage > 0) return "#FBBF24";       // Yellow
        if (percentage == 0) return "#10B981";      // Green
        if (percentage > -10) return "#60A5FA";     // Light Blue
        return "#3B82F6";                           // Blue
    }

    private decimal? CalculatePercentageChange(decimal price, decimal basePrice)
    {
        if (basePrice == 0) return null;
        var pct = ((price - basePrice) / basePrice) * 100m;
        return Math.Round(pct, 2, MidpointRounding.AwayFromZero);
    }

    private PricingStatsDto CalculatePricingStats(List<decimal> prices, decimal basePrice)
    {
        if (!prices.Any())
            return new PricingStatsDto();

        return new PricingStatsDto
        {
            AveragePrice = prices.Average(),
            MinPrice = prices.Min(),
            MaxPrice = prices.Max(),
            DaysWithSpecialPricing = prices.Count(p => p != basePrice),
            PotentialRevenue = prices.Sum()
        };
    }
}