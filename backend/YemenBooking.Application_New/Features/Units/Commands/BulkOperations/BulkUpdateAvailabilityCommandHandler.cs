using MediatR;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.Units.Services;

namespace YemenBooking.Application.Features.Units.Commands.BulkOperations;


public class BulkUpdateAvailabilityCommandHandler : IRequestHandler<BulkUpdateAvailabilityCommand, ResultDto>
{
    private readonly IAvailabilityService _availabilityService;
    private readonly ICurrentUserService _currentUserService;

    public BulkUpdateAvailabilityCommandHandler(IAvailabilityService availabilityService, ICurrentUserService currentUserService)
    {
        _availabilityService = availabilityService;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto> Handle(BulkUpdateAvailabilityCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Normalize all incoming periods to local-day bounds then convert to UTC
            var normalized = new List<AvailabilityPeriodDto>(request.Periods.Count);
            foreach (var p in request.Periods)
            {
                var localStart = new DateTime(p.StartDate.Year, p.StartDate.Month, p.StartDate.Day, 12, 0, 0);
                var localEnd = new DateTime(p.EndDate.Year, p.EndDate.Month, p.EndDate.Day, 23, 59, 59, 999);
                var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localStart);
                var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localEnd);
                normalized.Add(new AvailabilityPeriodDto
                {
                    StartDate = startUtc,
                    EndDate = endUtc,
                    Status = p.Status,
                    Reason = p.Reason,
                    Notes = p.Notes,
                    OverwriteExisting = p.OverwriteExisting
                });
            }
            await _availabilityService.ApplyBulkAvailabilityAsync(request.UnitId, normalized);
            return ResultDto.Ok();
        }
        catch (Exception ex)
        {
            return ResultDto.Failure($"حدث خطأ: {ex.Message}");
        }
    }
}