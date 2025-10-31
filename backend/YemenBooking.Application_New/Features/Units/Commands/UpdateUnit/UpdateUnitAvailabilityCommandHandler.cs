using AutoMapper;
using MediatR;
using YemenBooking.Application.Features.Units;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Common.Interfaces;

namespace YemenBooking.Application.Features.Units.Commands.UpdateUnit;

public class UpdateUnitAvailabilityCommandHandler : IRequestHandler<UpdateUnitAvailabilityCommand, ResultDto>
{
    private readonly IUnitAvailabilityRepository _repository;
    private readonly IMapper _mapper;
    private readonly ICurrentUserService _currentUserService;

    public UpdateUnitAvailabilityCommandHandler(
        IUnitAvailabilityRepository repository,
        IMapper mapper,
        ICurrentUserService currentUserService)
    {
        _repository = repository;
        _mapper = mapper;
        _currentUserService = currentUserService;
    }

    public async Task<ResultDto> Handle(UpdateUnitAvailabilityCommand request, CancellationToken cancellationToken)
    {
        try
        {
            // Validate dates (allow single-day inclusive ranges)
            if (request.EndDate < request.StartDate)
                return ResultDto.Failure("تاريخ النهاية يجب أن لا يكون قبل تاريخ البداية");

            // Normalize to local-day safe bounds then convert to UTC
            var localStart = new DateTime(request.StartDate.Year, request.StartDate.Month, request.StartDate.Day, 12, 0, 0);
            var localEnd = new DateTime(request.EndDate.Year, request.EndDate.Month, request.EndDate.Day, 23, 59, 59, 999);
            var startUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localStart);
            var endUtc = await _currentUserService.ConvertFromUserLocalToUtcAsync(localEnd);

            // Delete existing if overwrite is requested
            if (request.OverwriteExisting)
            {
                await _repository.DeleteRangeAsync(request.UnitId, startUtc, endUtc);
            }

            var availability = new UnitAvailability
            {
                Id = Guid.NewGuid(),
                UnitId = request.UnitId,
                StartDate = startUtc,
                EndDate = endUtc,
                Status = request.Status,
                Reason = request.Reason,
                Notes = request.Notes,
                CreatedAt = DateTime.UtcNow
            };

            await _repository.AddAsync(availability);
            await _repository.SaveChangesAsync(cancellationToken);
            return ResultDto.Ok("تم تحديث الإتاحة وحفظها");
        }
        catch (Exception ex)
        {
            return ResultDto.Failure($"حدث خطأ: {ex.Message}");
        }
    }
}