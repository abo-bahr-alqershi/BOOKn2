using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Enums;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features;

namespace YemenBooking.Application.Features.Units.Queries.CheckAvailability;

public class CheckAvailabilityQuery : IRequest<ResultDto<CheckAvailabilityResponse>>
{
    public Guid UnitId { get; set; }
    public DateTime CheckIn { get; set; }
    public DateTime CheckOut { get; set; }
    public int? Adults { get; set; }
    public int? Children { get; set; }
    public bool IncludePricing { get; set; } = false;
}

public class CheckAvailabilityResponse
{
    public bool IsAvailable { get; set; }
    public string Status { get; set; }
    public List<BlockedPeriodDto> BlockedPeriods { get; set; }
    public List<AvailablePeriodDto> AvailablePeriods { get; set; }
    public AvailabilityDetailsDto Details { get; set; }
    public PricingSummaryDto PricingSummary { get; set; }
    public List<string> Messages { get; set; }
}

public class BlockedPeriodDto
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Status { get; set; }
    public string Reason { get; set; }
    public string Notes { get; set; }
}

public class AvailablePeriodDto
{
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public decimal? Price { get; set; }
    public string Currency { get; set; }
}

public class AvailabilityDetailsDto
{
    public Guid UnitId { get; set; }
    public string UnitName { get; set; }
    public string UnitType { get; set; }
    public int MaxAdults { get; set; }
    public int MaxChildren { get; set; }
    public int TotalNights { get; set; }
    public bool IsMultiDays { get; set; }
    public bool IsRequiredToDetermineTheHour { get; set; }
}

public class PricingSummaryDto
{
    public decimal TotalPrice { get; set; }
    public decimal AverageNightlyPrice { get; set; }
    public string Currency { get; set; }
    public List<DailyPriceDto> DailyPrices { get; set; }
}

public class DailyPriceDto
{
    public DateTime Date { get; set; }
    public decimal Price { get; set; }
    public string PriceType { get; set; }
}
