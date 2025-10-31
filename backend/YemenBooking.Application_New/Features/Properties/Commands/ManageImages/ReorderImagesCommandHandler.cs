using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// معالج أمر إعادة ترتيب الصور
    /// Handler for ReorderImagesCommand to update display order of images
    /// </summary>
    public class ReorderImagesCommandHandler : IRequestHandler<ReorderImagesCommand, ResultDto<bool>>
    {
        private readonly IPropertyImageRepository _imageRepository;
        private readonly IUnitOfWork _unitOfWork;

        public ReorderImagesCommandHandler(
            IPropertyImageRepository imageRepository,
            IUnitOfWork unitOfWork)
        {
            _imageRepository = imageRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<bool>> Handle(ReorderImagesCommand request, CancellationToken cancellationToken)
        {
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // Batch update to minimize locks and round-trips
                var tuples = request.Assignments.ConvertAll(a => (a.ImageId, a.DisplayOrder));
                await _imageRepository.UpdateDisplayOrdersAsync(tuples, cancellationToken);
            }, cancellationToken);

            return ResultDto<bool>.Ok(true, "تم إعادة ترتيب الصور بنجاح");
        }
    }
} 