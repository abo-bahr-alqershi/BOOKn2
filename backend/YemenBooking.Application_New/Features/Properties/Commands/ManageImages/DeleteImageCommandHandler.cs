using System;
using System.Threading;
using System.Threading.Tasks;
using MediatR;
using YemenBooking.Application.Features.Properties;
using YemenBooking.Application.Common.Models;
using YemenBooking.Core.Interfaces.Repositories;
using YemenBooking.Application.Infrastructure.Services;
using YemenBooking.Core.Interfaces;

namespace YemenBooking.Application.Features.Properties.Commands.ManageImages
{
    /// <summary>
    /// معالج أمر حذف صورة واحدة (مؤقت أو دائم)
    /// Handler for DeleteImageCommand to delete a single image (soft or permanent)
    /// </summary>
    public class DeleteImageCommandHandler : IRequestHandler<DeleteImageCommand, ResultDto<bool>>
    {
        private readonly IPropertyImageRepository _imageRepository;
        private readonly ISectionImageRepository _sectionImageRepository;
        private readonly IPropertyInSectionImageRepository _propertyInSectionImageRepository;
        private readonly IUnitInSectionImageRepository _unitInSectionImageRepository;
        private readonly IFileStorageService _fileStorageService;
        private readonly IUnitOfWork _unitOfWork;

        public DeleteImageCommandHandler(
            IPropertyImageRepository imageRepository,
            ISectionImageRepository sectionImageRepository,
            IPropertyInSectionImageRepository propertyInSectionImageRepository,
            IUnitInSectionImageRepository unitInSectionImageRepository,
            IFileStorageService fileStorageService,
            IUnitOfWork unitOfWork)
        {
            _imageRepository = imageRepository;
            _sectionImageRepository = sectionImageRepository;
            _propertyInSectionImageRepository = propertyInSectionImageRepository;
            _unitInSectionImageRepository = unitInSectionImageRepository;
            _fileStorageService = fileStorageService;
            _unitOfWork = unitOfWork;
        }

        public async Task<ResultDto<bool>> Handle(DeleteImageCommand request, CancellationToken cancellationToken)
        {
            // جلب الصورة من المستودعات
            var s = await _sectionImageRepository.GetByIdAsync(request.ImageId, cancellationToken);
            var pis = s == null ? await _propertyInSectionImageRepository.GetByIdAsync(request.ImageId, cancellationToken) : null;
            var uis = (s == null && pis == null) ? await _unitInSectionImageRepository.GetByIdAsync(request.ImageId, cancellationToken) : null;
            var image = (s == null && pis == null && uis == null) ? await _imageRepository.GetPropertyImageByIdAsync(request.ImageId, cancellationToken) : null;
            if (s == null && pis == null && uis == null && image == null)
                return ResultDto<bool>.Failure("الصورة غير موجودة");

            var success = false;
            await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                if (s != null) success = await _sectionImageRepository.DeleteAsync(request.ImageId, cancellationToken);
                else if (pis != null) success = await _propertyInSectionImageRepository.DeleteAsync(request.ImageId, cancellationToken);
                else if (uis != null) success = await _unitInSectionImageRepository.DeleteAsync(request.ImageId, cancellationToken);
                else success = await _imageRepository.DeletePropertyImageAsync(request.ImageId, cancellationToken);

                var fileUrl = s?.Url ?? pis?.Url ?? uis?.Url ?? image?.Url;
                if (success && request.Permanent && !string.IsNullOrEmpty(fileUrl))
                {
                    await _fileStorageService.DeleteFileAsync(fileUrl!, cancellationToken);
                }
            }, cancellationToken);

            return success
                ? ResultDto<bool>.Ok(true, "تم حذف الصورة بنجاح")
                : ResultDto<bool>.Failure("فشل في حذف الصورة");
        }
    }
} 