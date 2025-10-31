using AutoMapper;
using MediatR;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;

namespace YemenBooking.Application.Features.Units.Commands.UpdateUnit;

public class UpdateUnitAvailabilityCommand : IRequest<ResultDto>
{
    public Guid UnitId { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public string Status { get; set; } // Available, Blocked, Maintenance
    public string? Reason { get; set; }
    public string? Notes { get; set; }
    public bool OverwriteExisting { get; set; }
}
