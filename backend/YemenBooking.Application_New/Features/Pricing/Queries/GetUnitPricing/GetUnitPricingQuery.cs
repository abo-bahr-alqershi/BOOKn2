using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features;
using YemenBooking.Application.Features.Pricing.DTOs;

namespace YemenBooking.Application.Features.Pricing.Queries.GetUnitPricing;

public class GetUnitPricingQuery : IRequest<ResultDto<UnitPricingDto>>
{
    public Guid UnitId { get; set; }
    public int Year { get; set; }
    public int Month { get; set; }
}

public class UnitPricingDto
{
    public Guid UnitId { get; set; }
    public string UnitName { get; set; }
    public decimal BasePrice { get; set; }
    public string Currency { get; set; }
    public Dictionary<DateTime, PricingDayDto> Calendar { get; set; }
    public List<YemenBooking.Application.Features.Pricing.DTOs.PricingRuleDto> Rules { get; set; }
    public PricingStatsDto Stats { get; set; }
}

public class PricingDayDto
{
    public decimal Price { get; set; }
    public string PriceType { get; set; }
    public string ColorCode { get; set; }
    public decimal? PercentageChange { get; set; }
    public string PricingTier { get; set; }
}


public class PricingStatsDto
{
    public decimal AveragePrice { get; set; }
    public decimal MinPrice { get; set; }
    public decimal MaxPrice { get; set; }
    public int DaysWithSpecialPricing { get; set; }
    public decimal PotentialRevenue { get; set; }
}