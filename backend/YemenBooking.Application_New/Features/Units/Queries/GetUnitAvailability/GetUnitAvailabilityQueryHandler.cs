using MediatR;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Features.Units;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features;
using YemenBooking.Application.Features.Units.Commands.BulkOperations;

namespace YemenBooking.Application.Features.Units.Queries.GetUnitAvailability;


public class GetUnitAvailabilityQueryHandler : IRequestHandler<GetUnitAvailabilityQuery, ResultDto<UnitAvailabilityDto>>
{
    private readonly IUnitAvailabilityRepository _availabilityRepository;
    private readonly IUnitRepository _unitRepository;
    private readonly ICurrentUserService _currentUserService;

    public GetUnitAvailabilityQueryHandler(
        IUnitAvailabilityRepository availabilityRepository,
        IUnitRepository unitRepository,
        ICurrentUserService currentUserService)
    {
        _availabilityRepository = availabilityRepository;
        _unitRepository = unitRepository;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto<UnitAvailabilityDto>> Handle(GetUnitAvailabilityQuery request, CancellationToken cancellationToken)
    {
        var unit = await _unitRepository.GetByIdAsync(request.UnitId);
        if (unit == null)
            return ResultDto<UnitAvailabilityDto>.Failure("الوحدة غير موجودة");

        var calendar = await _availabilityRepository.GetAvailabilityCalendarAsync(
            request.UnitId, 
            request.Year, 
            request.Month);

        var startOfMonthLocal = new DateTime(request.Year, request.Month, 1);
        var endOfMonthLocal = startOfMonthLocal.AddMonths(1).AddDays(-1);
        var startOfMonth = await _currentUserService.ConvertFromUserLocalToUtcAsync(startOfMonthLocal);
        var endOfMonth = await _currentUserService.ConvertFromUserLocalToUtcAsync(endOfMonthLocal);
        
        var periods = await _availabilityRepository.GetByDateRangeAsync(
            request.UnitId,
            startOfMonth,
            endOfMonth);

        var dto = new UnitAvailabilityDto
        {
            UnitId = unit.Id,
            UnitName = unit.Name,
            Calendar = calendar.ToDictionary(
                kvp => kvp.Key,
                kvp => new AvailabilityStatusDto
                {
                    Status = kvp.Value,
                    ColorCode = GetColorCode(kvp.Value)
                }),
            Periods = periods.Select(p => new AvailabilityPeriodDto
            {
                StartDate = p.StartDate,
                EndDate = p.EndDate,
                Status = p.Status,
                Reason = p.Reason,
                Notes = p.Notes
            }).ToList(),
            Stats = CalculateStats(calendar)
        };

        // Convert outgoing dates to user's local time
        var convertedCalendar = new Dictionary<DateTime, AvailabilityStatusDto>();
        foreach (var kvp in dto.Calendar)
        {
            var localDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(kvp.Key);
            convertedCalendar[localDate.Date] = kvp.Value;
        }
        dto.Calendar = convertedCalendar;

        foreach (var p in dto.Periods)
        {
            p.StartDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(p.StartDate);
            p.EndDate = await _currentUserService.ConvertFromUtcToUserLocalAsync(p.EndDate);
        }

        return ResultDto<UnitAvailabilityDto>.Ok(dto);
    }

    private string GetColorCode(string status)
    {
        return status switch
        {
            "Available" => "#10B981",    // Green
            "Booked" => "#EF4444",       // Red
            "Blocked" => "#F59E0B",      // Orange
            "Maintenance" => "#6B7280",  // Gray
            _ => "#E5E7EB"              // Light Gray
        };
    }

    private AvailabilityStatsDto CalculateStats(Dictionary<DateTime, string> calendar)
    {
        var total = calendar.Count;
        var available = calendar.Count(c => c.Value == "Available");
        var booked = calendar.Count(c => c.Value == "Booked");
        var blocked = calendar.Count(c => c.Value == "Blocked");
        var maintenance = calendar.Count(c => c.Value == "Maintenance");

        return new AvailabilityStatsDto
        {
            TotalDays = total,
            AvailableDays = available,
            BookedDays = booked,
            BlockedDays = blocked,
            MaintenanceDays = maintenance,
            OccupancyRate = total > 0 ? (decimal)booked / total * 100 : 0
        };
    }
}