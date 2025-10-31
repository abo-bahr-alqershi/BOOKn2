using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;

namespace YemenBooking.Application.Features.Pricing.Commands.SeasonalPricing;

public class ApplySeasonalPricingCommand : IRequest<ResultDto>
{
    public Guid UnitId { get; set; }
    public List<SeasonDto> Seasons { get; set; }
    public string Currency { get; set; }
    public bool ApplyRecurringly { get; set; }
    public bool OverwriteExisting { get; set; }
}

public class SeasonDto
{
    public string Name { get; set; }
    public string Type { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public TimeSpan? StartTime { get; set; }
    public TimeSpan? EndTime { get; set; }
    public decimal Price { get; set; }
    public decimal? PercentageChange { get; set; }
    public int Priority { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public string? Description { get; set; }
    public bool IsRecurringYearly { get; set; }
    public List<int>? ApplicableDaysOfWeek { get; set; }
}
