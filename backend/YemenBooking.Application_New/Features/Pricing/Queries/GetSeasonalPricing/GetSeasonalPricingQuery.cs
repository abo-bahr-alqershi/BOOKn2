using MediatR;
using AutoMapper;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Pricing.Queries.GetSeasonalPricing;

public class GetSeasonalPricingQuery : IRequest<ResultDto<SeasonalPricingResponse>>
{
    public Guid UnitId { get; set; }
    public int? Year { get; set; }
    public bool IncludeExpired { get; set; } = false;
}

public class SeasonalPricingResponse
{
    public Guid UnitId { get; set; }
    public string UnitName { get; set; }
    public List<QuerySeasonalPricingDto> Seasons { get; set; }
    public SeasonalPricingStatsDto StatisticsDto { get; set; }
}

public class QuerySeasonalPricingDto
{
    public Guid Id { get; set; }
    public string Name { get; set; }
    public string Type { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal Price { get; set; }
    public decimal? PercentageChange { get; set; }
    public string Currency { get; set; }
    public string PricingTier { get; set; }
    public int Priority { get; set; }
    public string Description { get; set; }
    public bool IsActive { get; set; }
    public bool IsRecurring { get; set; }
    public int DaysCount { get; set; }
    public decimal TotalRevenuePotential { get; set; }
}

public class SeasonalPricingStatsDto
{
    public int TotalSeasons { get; set; }
    public int ActiveSeasons { get; set; }
    public int UpcomingSeasons { get; set; }
    public int ExpiredSeasons { get; set; }
    public decimal AverageSeasonalPrice { get; set; }
    public decimal MaxSeasonalPrice { get; set; }
    public decimal MinSeasonalPrice { get; set; }
    public int TotalDaysCovered { get; set; }
}
