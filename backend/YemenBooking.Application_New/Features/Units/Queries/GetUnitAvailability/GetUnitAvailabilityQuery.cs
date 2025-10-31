using MediatR;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Features;
using YemenBooking.Application.Features.Units.Commands.BulkOperations;

namespace YemenBooking.Application.Features.Units.Queries.GetUnitAvailability;

public class GetUnitAvailabilityQuery : IRequest<ResultDto<UnitAvailabilityDto>>
{
    public Guid UnitId { get; set; }
    public int Year { get; set; }
    public int Month { get; set; }
}

public class UnitAvailabilityDto
{
    public Guid UnitId { get; set; }
    public string UnitName { get; set; }
    public Dictionary<DateTime, AvailabilityStatusDto> Calendar { get; set; }
    public List<AvailabilityPeriodDto> Periods { get; set; }
    public AvailabilityStatsDto Stats { get; set; }
}

public class AvailabilityStatusDto
{
    public string Status { get; set; }
    public string? Reason { get; set; }
    public string? BookingId { get; set; }
    public string ColorCode { get; set; }
}

public class AvailabilityStatsDto
{
    public int TotalDays { get; set; }
    public int AvailableDays { get; set; }
    public int BookedDays { get; set; }
    public int BlockedDays { get; set; }
    public int MaintenanceDays { get; set; }
    public decimal OccupancyRate { get; set; }
}