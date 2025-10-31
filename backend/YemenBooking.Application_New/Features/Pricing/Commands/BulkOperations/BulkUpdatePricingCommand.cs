using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Pricing.Commands.BulkOperations;

public class BulkUpdatePricingCommand : IRequest<ResultDto>
{
    public Guid UnitId { get; set; }
    public List<PricingPeriodDto> Periods { get; set; }
    public bool OverwriteExisting { get; set; }
}

public class PricingPeriodDto
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public TimeSpan? StartTime { get; set; }
    public TimeSpan? EndTime { get; set; }
    public string PriceType { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; }
    public string Tier { get; set; }
    public decimal? PercentageChange { get; set; }
    public decimal? MinPrice { get; set; }
    public decimal? MaxPrice { get; set; }
    public string? Description { get; set; }
    public bool OverwriteExisting { get; set; }
}