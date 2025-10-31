using MediatR;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Units.Commands.ManageAvailability;

public class CloneAvailabilityCommandHandler : IRequestHandler<CloneAvailabilityCommand, ResultDto>
{
    private readonly IUnitAvailabilityRepository _repository;
    private readonly ICurrentUserService _currentUserService;

    public CloneAvailabilityCommandHandler(IUnitAvailabilityRepository repository, ICurrentUserService currentUserService)
    {
        _repository = repository;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto> Handle(CloneAvailabilityCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Get source availability
            // Normalize source and target ranges from user-local to UTC
            var sourceStartUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.SourceStartDate);
            var sourceEndUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.SourceEndDate);
            var targetStartBaseUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(request.TargetStartDate);

            var sourceAvailabilities = await _repository.GetByDateRangeAsync(
                request.UnitId, 
                sourceStartUtc, 
                sourceEndUtc);

            if (!sourceAvailabilities.Any())
                return ResultDto.Failure("لا توجد بيانات إتاحة في الفترة المصدر");

            var newAvailabilities = new List<UnitAvailability>();
            var daysDiff = (sourceEndUtc - sourceStartUtc).Days;

            for (int i = 0; i < request.RepeatCount; i++)
            {
                var targetStart = targetStartBaseUtc.AddDays(daysDiff * i + i);
                
                foreach (var source in sourceAvailabilities)
                {
                    var sourceDayOffset = (source.StartDate - sourceStartUtc).Days;
                    var newAvailability = new UnitAvailability
                    {
                        Id = Guid.NewGuid(),
                        UnitId = request.UnitId,
                        StartDate = targetStart.AddDays(sourceDayOffset),
                        EndDate = targetStart.AddDays(sourceDayOffset + (source.EndDate - source.StartDate).Days),
                        Status = source.Status,
                        Reason = source.Reason,
                        Notes = $"مستنسخ من {source.StartDate:yyyy-MM-dd}",
                        CreatedAt = DateTime.UtcNow
                    };
                    
                    newAvailabilities.Add(newAvailability);
                }
            }

            await _repository.BulkCreateAsync(newAvailabilities);
            await _repository.SaveChangesAsync(cancellationToken);
            return ResultDto.Ok();
        }
        catch (Exception ex)
        {
            return ResultDto.Failure($"حدث خطأ: {ex.Message}");
        }
    }
}