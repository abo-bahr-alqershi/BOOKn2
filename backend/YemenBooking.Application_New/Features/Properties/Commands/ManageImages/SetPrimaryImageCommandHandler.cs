using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Core.Interfaces;
using System.Linq;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// معالج أمر تعيين صورة كرئيسية لكيان أو وحدة
    /// Handler for SetPrimaryImageCommand to set an image as main
    /// </summary>
    public class SetPrimaryImageCommandHandler : IRequestHandler<SetPrimaryImageCommand, ResultDto<bool>>
    {
        private readonly IPropertyImageRepository _imageRepository;
        private readonly IUnitOfWork _unitOfWork;

        public SetPrimaryImageCommandHandler(
            IPropertyImageRepository imageRepository,
            IUnitOfWork unitOfWork)
        {
            _imageRepository = imageRepository;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<bool>> Handle(SetPrimaryImageCommand request, CancellationToken cancellationToken)
        {
            var success = false;
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                // احصل على الصورة أولاً
                var image = await _imageRepository.GetPropertyImageByIdAsync(request.ImageId, cancellationToken);
                if (image == null)
                {
                    success = false;
                    return;
                }

                // إذا كانت الصورة غير مرتبطة بعد (إنشاء سابق للحفظ) ويوجد TempKey، قم بتحديث مجموعة المفتاح المؤقت فقط
                if (!image.PropertyId.HasValue && !image.UnitId.HasValue && string.IsNullOrWhiteSpace(image.CityName) && !string.IsNullOrWhiteSpace(request.TempKey))
                {
                    var group = await _imageRepository.GetImagesByTempKeyAsync(request.TempKey!, cancellationToken);
                    foreach (var img in group)
                    {
                        img.IsMain = img.Id == request.ImageId;
                        img.IsMainImage = img.Id == request.ImageId;
                        img.UpdatedAt = System.DateTime.UtcNow;
                        await _imageRepository.UpdatePropertyImageAsync(img, cancellationToken);
                    }
                    success = true;
                }
                else
                {
                    // إذا كانت الصورة مرتبطة بعقار/وحدة، استخدم المستودع لتفريغ الآخرين وتعيين الحالية كرئيسية
                    success = await _imageRepository.UpdateMainImageStatusAsync(request.ImageId, true, cancellationToken);
                }
            }, cancellationToken);

            return success
                ? ResultDto<bool>.Ok(true, "تم تعيين الصورة الرئيسية بنجاح")
                : ResultDto<bool>.Failure("فشل في تعيين الصورة الرئيسية");
        }
    }
} 