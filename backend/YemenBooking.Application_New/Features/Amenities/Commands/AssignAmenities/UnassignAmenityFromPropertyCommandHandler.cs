using MediatR;
using Microsoft.Extensions.Logging;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces;
using YemenBooking.Core.Entities;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Application.Common.Interfaces;
using YemenBooking.Application.Features.SearchAndFilters.Services;

namespace YemenBooking.Application.Features.Amenities.Commands.AssignAmenities;

/// <summary>
/// معالج أمر إلغاء إسناد مرفق من عقار
/// </summary>
public class UnassignAmenityFromPropertyCommandHandler : IRequestHandler<UnassignAmenityFromPropertyCommand, ResultDto<bool>>
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<UnassignAmenityFromPropertyCommandHandler> _logger;
    private readonly IIndexingService _indexingService;

    public UnassignAmenityFromPropertyCommandHandler(
        IUnitOfWork unitOfWork,
        ILogger<UnassignAmenityFromPropertyCommandHandler> logger,
        IIndexingService indexingService)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _indexingService = indexingService;
    }

    public async Task<ResultDto<bool>> Handle(UnassignAmenityFromPropertyCommand request, CancellationToken cancellationToken)
    {
        try
        {
            if (request.PropertyId == Guid.Empty || request.AmenityId == Guid.Empty)
                return ResultDto<bool>.Failed("بيانات غير صحيحة");

            // Find PropertyTypeAmenity for this Amenity
            var ptaList = await _unitOfWork.Repository<PropertyTypeAmenity>()
                .FindAsync(x => x.AmenityId == request.AmenityId, cancellationToken);

            if (!ptaList.Any())
                return ResultDto<bool>.Failed("المرفق غير مرتبط بأي نوع");

            // Remove PropertyAmenity row for this property and matching PTA
            var propertyAmenityRepo = _unitOfWork.Repository<PropertyAmenity>();
            var toRemove = await propertyAmenityRepo
                .FindAsync(x => x.PropertyId == request.PropertyId && ptaList.Select(p => p.Id).Contains(x.PtaId), cancellationToken);

            if (!toRemove.Any())
                return ResultDto<bool>.Failed("لا يوجد إسناد لهذا المرفق على هذا العقار");

            foreach (var pa in toRemove)
            {
                await propertyAmenityRepo.DeleteAsync(pa, cancellationToken);
            }

            await _unitOfWork.SaveChangesAsync(cancellationToken);

            // re-index property
            await _indexingService.OnPropertyUpdatedAsync(request.PropertyId, cancellationToken);

            return ResultDto<bool>.Succeeded(true, "تم إلغاء إسناد المرفق بنجاح");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "فشل إلغاء إسناد المرفق من العقار {PropertyId} {AmenityId}", request.PropertyId, request.AmenityId);
            return ResultDto<bool>.Failed("حدث خطأ أثناء إلغاء الإسناد");
        }
    }
}

