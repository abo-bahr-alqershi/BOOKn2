using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Amenities;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Entities;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Application.Features.Amenities.Commands.ManageAmenities
{
    public class ToggleAmenityStatusCommandHandler : IRequestHandler<ToggleAmenityStatusCommand, ResultDto<bool>>
    {
        private readonly IUnitOfWork _unitOfWork;

        public ToggleAmenityStatusCommandHandler(IUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<bool>> Handle(ToggleAmenityStatusCommand request, CancellationToken cancellationToken)
        {
            var repo = _unitOfWork.Repository<Amenity>();
            var amenity = await repo.GetByIdAsync(request.AmenityId, cancellationToken);
            if (amenity == null)
                return ResultDto<bool>.Failed("المرفق غير موجود");

            amenity.IsActive = !amenity.IsActive;
            await repo.UpdateAsync(amenity, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return ResultDto<bool>.Succeeded(true, amenity.IsActive ? "تم تفعيل المرفق" : "تم تعطيل المرفق");
        }
    }
}

